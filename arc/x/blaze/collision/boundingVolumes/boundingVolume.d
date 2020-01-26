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
module arc.x.blaze.collision.boundingVolumes.boundingVolume;


import arc.x.blaze.common.math;

abstract class BoundingVolume {
///
static bool intersect(BoundingVolume v1, BoundingVolume v2)
{
	if (v1.getMax(0) < v2.getMin(0) || v1.getMin(0) > v2.getMax(0)) return false;
	if (v1.getMax(1) < v2.getMin(1) || v1.getMin(1) > v2.getMax(1)) return false;
	return true;
}

abstract float getMin(int axis);
abstract void setMin(float min, int axis);
abstract float getMax(int axis);
abstract void setMax(float max, int axis);
abstract void update(bVec2[] vertices);
abstract float[] getCenter();
abstract bool contains(bVec2 point);
}
