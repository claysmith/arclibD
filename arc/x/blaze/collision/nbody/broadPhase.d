/*
 *  Copyright (c) 2008 Mason Green http://www.dsource.org/projects/blaze
 *
 *   This software is provided 'as-is', without any express or implied
 *   warranty. In no event will the authors be held liable for any damages
 *   arising from the use of this software.
 *
 *   Permission is granted to anyone to use this software for any purpose,
 *   including commercial applications, and to alter it and redistribute it
 *   freely, subject to the following restrictions:
 *
 *   1. The origin of this software must not be misrepresented; you must not
 *   claim that you wrote the original software. If you use this software
 *   in a product, an acknowledgment in the product documentation would be
 *   appreciated but is not required.
 *
 *   2. Altered source versions must be plainly marked as such, and must not be
 *   misrepresented as being the original software.
 *
 *   3. This notice may not be removed or altered from any source
 *   distribution.
 */
module arc.x.blaze.collision.nbody.broadPhase;

import arc.x.blaze.common.math;
import arc.x.blaze.collision.shapes.shape;
import arc.x.blaze.collision.collision;
import arc.x.blaze.dynamics.contact.contactManager;
import arc.x.blaze.dynamics.contact.contact;
import arc.x.blaze.dynamics.Body;
import arc.x.blaze.world;

struct SPHContact {
    Shape shape1;
    Shape shape2;
}

///
abstract class BroadPhase {

    /** Contact pair list */
    Contact[int] contactPool;
    /** World shape list */
    Shape[] shapes;
    /** Particle/shape contact list */
    SPHContact[] sphList;

    private ContactManager contactManager;

    this(World world) {
        contactManager = new ContactManager(world);
    }

    /**
     * Reset the contact pool.
     */
    protected void resetContactPool() {
        foreach(c; contactPool) {
            c.flag = false;
        }
    }

    /**
     * Add new contacts to the contact pool, and update existing contacts
     */
    protected void updatePool(int i1, int i2) {

        Shape s1 = shapes[i1];
        Shape s2 = shapes[i2];

        // Create Pair hash
        uint key = hash(s1.ID, s2.ID);

        if (!(key in contactPool)) {
            Contact newContact = contactManager.pairAdded(s1, s2);
            if (newContact) {
                contactPool[key] = newContact;
                newContact.hash = key;
                newContact.flag = true;
            }
        } else {
            // Contact already exists
            contactPool[key].flag = true;
        }
    }

    /**
     * Remove contacts who's bounding boxes are no longer overlaping. All keys left in the
     * arbiter pool are no longer valid.
     */
    protected void scrubContactPool() {
        uint[] key;
        foreach(c; contactPool) {
            if(c.flag is false) {
                key ~= c.hash;
            }
        }
        foreach(k; key) {
            contactPool.remove(k);
        }
    }

    /** Add shape to the shape list */
    void addShape(Shape s) {
        shapes ~= s;
    }

    /** Remove shape from the shape list */
    void removeShape(Shape s) {
        bKill(shapes, s);
    }

    void removeBodyContacts(Body b) {
        // Search all contacts connected to this body.
        for (ContactEdge cn = b.contactList; cn; cn = cn.next) {
            Contact c = cn.contact;
            uint hash = c.hash;
            contactPool.remove(hash);
            contactManager.pairRemoved(c);
            cn.other.wakeup();
        }
    }

    /** Brute force query for overlapping AABB */
    void query(AABB aabb, inout Shape[] results) {
        for (int i = 0; i < shapes.length; i++) {
            auto s = shapes[i];
            s.updateAABB();
            // TODO Add collision filtering
            // Test for AABB intersect
            if (testOverlap(aabb, s.aabb)) {
                results ~= s;
            }
        }
    }

    /** Process the fluid/shape contacts */
    void processFluidContacts() {
        foreach(s; sphList) {
            Contact c = contactManager.factory.create(s.shape1, s.shape2);
            c.update(null);
        }
        delete sphList;
    }

    /** Update broadphase */
    abstract void search();

    /**
     * Thomas Wang's hash, see: http://www.concentric.net/~Ttwang/tech/inthash.htm
     * This assumes Id1 and Id2 are 16-bit.
     */
    uint hash(uint ID1, uint ID2) {
        uint key = (ID1 << 16) | ID2;
        key = ~key + (key << 15);
        key = key ^ (key >> 12);
        key = key + (key << 2);
        key = key ^ (key >> 4);
        key = key * 2057;
        key = key ^ (key >> 16);
        return key;
    }
}

