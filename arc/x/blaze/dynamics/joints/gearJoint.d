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
module arc.x.blaze.dynamics.joints.gearJoint;

import arc.x.blaze.world;
import arc.x.blaze.common.math;
import arc.x.blaze.common.constants;
import arc.x.blaze.dynamics.Body;
import arc.x.blaze.dynamics.joints.joint;
import arc.x.blaze.dynamics.joints.revoluteJoint;
import arc.x.blaze.dynamics.joints.prismaticJoint;

/// Gear joint definition. This definition requires two existing
/// revolute or prismatic joints (any combination will work).
/// The provided joints must attach a dynamic body to a static body.
class GearJointDef : JointDef {

    /**
    * Creates a new GearJointData instance.
    *
    * @param joint1   	The first gear of the joint.
    * @param joint2   	The second gear of the joint
    * @param ratio 	    The gear joint's gear ratio.
    */
    this(Joint joint1, Joint joint2, float ratio = 1) {
        super(joint1.rBody2,joint2.rBody2);
        this.joint1 = joint1;
        this.joint2 = joint2;
        this.ratio = ratio;
    }

    /// The first revolute/prismatic joint attached to the gear joint.
    Joint joint1;

    /// The second revolute/prismatic joint attached to the gear joint.
    Joint joint2;

    /// The gear ratio.
    /// @see b2GearJoint for explanation.
    float ratio;
}

/// A gear joint is used to connect two joints together. Either joint
/// can be a revolute or prismatic joint. You specify a gear ratio
/// to bind the motions together:
/// coordinate1 + ratio * coordinate2 = constant
/// The ratio can be negative or positive. If one joint is a revolute joint
/// and the other joint is a prismatic joint, then the ratio will have units
/// of length or units of 1/length.
/// @warning The revolute and prismatic joints must be attached to
/// fixed bodies (which must be body1 on those joints).
class GearJoint : Joint {

    bVec2 anchor1() {
        return m_body1.worldPoint(m_localAnchor1);
    }

    bVec2 anchor2() {
        return m_body2.worldPoint(m_localAnchor2);
    }

    bVec2 reactionForce(float inv_dt) {
        // TODO_ERIN not tested
        bVec2 P = m_impulse * m_J.linear2;
        return inv_dt * P;
    }

    float reactionTorque(float inv_dt) {
        // TODO_ERIN not tested
        bVec2 r = bMul(m_body2.xf.R, m_localAnchor2 - m_body2.localCenter);
        bVec2 P = m_impulse * m_J.linear2;
        float L = m_impulse * m_J.angular2 - bCross(r, P);
        return inv_dt * L;
    }

    /** Get the gear ratio */
    float ratio() {
        return m_ratio;
    }

    //--------------- Internals Below -------------------
    // Gear Joint:
    // C0 = (coordinate1 + ratio * coordinate2)_initial
    // C = C0 - (cordinate1 + ratio * coordinate2) = 0
    // Cdot = -(Cdot1 + ratio * Cdot2)
    // J = -[J1 ratio * J2]
    // K = J * invM * JT
    //   = J1 * invM1 * J1T + ratio * ratio * J2 * invM2 * J2T
    //
    // Revolute:
    // coordinate = rotation
    // Cdot = angularVelocity
    // J = [0 0 1]
    // K = J * invM * JT = invI
    //
    // Prismatic:
    // coordinate = bDot(p - pg, ug)
    // Cdot = bDot(v + bCross(w, r), ug)
    // J = [ug bCross(r, ug)]
    // K = J * invM * JT = invMass + invI * bCross(r, ug)^2
    this (GearJointDef def) {

        super(def);
        JointType type1 = def.joint1.type;
        JointType type2 = def.joint2.type;

        assert(type1 == JointType.REVOLUTE || type1 == JointType.PRISMATIC);
        assert(type2 == JointType.REVOLUTE || type2 == JointType.PRISMATIC);
        assert(def.joint1.rBody1.isStatic);
        assert(def.joint2.rBody1.isStatic);

        m_revolute1 = null;
        m_prismatic1 = null;
        m_revolute2 = null;
        m_prismatic2 = null;

        float coordinate1, coordinate2;

        m_ground1 = def.joint1.rBody1;
        m_body1 = def.joint1.rBody2;
        if (type1 == JointType.REVOLUTE) {
            m_revolute1 = cast (RevoluteJoint) def.joint1;
            m_groundAnchor1 = m_revolute1.localAnchor1;
            m_localAnchor1 = m_revolute1.localAnchor2;
            coordinate1 = m_revolute1.jointAngle;
        } else {
            m_prismatic1 = cast (PrismaticJoint) def.joint1;
            m_groundAnchor1 = m_prismatic1.localAnchor1;
            m_localAnchor1 = m_prismatic1.localAnchor2;
            coordinate1 = m_prismatic1.jointTranslation;
        }

        m_ground2 = def.joint2.rBody1;
        m_body2 = def.joint2.rBody2;
        if (type2 == JointType.REVOLUTE) {
            m_revolute2 = cast (RevoluteJoint) def.joint2;
            m_groundAnchor2 = m_revolute2.localAnchor1;
            m_localAnchor2 = m_revolute2.localAnchor2;
            coordinate2 = m_revolute2.jointAngle;
        } else {
            m_prismatic2 = cast (PrismaticJoint) def.joint2;
            m_groundAnchor2 = m_prismatic2.localAnchor1;
            m_localAnchor2 = m_prismatic2.localAnchor2;
            coordinate2 = m_prismatic2.jointTranslation;
        }

        m_ratio = def.ratio;

        m_constant = coordinate1 + m_ratio * coordinate2;

        m_impulse = 0.0f;
    }

