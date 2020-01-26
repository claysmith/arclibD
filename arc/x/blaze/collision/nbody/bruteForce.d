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
module arc.x.blaze.collision.nbody.bruteForce;

import arc.x.blaze.collision.nbody.broadPhase;
import arc.x.blaze.collision.collision;
import arc.x.blaze.world;

/**
 * Checks every possible pair against each other
 * time complexity: n(n-1)/2 ~ O(n^2).
 */
public class BruteForce : BroadPhase {

    this(World world) {
        super(world);
    }

    void search() {

        resetContactPool();

        for (int i = 0; i < shapes.length; i++) {
            auto s1 = shapes[i];
            for (int j = i + 1; j < shapes.length; j++) {
                auto s2 = shapes[j];
                // TODO Add collision filtering
                // Test for AABB intersect
                if (testOverlap(s1.aabb, s2.aabb)) {
                    updatePool(i, j);
                }
            }
        }

        scrubContactPool();

    }
}
