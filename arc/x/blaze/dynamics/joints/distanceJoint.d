/*
* Copyright (c) 2006-2007 Erin Catto http://www.gphysics.com
*
* This software is provided 'as-is', without any express or implied
* warranty.  In no event will the authors be held liable for any damages
* arising from the use of this software.
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
* 1. The origin of this software must not be misrepresented; you must not
* claim that you wrote the original software. If you use this software
* in a product, an acknowledgment in the product documentation would be
* appreciated but is not required.
* 2. Altered source versions must be plainly marked as such, and must not be
* misrepresented as being the original software.
* 3. This notice may not be removed or altered from any source distribution.
*/
module arc.x.blaze.dynamics.joints.distanceJoint;

import arc.x.blaze.common.math;
import arc.x.blaze.common.constants;
import arc.x.blaze.dynamics.Body;
import arc.x.blaze.world;
import arc.x.blaze.dynamics.joints.joint;

/// Distance joint definition. This requires defining an
/// anchor point on both bodies and the non-zero length of the
/// distance joint. The definition uses local anchor points
/// so that the initial configuration can violate the constraint
/// slightly. This helps when saving and loading a game.
/// @warning Do not use a zero or short length.
class DistanceJointDef : JointDef {

    /// Initialize the bodies, anchors, and length using the world
    /// anchors.
    this (Body body1, Body body2, bVec2 anchor1, bVec2 anchor2) {
        super(body1, body2);
        type = JointType.DISTANCE;
        localAnchor1 = body1.localPoint(anchor1);
        localAnchor2 = body2.localPoint(anchor2);
        bVec2 d = anchor2 - anchor1;
        length = d.length();
        frequencyHz = 0.0f;
        dampingRatio = 0.0f;
    }

    /// The local anchor point relative to body1's origin.
    bVec2 localAnchor1;

    /// The local anchor point relative to body2's origin.
    bVec2 localAnchor2;

    /// The equilibrium length between the anchor points.
    float length;

    /// The response speed.
    float frequencyHz;

    /// The damping ratio. 0 = no damping, 1 = critical damping.
    float dampingRatio;
}

/// A distance joint constrains two points on two bodies
/// to remain at a fixed distance from each other. You can view
/// this as a massless, rigid rod.
class DistanceJoint : Joint {

    this(DistanceJointDef def) {
        super(def);
        m_localAnchor1 = def.localAnchor1;
        m_localAnchor2 = def.localAnchor2;
        m_length = def.length;
        m_frequencyHz = def.frequencyHz;
        m_dampingRatio = def.dampingRatio;
        m_impulse = 0.0f;
        m_gamma = 0.0f;
        m_bias = 0.0f;
    }

    bVec2 anchor1() {
        return m_body1.worldPoint(m_localAnchor1);
    }

    bVec2 anchor2() {
        return m_body2.worldPoint(m_localAnchor2);
    }

    bVec2 reactionForce(float inv_dt) {
        bVec2 F = (inv_dt * m_impulse) * m_u;
        return F;
    }

    float reactionTorque(float inv_dt) {
        return 0.0f;
    }

    //--------------- Internals Below -------------------

    // 1-D constrained system
    // m (v2 - v1) = lambda
    // v2 + (beta/h) * x1 + gamma * lambda = 0, gamma has units of inverse mass.
    // x2 = x1 + h * v2

    // 1-D mass-damper-spring system
    // m (v2 - v1) + h * d * v2 + h * k *

    // C = norm(p2 - p1) - L
    // u = (p2 - p1) / norm(p2 - p1)
    // Cdot = bDot(u, v2 + bCross(w2, r2) - v1 - bCross(w1, r1))
    // J = [-u -bCross(r1, u) u bCross(r2, u)]
    // K = J * invM * JT
    //   = invMass1 + invI1 * bCross(r1, u)^2 + invMass2 + invI2 * bCross(r2, u)^2

