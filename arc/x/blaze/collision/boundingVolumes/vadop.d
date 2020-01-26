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
module arc.x.blaze.collision.boundingVolumes.vadop;

import arc.x.blaze.common.math;

struct VADOP {

	float[] max;
	float[] min;

	bVec2 vel;

	//max[uint] y;
	//min[uint] x;

	int x, y;

	static VADOP opCall(float[] qmin, float[] qmax, bVec2 velocity)
	{
		VADOP a;
		a.min[0] = qmin[0]; a.min[1] = qmin[1];
		a.max[0] = qmax[0]; a.max[1] = qmax[1];
		a.vel = velocity;
		return a;
	}

	void initAxes()
	{
		bVec2 ortho = vel.rotateRight90;
		float angle;

		// 180/k, with k = 8, equals 22.5 degrees
		// Calculate ortho position on circle in degrees
		// Add all axes 45 degrees to left and right of ortho position.

		// Find position in polar coordinates
		if (ortho.x > 0 && ortho.y >= 0)
			angle = atan(y / x);
		else if (ortho.x > 0 && ortho.y > 0)
			angle = atan(y / x) + 2 * PI;
		else if (ortho.x < 0)
			angle = atan(y / x) + PI;
		else if (ortho.x == 0 && ortho.y == 0)
			angle = PI / 2;
		else if (ortho.x == 0 && ortho.y < 0)
			angle = 3 * PI / 2;
	}

	void update()
	{
	}
}