    void initVelocityConstraints(TimeStep step) {
        Body g1 = m_ground1;
        Body g2 = m_ground2;
        Body b1 = m_body1;
        Body b2 = m_body2;

        float K = 0.0f;
        m_J.zero();

        if (m_revolute1) {
            m_J.angular1 = -1.0f;
            K += b1.invI;
        } else {
            bVec2 ug = bMul(g1.xf.R, m_prismatic1.localXAxis1);
            bVec2 r = bMul(b1.xf.R, m_localAnchor1 - b1.localCenter);
            float crug = bCross(r, ug);
            m_J.linear1 = -ug;
            m_J.angular1 = -crug;
            K += b1.invMass + b1.invI * crug * crug;
        }

        if (m_revolute2) {
            m_J.angular2 = -m_ratio;
            K += m_ratio * m_ratio * b2.invI;
        } else {
            bVec2 ug = bMul(g2.xf.R, m_prismatic2.localXAxis1);
            bVec2 r = bMul(b2.xf.R, m_localAnchor2 - b2.localCenter);
            float crug = bCross(r, ug);
            m_J.linear2 = -m_ratio * ug;
            m_J.angular2 = -m_ratio * crug;
            K += m_ratio * m_ratio * (b2.invMass + b2.invI * crug * crug);
        }

        // Compute effective mass.
        assert(K > 0.0f);
        m_mass = 1.0f / K;

        if (step.warmStarting) {
            // Warm starting.
            b1.linearVelocity = b1.linearVelocity + b1.invMass * m_impulse * m_J.linear1;
            b1.angularVelocity = b1.angularVelocity + b1.invI * m_impulse * m_J.angular1;
            b2.linearVelocity = b2.linearVelocity + b2.invMass * m_impulse * m_J.linear2;
            b2.angularVelocity = b2.angularVelocity + b2.invI * m_impulse * m_J.angular2;
        } else {
            m_impulse = 0.0f;
        }
    }

    void solveVelocityConstraints(TimeStep step) {
        Body b1 = m_body1;
        Body b2 = m_body2;

        float Cdot = m_J.compute(b1.linearVelocity, b1.angularVelocity, b2.linearVelocity, b2.angularVelocity);

        float impulse = m_mass * (-Cdot);
        m_impulse += impulse;

        b1.linearVelocity = b1.linearVelocity + b1.invMass * impulse * m_J.linear1;
        b1.angularVelocity = b1.angularVelocity + b1.invI * impulse * m_J.angular1;
        b2.linearVelocity = b2.linearVelocity + b2.invMass * impulse * m_J.linear2;
        b2.angularVelocity = b2.angularVelocity + b2.invI * impulse * m_J.angular2;
    }

    bool solvePositionConstraints(float baumgarte) {

        float linearError = 0.0f;

        Body b1 = m_body1;
        Body b2 = m_body2;

        float coordinate1, coordinate2;
        if (m_revolute1) {
            coordinate1 = m_revolute1.jointAngle;
        } else {
            coordinate1 = m_prismatic1.jointTranslation;
        }

        if (m_revolute2) {
            coordinate2 = m_revolute2.jointAngle;
        } else {
            coordinate2 = m_prismatic2.jointTranslation;
        }

        float C = m_constant - (coordinate1 + m_ratio * coordinate2);

        float impulse = m_mass * (-C);

        b1.sweep.c = b1.sweep.c + b1.invMass * impulse * m_J.linear1;
        b1.sweep.a = b1.sweep.a + b1.invI * impulse * m_J.angular1;
        b2.sweep.c = b2.sweep.c + b2.invMass * impulse * m_J.linear2;
        b2.sweep.a = b2.sweep.a + b2.invI * impulse * m_J.angular2;

        b1.synchronizeTransform();
        b2.synchronizeTransform();

        // TODO_ERIN not implemented
        return linearError < k_linearSlop;
    }

private:

    Body m_ground1;
    Body m_ground2;

    // One of these is null.
    RevoluteJoint m_revolute1;
    PrismaticJoint m_prismatic1;

    // One of these is null.
    RevoluteJoint m_revolute2;
    PrismaticJoint m_prismatic2;

    bVec2 m_groundAnchor1;
    bVec2 m_groundAnchor2;

    bVec2 m_localAnchor1;
    bVec2 m_localAnchor2;

    bJacobian m_J;

    float m_constant;
    float m_ratio;

    // Effective mass
    float m_mass;

    // Impulse for accumulation/warm starting.
    float m_impulse;
}
