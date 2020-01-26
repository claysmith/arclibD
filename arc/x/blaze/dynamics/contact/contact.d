/*
 * Copyright (c) 2007-2008, Michael Baczynski
 * Based on Box2D by Erin Catto, http://www.box2d.org
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * * Neither the name of the polygonal nor the names of its contributors may be
 *   used to endorse or promote products derived from this software without specific
 *   prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
module arc.x.blaze.dynamics.contact.contact;

import arc.x.blaze.common.math;
import arc.x.blaze.common.constants;
import arc.x.blaze.collision.shapes.shape;
import arc.x.blaze.collision.shapes.shapeType;
import arc.x.blaze.collision.collision;
import arc.x.blaze.dynamics.worldCallbacks;
import arc.x.blaze.dynamics.Body;

/// This structure is used to report contact points.
struct ContactPoint {
    Shape shape1;		///< the first shape
    Shape shape2;		///< the second shape
    bVec2 position;		///< position in world coordinates
    bVec2 velocity;		///< velocity of point on body2 relative to point on body1 (pre-solver)
    bVec2 normal;		///< points from shape1 to shape2
    float separation;	///< the separation is negative when shapes are touching
    float friction;		///< the combined friction coefficient
    float restitution;	///< the combined restitution coefficient
    ContactID id;		///< the contact id identifies the features in contact
}

/// This structure is used to report contact point results.
struct ContactResult {
    Shape shape1;		///< the first shape
    Shape shape2;		///< the second shape
    bVec2 position;		///< position in world coordinates
    bVec2 normal;			///< points from shape1 to shape2
    float normalImpulse;	///< the normal impulse applied to body2
    float tangentImpulse;	///< the tangent impulse applied to body2
    ContactID id;			///< the contact id identifies the features in contact
}

/// A contact edge is used to connect bodies and contacts together
/// in a contact graph where each body is a node and each contact
/// is an edge. A contact edge belongs to a doubly linked list
/// maintained in each attached body. Each contact has two contact
/// nodes, one for each attached body.
class ContactEdge {
    Body other;			///< provides quick access to the other body attached.
    Contact contact;	///< the contact
    ContactEdge prev;	///< the previous contact edge in the body's contact list
    ContactEdge next;	///< the next contact edge in the body's contact list
}

/// The class manages contact between two shapes. A contact exists for each overlapping
/// AABB in the broad-phase (except if filtered). Therefore a contact object may exist
/// that has no contact points.
class Contact {

    /** Contact manifold */
    Manifold[] manifolds;

    /// Get the number of manifolds. This is 0 or 1 between convex shapes.
    /// This may be greater than 1 for convex-vs-concave shapes. Each
    /// manifold holds up to two contact points with a shared contact normal.
    int manifoldCount() {
        return m_manifoldCount;
    }

    /// Is this contact solid?
    /// @return true if this contact should generate a response.
    bool isSolid() {
        return (flags & NON_SOLID) == 0;
    }

    /// Get the first shape in this contact.
    Shape shape1() {
        return m_shape1;
    }

    /// Get the second shape in this contact.
    Shape shape2() {
        return m_shape2;
    }

    //--------------- Internals Below -------------------

    void toi(float toi) {
        m_toi = toi;
    }

    float toi() {
        return m_toi;
    }

    this (Shape s1, Shape s2) {
        flags = 0;
        if (s1.isSensor || s2.isSensor) {
            flags |= NON_SOLID;
        }
        m_shape1 = s1;
        m_shape2 = s2;
        m_manifoldCount = 0;
        node1 = new ContactEdge();
        node2 = new ContactEdge();
    }

    // flags
    static enum {
        NON_SOLID	= 0x0001,
        SLOW		= 0x0002,
        ISLAND	    = 0x0004,
        TOI		    = 0x0008,
    }

    void update(ContactListener listener) {

        int oldCount = m_manifoldCount;

        evaluate(listener);

        // Fluid contacts are a special case
        if(m_shape2.type is ShapeType.FLUID) return;

        int newCount = m_manifoldCount;

        auto body1 = m_shape1.rBody;
        auto body2 = m_shape2.rBody;

        if (newCount == 0 && oldCount > 0) {
            body1.wakeup();
            body2.wakeup();
        }

        // Bullets generate TOI events.
        if (body1.bullet || body2.bullet) {
            flags &= ~SLOW;
        } else {
            flags |= SLOW;
        }

    }

    abstract void evaluate(ContactListener listener);

    static bool s_initialized;

    int flags;

    // World pool and list pointers.
    Contact prev;
    Contact next;

    // Nodes for connecting bodies.
    ContactEdge node1;
    ContactEdge node2;

    int stamp;
    uint hash;
    bool flag;

protected:

    int m_manifoldCount;
    Shape m_shape1;
    Shape m_shape2;

    float m_toi;
}
