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
module arc.x.blaze.collision.boundingVolumes.aabb;


import arc.x.blaze.common.math;
import arc.x.blaze.collision.boundingVolumes.boundingVolume;

///
class AABB : BoundingVolume {
    ///
    private float[2] max;
    ///
    private float[2] min;

    this() {
        min[0] = 0.0f;
        min[1] = 0.0f;
        max[0] = 0.0f;
        max[1] = 0.0f;
    }

    ///
    override void update(bVec2[] vertices) {
        min[0] = vertices[0].x;
        min[1] = vertices[0].y;
        max[0] = min[0];
        max[1] = min[1];
        for (int i = 0; i < vertices.length; i++) {
            bVec2 vertice = vertices[i];
            if (vertice.x < min[0]) min[0] = vertice.x;
            if (vertice.x > max[0]) max[0] = vertice.x;
            if (vertice.y < min[1]) min[1] = vertice.y;
            if (vertice.y > max[1]) max[1] = vertice.y;
        }
    }

    ///
    override float[] getCenter() {
        float[] center;
        center.length = 2;
        center[0] = min[0] + (max[0] - min[0]) * 0.5f;
        center[1] = min[1] + (max[1] - min[1]) * 0.5f;
        return center;
    }

    override float getMin(int axis) {
        return min[axis];
    }

    override void setMin(float min, int axis) {
        this.min[axis] = min;
    }

    override float getMax(int axis) {
        return max[axis];
    }

    override void setMax(float max, int axis) {
        this.max[axis] = max;
    }

    ///
    override bool contains(bVec2 point) {
        /// Using epsilon to try and gaurd against float rounding errors.
        if ((point.x > (min[0] + float.epsilon) && point.x < (max[0] - float.epsilon)
                && (point.y > (min[1] + float.epsilon) && point.y < (max[1] - float.epsilon)))) {
            return true;
        } else {
            return false;
        }
    }
}

