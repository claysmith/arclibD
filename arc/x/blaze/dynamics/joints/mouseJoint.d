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
module arc.x.blaze.dynamics.joints.mouseJoint;

import arc.x.blaze.common.math;
import arc.x.blaze.common.constants;
import arc.x.blaze.dynamics.Body;
import arc.x.blaze.dynamics.bodyDef;
import arc.x.blaze.world;
import arc.x.blaze.dynamics.joints.joint;

/// Mouse joint definition. This requires a world target point,
/// tuning parameters, and the time step.
class MouseJointDef : JointDef {

    /** Initialize the body and target point */
    this(Body body1, Body body2) {
        super(body1, body2);
        type = JointType.MOUSE;
        maxForce = 0.0f;
        frequencyHz = 5.0f;
        dampingRatio = 0.7f;
    }

    /// The initial world target point. This is assumed
    /// to coincide with the body anchor initially.
    bVec2 target;

    /// The maximum constraint force that can be exerted
    /// to move the candidate body. Usually you will express
    /// as some multiple of the weight (multiplier * mass * gravity).
    float maxForce;

    /// The response speed.
    float frequencyHz;

    /// The damping ratio. 0 = no damping, 1 = critical damping.
    float dampingRatio;
    
    // Can the body rotate?
    bool fixed;
}

/// A mouse joint is used to make a point on a body track a
/// specified world point. This a soft constraint with a maximum
/// force. This allows the constraint to stretch and without
/// applying huge forces.
class MouseJoint : Joint {

    /// Implements b2Joint.
    bVec2 anchor1() {
        return m_target;
    }

    /// Implements b2Joint.
    bVec2 anchor2() {
        return m_body2.worldPoint(m_localAnchor);
    }

    /// Implements b2Joint.
    bVec2 reactionForce(float inv_dt) {
        return inv_dt * m_impulse;
    }

    /// Implements b2Joint.
    float reactionTorque(float inv_dt) {
        return inv_dt * 0.0f;
    }

    /// Use this to update the target point.
    void setTarget(bVec2 target) {
        if (m_body2.isSleeping) {
            m_body2.wakeup();
        }
        m_target = target;
    }

    //--------------- Internals Below -------------------
    // p = attached point, m = mouse point
    // C = p - m
    // Cdot = v
    //      = v + bCross(w, r)
    // J = [I r_skew]
    // Identity used:
    // w k % (rx i + ry j) = w * (-ry i + rx j)

    this(MouseJointDef def) {
        super(def);
        m_target = def.target;
        m_localAnchor = bMulT(m_body2.xf, m_target);

        m_maxForce = def.maxForce;
        m_impulse.zero();

        m_frequencyHz = def.frequencyHz;
        m_dampingRatio = def.dampingRatio;

        m_beta = 0.0f;
        m_gamma = 0.0f;
        fixed = def.fixed;
    }

    void initVelocityConstraints(TimeStep step) {
        Body b = m_body2;

        float mass = b.mass();

        // Frequency
        float omega = 2.0f * PI * m_frequencyHz;

        // Damping coefficient
        float d = 2.0f * mass * m_dampingRatio * omega;

        // Spring stiffness
        float k = mass * (omega * omega);

        // magic formulas
        // gamma has units of inverse mass.
        // beta has units of inverse time.
        assert(d + step.dt * k > float.epsilon);
        m_gamma = 1.0f / (step.dt * (d + step.dt * k));
        m_beta = step.dt * k * m_gamma;

        // Compute the effective mass matrix.
        bVec2 r = bMul(b.xf.R, m_localAnchor - b.localCenter);

        // K    = [(1/m1 + 1/m2) * eye(2) - skew(r1) * invI1 * skew(r1) - skew(r2) * invI2 * skew(r2)]
        //      = [1/m1+1/m2     0    ] + invI1 * [r1.y*r1.y -r1.x*r1.y] + invI2 * [r1.y*r1.y -r1.x*r1.y]
        //        [    0     1/m1+1/m2]           [-r1.x*r1.y r1.x*r1.x]           [-r1.x*r1.y r1.x*r1.x]
        float invMass = b.invMass;
        float invI = b.invI;

        bMat22 K1;
        K1.col1.x = invMass; K1.col2.x = 0.0f;
        K1.col1.y = 0.0f; K1.col2.y = invMass;

        bMat22 K2;
        K2.col1.x =  invI * r.y * r.y; K2.col2.x = -invI * r.x * r.y;
        K2.col1.y = -invI * r.x * r.y; K2.col2.y =  invI * r.x * r.x;

        bMat22 K = K1 + K2;
        K.col1.x += m_gamma;
        K.col2.y += m_gamma;

        m_mass = K.inverse();

        m_C = b.sweep.c + r - m_target;

        // Cheat with some damping
        b.angularVelocity *= 0.98f;

        // Warm starting.
        m_impulse *= step.dtRatio;
        b.linearVelocity += invMass * m_impulse;
        if(!fixed) {
			b.angularVelocity += invI * bCross(r, m_impulse);
		}
    }

    void solveVelocityConstraints(TimeStep step) {
        Body b = m_body2;

        bVec2 r = bMul(b.xf.R, m_localAnchor - b.localCenter);

        // Cdot = v + bCross(w, r)
        bVec2 Cdot = b.linearVelocity + bCross(b.angularVelocity, r);
        bVec2 impulse = bMul(m_mass, -(Cdot + m_beta * m_C + m_gamma * m_impulse));

        bVec2 oldImpulse = m_impulse;
        m_impulse += impulse;
        float maxImpulse = step.dt * m_maxForce;
        if (m_impulse.lengthSquared > maxImpulse * maxImpulse) {
            m_impulse *= maxImpulse / m_impulse.length();
        }
        impulse = m_impulse - oldImpulse;

        b.linearVelocity += b.invMass * impulse;
        if(!fixed) {
			b.angularVelocity += b.invI * bCross(r, impulse);
		}
    }

    bool solvePositionConstraints(float baumgarte) { return true; }

	bool fixed;
	
    private:

    bVec2 m_localAnchor;
    bVec2 m_target;
    bVec2 m_impulse;

    bMat22 m_mass;		// effective mass for point-to-point constraint.
    bVec2 m_C;				// position error
    float m_maxForce;
    float m_frequencyHz;
    float m_dampingRatio;
    float m_beta;
    float m_gamma;
}
