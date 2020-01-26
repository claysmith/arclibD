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
module arc.x.blaze.collision.boundingVolumes.pointVolume;


import arc.x.blaze.common.math;
import arc.x.blaze.common.constants;
import arc.x.blaze.collision.boundingVolumes.boundingVolume;

///
class PointVolume : BoundingVolume {
private float[2] center;
float gridSize = CELL_SPACE * 1.25f;

this() {
}

///
override void update(bVec2[] vert)
{
	assert(vert.length == 1);
	center[0] = vert[0].x;
	center[1] = vert[0].y;
}

///
override float[] getCenter()
{
	return center;
}

override float getMin(int axis)
{
	return center[axis];
}

override void setMin(float min, int axis)
{
	center[axis] = min;
}

override float getMax(int axis)
{
	return center[axis];
}

override void setMax(float max, int axis)
{
	center[axis] = max;
}

///
override bool contains(bVec2 point)
{
	float maxX = center[0] + gridSize;
	float minX = center[0] - gridSize;
	float maxY = center[1] + gridSize;
	float minY = center[1] - gridSize;

	/// Using epsilon to try and gaurd against float rounding errors.
	if ((point.x > (minX + float.epsilon) && point.x < (maxX - float.epsilon)
	     && (point.y > (minY + float.epsilon) && point.y < (maxY - float.epsilon)))) {
		return true;
	} else {
		return false;
	}
}
}

