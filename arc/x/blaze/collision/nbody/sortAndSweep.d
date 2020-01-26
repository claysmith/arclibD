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
module arc.x.blaze.collision.nbody.sortAndSweep;

import arc.x.blaze.collision.collision;
import arc.x.blaze.collision.nbody.broadPhase;
import arc.x.blaze.collision.shapes.shape;
import arc.x.blaze.collision.shapes.shapeType;
import arc.x.blaze.collision.shapes.fluidParticle;
import arc.x.blaze.dynamics.contact.contact;

import arc.x.blaze.world;

/** Sort & Sweep algorithm */
class SortAndSweep : BroadPhase {

    /** Specifies axis (0/1) to sort on */
    int gSortAxis;

    this(World world) {
        super(world);
        // Arbitrarily initialized
        gSortAxis = 1;
    }

    /** Sort & Sweep algorithm, from "Real-Time Collision Detection" by Christer Ericson */
    override void search() {

        resetContactPool();

        // Sort the AABB's on currently selected sorting axis (gSortAxis)
        shellSort();

        // Sweep the array for collisions
        for (int i = 0; i < shapes.length; i++) {
            Shape s1 = shapes[i];
            // Test collisions against all possible overlapping AABBs following current one
            for (int j = i + 1; j < shapes.length; j++) {
                Shape s2 = shapes[j];
                // Stop when tested AABBs are beyond the end of current AABB
                if (s2.aabb.lowerBound.x > s1.aabb.upperBound.x) break;
                // Particle-particle collisions
                if (s1.type == ShapeType.FLUID && s2.type == ShapeType.FLUID) {
                    FluidParticle p1 = cast(FluidParticle) s1;
                    FluidParticle p2 = cast(FluidParticle) s2;
                    if (testOverlap(p1.aabb, p2.position)) {
                        p1.addNeighbor(p2.ID);
                    }
                    if (testOverlap(p2.aabb, p1.position)) {
                        p2.addNeighbor(p1.ID);
                    }
                } else {
                    // Everything else
                    if (testOverlap(s1.aabb, s2.aabb)) {
                        // Particle/shape contacts are added to a separate list
                        if(s1.type == ShapeType.FLUID || s2.type == ShapeType.FLUID) {
                            SPHContact sph;
                            sph.shape1 = s1; sph.shape2 = s2;
                            sphList ~= sph;
                        } else {
                            // Everything else (polygons/circles) reports to the contact manager
                            updatePool(i, j);
                        }
                    }
                }
            }
        }
        scrubContactPool();
        processFluidContacts();
    }

    /** Array Shell sort algorithm */
    void shellSort() {
        int increment = cast(int)(shapes.length * 0.5f);
        while (increment > 0) {
            for (int i = increment; i < shapes.length; i++) {
                int j = i;
                Shape temp = shapes[i];
                while ((j >= increment)
                       && (shapes[j - increment].aabb.lowerBound.x > temp.aabb.lowerBound.x)) {
                    shapes[j] = shapes[j - increment];
                    j = j - increment;
                }
                shapes[j] = temp;
            }
            if (increment == 2) {
                 increment = 1;
            } else {
                increment = cast(int)(increment * 0.45454545f);
            }
        }
    }

}
