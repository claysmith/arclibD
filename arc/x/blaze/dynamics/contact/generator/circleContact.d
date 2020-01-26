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
module arc.x.blaze.dynamics.contact.generator.circleContact;

import arc.x.blaze.common.constants;
import arc.x.blaze.common.math;
import arc.x.blaze.collision.shapes.shape;
import arc.x.blaze.collision.shapes.circle;
import arc.x.blaze.collision.shapes.shapeType;
import arc.x.blaze.collision.collision;
import arc.x.blaze.collision.pairwise.collideCircle;
import arc.x.blaze.dynamics.worldCallbacks;
import arc.x.blaze.dynamics.contact.contact;
import arc.x.blaze.dynamics.worldCallbacks;
import arc.x.blaze.dynamics.Body;

/** Generate contacts from the narrow phase colliion detection
 * for Circle-Circle contacts.
 */
class CircleContact : Contact {

    this(Shape s1, Shape s2) {
        assert(s1.type == ShapeType.CIRCLE);
        assert(s2.type == ShapeType.CIRCLE);
        super(s1, s2);
        manifolds.length = 1;
    }

    static Contact create(Shape s1, Shape s2) {
        return new CircleContact(s1, s2);
    }

    void evaluate(ContactListener listener) {

        Body b1 = m_shape1.rBody;
        Body b2 = m_shape2.rBody;

        // Make a copy
        Manifold m0 = manifolds[0];

        collideCircles(manifolds[0], cast (Circle) m_shape1, cast (Circle) m_shape2);

        ContactPoint cp;
        cp.shape1 = m_shape1;
        cp.shape2 = m_shape2;
        cp.friction = mixFriction(m_shape1.friction, m_shape2.friction);
        cp.restitution = mixRestitution(m_shape1.restitution, m_shape2.restitution);

        if (manifolds[0].pointCount > 0) {
            ManifoldPoint *mp = &manifolds[0].points[0];
            if (m0.pointCount == 0) {
                mp.normalImpulse = 0.0f;
                mp.tangentImpulse = 0.0f;

                if (listener) {
                    cp.position = b1.worldPoint(mp.localPoint1);
                    bVec2 v1 = b1.linearVelocityFromLocalPoint(mp.localPoint1);
                    bVec2 v2 = b2.linearVelocityFromLocalPoint(mp.localPoint2);
                    cp.velocity = v2 - v1;
                    cp.normal = manifolds[0].normal;
                    cp.separation = mp.separation;
                    cp.id = mp.id;
                    listener.add(cp);
                }
            } else {
                ManifoldPoint *mp0 = &m0.points[0];
                mp.normalImpulse = mp0.normalImpulse;
                mp.tangentImpulse = mp0.tangentImpulse;

                if (listener) {
                    cp.position = b1.worldPoint(mp.localPoint1);
                    bVec2 v1 = b1.linearVelocityFromLocalPoint(mp.localPoint1);
                    bVec2 v2 = b2.linearVelocityFromLocalPoint(mp.localPoint2);
                    cp.velocity = v2 - v1;
                    cp.normal = manifolds[0].normal;
                    cp.separation = mp.separation;
                    cp.id = mp.id;
                    listener.persist(cp);
                }
            }
            m_manifoldCount = 1;
        } else {
            m_manifoldCount = 0;
            if (m0.pointCount > 0 && listener) {
                ManifoldPoint *mp0 = &m0.points[0];
                cp.position = b1.worldPoint(mp0.localPoint1);
                bVec2 v1 = b1.linearVelocityFromLocalPoint(mp0.localPoint1);
                bVec2 v2 = b2.linearVelocityFromLocalPoint(mp0.localPoint2);
                cp.velocity = v2 - v1;
                cp.normal = m0.normal;
                cp.separation = mp0.separation;
                cp.id = mp0.id;
                listener.remove(cp);
            }
        }
    }
}
