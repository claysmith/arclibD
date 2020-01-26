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
module arc.x.blaze.dynamics.joints.joint;

import arc.x.blaze.world;
import arc.x.blaze.common.math;
import arc.x.blaze.dynamics.Body;
import arc.x.blaze.dynamics.joints.distanceJoint;
import arc.x.blaze.dynamics.joints.gearJoint;
import arc.x.blaze.dynamics.joints.prismaticJoint;
import arc.x.blaze.dynamics.joints.pulleyJoint;
import arc.x.blaze.dynamics.joints.revoluteJoint;
import arc.x.blaze.dynamics.joints.mouseJoint;
import arc.x.blaze.dynamics.joints.lineJoint;

enum JointType {
    UNKNOWN,
    REVOLUTE,
    PRISMATIC,
    DISTANCE,
    PULLEY,
    MOUSE,
    GEAR,
	LINE
}

enum LimitState {
    INACTIVE,
    LOWER,
    UPPER,
    EQUAL
}

/// Joint definitions are used to construct joints.
class JointDef {

    this(Body body1, Body body2) {
        this.body1 = body1;
        this.body2 = body2;
        type = JointType.UNKNOWN;
    }

    /// The joint type is set automatically for concrete joint types.
    JointType type;

    /// Use this to attach application specific data to your joints.
    Object userData;

    /// The first attached body.
    Body body1;

    /// The second attached body.
    Body body2;

    /// Set this flag to true if the attached bodies should collide.
    bool collideConnected;

}

/// The base joint class. Joints are used to constraint two bodies together in
/// various fashions. Some joints also feature limits and motors.
class Joint {

    this(JointDef def) {
        m_type = def.type;
        prev = null;
        next = null;
        m_body1 = def.body1;
        m_body2 = def.body2;
        m_collideConnected = def.collideConnected;
        m_islandFlag = false;
        userData = def.userData;
        m_node1 = new JointEdge();
        m_node2 = new JointEdge();
    }

    /// Get the type of the concrete joint.
    JointType type() {
        return m_type;
    }

    /// Get the first body attached to this joint.
    Body rBody1() {
        return m_body1;
    }

    /// Get the second body attached to this joint.
    Body rBody2() {
        return m_body2;
    }

    JointEdge node1() {
        return m_node1;
    }

    JointEdge node2() {
        return m_node2;
    }

    void node1(JointEdge edge) {
        m_node1 = edge;
    }

    Object userData;

    bool islandFlag() {
        return m_islandFlag;
    }

    void islandFlag(bool flag) {
        m_islandFlag = flag;
    }

    bool collideConnected() {
        return m_collideConnected;
    }

    /// Get the anchor point on body1 in world coordinates.
    abstract bVec2 anchor1();

    /// Get the anchor point on body2 in world coordinates.
    abstract bVec2 anchor2();

    /// Get the reaction force on body2 at the joint anchor.
    abstract bVec2 reactionForce(float inv_dt);

    /// Get the reaction torque on body2.
    abstract float reactionTorque(float inv_dt);

    //--------------- Internals Below -------------------

    static Joint create(JointDef def) {

        Joint joint;

        switch (def.type) {
        case JointType.DISTANCE: {
            return new DistanceJoint(cast(DistanceJointDef) def);
        }
        case JointType.MOUSE: {
            return new MouseJoint(cast(MouseJointDef) def);
        }
        case JointType.PRISMATIC: {
            return new PrismaticJoint(cast(PrismaticJointDef) def);
        }
        case JointType.REVOLUTE: {
            return new RevoluteJoint(cast(RevoluteJointDef) def);
        }
        case JointType.PULLEY: {
            return new PulleyJoint(cast(PulleyJointDef) def);
        }
        case JointType.GEAR: {
            return new GearJoint(cast(GearJointDef) def);
        }
        case JointType.LINE: {
            return new LineJoint(cast(LineJointDef) def);
        }
        default:
            throw new Exception("Unknown joint type.");
            break;
        }
        return null;
    }

    void computeXForm(bXForm xf, bVec2 center, bVec2 localCenter, float angle) {
        xf.R.set(angle);
        xf.position = center - bMul(xf.R, localCenter);
    }

    abstract void initVelocityConstraints(TimeStep step);
    abstract void solveVelocityConstraints(TimeStep step);
    // This returns true if the position errors are within tolerance.
    abstract bool solvePositionConstraints(float baumgarte);

    Joint prev;
    Joint next;

protected:

    JointType m_type;
    JointEdge m_node1;
    JointEdge m_node2;
    Body m_body1;
    Body m_body2;

    bool m_islandFlag;
    bool m_collideConnected;

    // Cache here per time step to reduce cache misses.
    bVec2 m_localCenter1, m_localCenter2;
    float m_invMass1, m_invI1;
    float m_invMass2, m_invI2;
}

/// A joint edge is used to connect bodies and joints together
/// in a joint graph where each body is a node and each joint
/// is an edge. A joint edge belongs to a doubly linked list
/// maintained in each attached body. Each joint has two joint
/// nodes, one for each attached body.
class JointEdge {
    Body other;			///< provides quick access to the other body attached.
    Joint joint;			///< the joint
    JointEdge prev;		///< the previous joint edge in the body's joint list
    JointEdge next;		///< the next joint edge in the body's joint list
}