    void initVelocityConstraints(TimeStep step) {

        Body b1 = m_body1;
        Body b2 = m_body2;

        // Compute the effective mass matrix.
        bVec2 r1 = bMul(b1.xf.R, m_localAnchor1 - b1.localCenter);
        bVec2 r2 = bMul(b2.xf.R, m_localAnchor2 - b2.localCenter);
        m_u = b2.sweep.c + r2 - b1.sweep.c - r1;

        // Handle singularity.
        float length = m_u.length();
        if (length > k_linearSlop) {
            m_u *= 1.0f / length;
        } else {
            m_u.set(0.0f, 0.0f);
        }

        float cr1u = bCross(r1, m_u);
        float cr2u = bCross(r2, m_u);
        float invMass = b1.invMass + b1.invI * cr1u * cr1u + b2.invMass + b2.invI * cr2u * cr2u;
        assert(invMass > float.epsilon);
        m_mass = 1.0f / invMass;

        if (m_frequencyHz > 0.0f) {
            float C = length - m_length;

            // Frequency
            float omega = 2.0f * PI * m_frequencyHz;

            // Damping coefficient
            float d = 2.0f * m_mass * m_dampingRatio * omega;

            // Spring stiffness
            float k = m_mass * omega * omega;

            // magic formulas
            m_gamma = 1.0f / (step.dt * (d + step.dt * k));
            m_bias = C * step.dt * k * m_gamma;

            m_mass = 1.0f / (invMass + m_gamma);
        }

        if (step.warmStarting) {
            // Scale the impulse to support a variable time step.
            m_impulse *= step.dtRatio;

            bVec2 P = m_impulse * m_u;
            b1.linearVelocity = b1.linearVelocity - b1.invMass * P;
            b1.angularVelocity = b1.angularVelocity - b1.invI * bCross(r1, P);
            b2.linearVelocity = b2.linearVelocity + b2.invMass * P;
            b2.angularVelocity = b2.angularVelocity + b2.invI * bCross(r2, P);
        } else {
            m_impulse = 0.0f;
        }
    }

    void solveVelocityConstraints(TimeStep step) {
        Body b1 = m_body1;
        Body b2 = m_body2;

        bVec2 r1 = bMul(b1.xf.R, m_localAnchor1 - b1.localCenter);
        bVec2 r2 = bMul(b2.xf.R, m_localAnchor2 - b2.localCenter);

        // Cdot = bDot(u, v + bCross(w, r))
        bVec2 v1 = b1.linearVelocity + bCross(b1.angularVelocity, r1);
        bVec2 v2 = b2.linearVelocity + bCross(b2.angularVelocity, r2);
        float Cdot = bDot(m_u, v2 - v1);

        float impulse = -m_mass * (Cdot + m_bias + m_gamma * m_impulse);
        m_impulse += impulse;

        bVec2 P = impulse * m_u;
        b1.linearVelocity = b1.linearVelocity - b1.invMass * P;
        b1.angularVelocity = b1.angularVelocity - b1.invI * bCross(r1, P);
        b2.linearVelocity = b2.linearVelocity + b2.invMass * P;
        b2.angularVelocity = b2.angularVelocity + b2.invI * bCross(r2, P);
    }

    bool solvePositionConstraints(float baumgarte) {
        if (m_frequencyHz > 0.0f) {
            // There is no position correction for soft distance constraints.
            return true;
        }

        Body b1 = m_body1;
        Body b2 = m_body2;

        bVec2 r1 = bMul(b1.xf.R, m_localAnchor1 - b1.localCenter);
        bVec2 r2 = bMul(b2.xf.R, m_localAnchor2 - b2.localCenter);

        bVec2 d = b2.sweep.c + r2 - b1.sweep.c - r1;

        float length = d.normalize;
        float C = length - m_length;
        C = bClamp(C, -k_maxLinearCorrection, k_maxLinearCorrection);

        float impulse = -m_mass * C;
        m_u = d;
        bVec2 P = impulse * m_u;

        b1.sweep.c = b1.sweep.c - b1.invMass * P;
        b1.sweep.a = b1.sweep.a - b1.invI * bCross(r1, P);
        b2.sweep.c = b2.sweep.c + b2.invMass * P;
        b2.sweep.a = b2.sweep.a  + b2.invI * bCross(r2, P);

        b1.synchronizeTransform();
        b2.synchronizeTransform();

        return abs(C) < k_linearSlop;
    }

    private:

    bVec2 m_localAnchor1;
    bVec2 m_localAnchor2;
    bVec2 m_u;
    float m_frequencyHz;
    float m_dampingRatio;
    float m_gamma;
    float m_bias;
    float m_impulse;
    float m_mass;		// effective mass for the constraint.
    float m_length;
}
