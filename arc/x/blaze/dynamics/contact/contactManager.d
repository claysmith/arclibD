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
module arc.x.blaze.dynamics.contact.contactManager;

import arc.x.blaze.common.math;
import arc.x.blaze.common.constants;
import arc.x.blaze.collision.shapes.shape;
import arc.x.blaze.collision.collision;
import arc.x.blaze.dynamics.Body;
import arc.x.blaze.dynamics.contact.contactFactory;
import arc.x.blaze.dynamics.contact.contact;
import arc.x.blaze.dynamics.contact.generator.nullContact;
import arc.x.blaze.world;

// Delegate of b2World.
class ContactManager {

    World m_world;
    ContactFactory factory;

    bool m_destroyImmediate;

    this (World world) {
        m_world = world;
        factory = new ContactFactory();
    }

    // This is a callback from the broadphase when two AABB proxies begin
    // to overlap. We create a Contact to manage the narrow phase.
    Contact pairAdded(Shape shape1, Shape shape2) {

        Body body1 = shape1.rBody;
        Body body2 = shape2.rBody;

        if (body1.isStatic && body2.isStatic) {
            return null;
        }

        if (shape1.rBody is shape2.rBody) {
            return null;
        }

        if (body2.isConnected(body1)) {
            return null;
        }

        if (m_world.contactFilter !is null && m_world.contactFilter.shouldCollide(shape1, shape2) == false) {
            return null;
        }

        // Call the factory.
        Contact c = factory.create(shape1, shape2);

        if (c is null) {
            return null;
        }

        // Contact creation may swap shapes.
        shape1 = c.shape1;
        shape2 = c.shape2;
        body1 = shape1.rBody;
        body2 = shape2.rBody;

        // Insert into the world.
        c.prev = null;
        c.next = m_world.contactList;
        if (m_world.contactList) {
            m_world.contactList.prev = c;
        }
        m_world.contactList = c;

        // Connect to island graph.

        // Connect to body 1
        c.node1.contact = c;
        c.node1.other = body2;

        c.node1.prev = null;
        c.node1.next = body1.contactList;
        if (body1.contactList) {
            body1.contactList.prev = c.node1;
        }
        body1.contactList = c.node1;

        // Connect to body 2
        c.node2.contact = c;
        c.node2.other = body1;

        c.node2.prev = null;
        c.node2.next = body2.contactList;
        if (body2.contactList) {
            body2.contactList.prev = c.node2;
        }
        body2.contactList = c.node2;

        m_world.contactCount++;
        return c;
    }

    // This is a callback from the broadphase when two AABB proxies cease
    // to overlap. We retire the Contact.
    void pairRemoved(Contact c) {

        if (c is null) {
            return;
        }

        // An attached body is being destroyed, we must destroy this contact
        // immediately to avoid orphaned shape pointers.
        destroy(c);
    }

    void destroy(Contact c) {

        Shape shape1 = c.shape1;
        Shape shape2 = c.shape2;

        // Inform the user that this contact is ending.
        int manifoldCount = c.manifoldCount;
        if (manifoldCount > 0 && m_world.contactListener) {

            Body b1 = shape1.rBody;
            Body b2 = shape2.rBody;

            Manifold[] manifolds = c.manifolds;
            ContactPoint cp;
            cp.shape1 = c.shape1;
            cp.shape2 = c.shape2;
            cp.friction = mixFriction(shape1.friction, shape2.friction);
            cp.restitution = mixRestitution(shape1.restitution, shape2.restitution);

            for (int i = 0; i < manifoldCount; ++i) {
                Manifold *manifold = &manifolds[i];
                cp.normal = manifold.normal;

                for (int j = 0; j < manifold.pointCount; ++j) {
                    ManifoldPoint *mp = &manifold.points[j];
                    cp.position = b1.worldPoint(mp.localPoint1);
                    bVec2 v1 = b1.linearVelocityFromLocalPoint(mp.localPoint1);
                    bVec2 v2 = b2.linearVelocityFromLocalPoint(mp.localPoint2);
                    cp.velocity = v2 - v1;
                    cp.separation = mp.separation;
                    cp.id = mp.id;
                    m_world.contactListener.remove(cp);
                }
            }
        }

        // Remove from the world.
        if (c.prev) {
            c.prev.next = c.next;
        }

        if (c.next) {
            c.next.prev = c.prev;
        }

        if (c == m_world.contactList) {
            m_world.contactList = c.next;
        }

        Body body1 = shape1.rBody;
        Body body2 = shape2.rBody;

        // Remove from body 1
        if (c.node1.prev) {
            c.node1.prev.next = c.node1.next;
        }

        if (c.node1.next) {
            c.node1.next.prev = c.node1.prev;
        }

        if (c.node1 == body1.contactList) {
            body1.contactList = c.node1.next;
        }

        // Remove from body 2
        if (c.node2.prev) {
            c.node2.prev.next = c.node2.next;
        }

        if (c.node2.next) {
            c.node2.next.prev = c.node2.prev;
        }

        if (c.node2 == body2.contactList) {
            body2.contactList = c.node2.next;
        }

        // Call the factory.
        //factory.destroy(c);
        delete c;
        m_world.contactCount--;
    }

// This is the top level collision call for the time step. Here
// all the narrow phase collision is processed for the world
// contact list.
    void collide() {
        // Update awake contacts.
        for (Contact c = m_world.contactList; c; c = c.next) {
            Body body1 = c.shape1.rBody;
            Body body2 = c.shape2.rBody;
            if ((body1.flags & body2.flags) & Body.SLEEP) {
                continue;
            }
            c.update(m_world.contactListener);
        }
    }
}
