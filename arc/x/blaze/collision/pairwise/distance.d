/*
* Copyright (c) 2007 Erin Catto http://www.gphysics.com
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
module arc.x.blaze.collision.pairwise.distance;

import arc.x.blaze.common.constants;
import arc.x.blaze.common.math;
import arc.x.blaze.collision.collision;
import arc.x.blaze.collision.shapes.shape;
import arc.x.blaze.collision.shapes.circle;
import arc.x.blaze.collision.shapes.polygon;
import arc.x.blaze.collision.shapes.shapeType;

int g_GJK_Iterations = 0;

// GJK using Voronoi regions (Christer Ericson) and region selection
// optimizations (Casey Muratori).

// The origin is either in the region of points[1] or in the edge region. The origin is
// not in region of points[0] because that is the old point.
static int processTwo(inout bVec2 x1, inout bVec2 x2, inout bVec2[] p1s, inout bVec2[] p2s, inout bVec2[] points)
{
	// If in point[1] region
	bVec2 r = -points[1];
	bVec2 d = points[0] - points[1];
	float length = d.normalize();
	float lambda = bDot(r, d);
	if (lambda <= 0.0f || length < float.epsilon)
	{
		// The simplex is reduced to a point.
		x1 = p1s[1];
		x2 = p2s[1];
		p1s[0] = p1s[1];
		p2s[0] = p2s[1];
		points[0] = points[1];
		return 1;
	}

	// Else in edge region
	lambda /= length;
	x1 = p1s[1] + lambda * (p1s[0] - p1s[1]);
	x2 = p2s[1] + lambda * (p2s[0] - p2s[1]);
	return 2;
}

// Possible regions:
// - points[2]
// - edge points[0]-points[2]
// - edge points[1]-points[2]
// - inside the triangle
static int processThree(inout bVec2 x1, inout bVec2 x2, inout bVec2[] p1s, inout bVec2[] p2s, inout bVec2[] points)
{
	bVec2 a = points[0];
	bVec2 b = points[1];
	bVec2 c = points[2];

	bVec2 ab = b - a;
	bVec2 ac = c - a;
	bVec2 bc = c - b;

	float sn = -bDot(a, ab), sd = bDot(b, ab);
	float tn = -bDot(a, ac), td = bDot(c, ac);
	float un = -bDot(b, bc), ud = bDot(c, bc);

	// In vertex c region?
	if (td <= 0.0f && ud <= 0.0f)
	{
		// Single point
		x1 = p1s[2];
		x2 = p2s[2];
		p1s[0] = p1s[2];
		p2s[0] = p2s[2];
		points[0] = points[2];
		return 1;
	}

	// Should not be in vertex a or b region.
	assert(sn > 0.0f || tn > 0.0f);
	assert(sd > 0.0f || un > 0.0f);

    float n = bCross(ab, ac);

	// Should not be in edge ab region.
	float vc = n * bCross(a, b);
	assert(vc > 0.0f || sn > 0.0f || sd > 0.0f);

	// In edge bc region?
	float va = n * bCross(b, c);
	if (va <= 0.0f && un >= 0.0f && ud >= 0.0f && (un+ud) > 0.0f)
	{
		assert(un + ud > 0.0f);
		float lambda = un / (un + ud);
		x1 = p1s[1] + lambda * (p1s[2] - p1s[1]);
		x2 = p2s[1] + lambda * (p2s[2] - p2s[1]);
		p1s[0] = p1s[2];
		p2s[0] = p2s[2];
		points[0] = points[2];
		return 2;
	}

	// In edge ac region?
	float vb = n * bCross(c, a);
	if (vb <= 0.0f && tn >= 0.0f && td >= 0.0f && (tn+td) > 0.0f)
	{
		assert(tn + td > 0.0f);
		float lambda = tn / (tn + td);
		x1 = p1s[0] + lambda * (p1s[2] - p1s[0]);
		x2 = p2s[0] + lambda * (p2s[2] - p2s[0]);
		p1s[1] = p1s[2];
		p2s[1] = p2s[2];
		points[1] = points[2];
		return 2;
	}

	// Inside the triangle, compute barycentric coordinates
	float denom = va + vb + vc;
	assert(denom > 0.0f);
	denom = 1.0f / denom;

	float u = va * denom;
	float v = vb * denom;
	float w = 1.0f - u - v;
	x1 = u * p1s[0] + v * p1s[1] + w * p1s[2];
	x2 = u * p2s[0] + v * p2s[1] + w * p2s[2];

	return 3;
}

static bool inPoints(bVec2 w, bVec2[] points, int pointCount)
{
	const float k_tolerance = 100.0f * float.epsilon;
	for (int i = 0; i < pointCount; ++i)
	{
		bVec2 d = bzAbs(w - points[i]);
		bVec2 m = bzMax(bzAbs(w), bzAbs(points[i]));

		if (d.x < k_tolerance * (m.x + 1.0f) &&
			d.y < k_tolerance * (m.y + 1.0f))
		{
			return true;
		}
	}

	return false;
}

float distanceGeneric(T, U) (inout bVec2 x1, inout bVec2 x2, T shape1, bXForm xf1, U shape2, bXForm xf2)
{
	bVec2[] p1s;
	bVec2[] p2s;
	bVec2[] points;
	p1s.length = p2s.length = points.length = 3;
	int pointCount = 0;

	x1 = shape1.firstVertex(xf1);
    x2 = shape2.firstVertex(xf2);

	float vSqr = 0.0f;
	const int maxIterations = 20;
	for (int iter = 0; iter < maxIterations; ++iter)
	{
		bVec2 v = x2 - x1;
		bVec2 w1 = shape1.support(xf1, v);
		bVec2 w2 = shape2.support(xf2, -v);

		vSqr = bDot(v, v);
		bVec2 w = w2 - w1;
		float vw = bDot(v, w);
		if (vSqr - vw <= 0.01f * vSqr || inPoints(w, points, pointCount)) // or w in points
		{
			if (pointCount == 0)
			{
				x1 = w1;
				x2 = w2;
			}
			g_GJK_Iterations = iter;
			return sqrt(vSqr);
		}

		switch (pointCount)
		{
		case 0:
			p1s[0] = w1;
			p2s[0] = w2;
			points[0] = w;
			x1 = p1s[0];
			x2 = p2s[0];
			++pointCount;
			break;

		case 1:
			p1s[1] = w1;
			p2s[1] = w2;
			points[1] = w;
			pointCount = processTwo(x1, x2, p1s, p2s, points);
			break;

		case 2:
			p1s[2] = w1;
			p2s[2] = w2;
			points[2] = w;
			pointCount = processThree(x1, x2, p1s, p2s, points);
			break;
		}

		// If we have three points, then the origin is in the corresponding triangle.
		if (pointCount == 3)
		{
			g_GJK_Iterations = iter;
			return 0.0f;
		}

		float maxSqr = -float.max;
		for (int i = 0; i < pointCount; ++i)
		{
			maxSqr = max(maxSqr, bDot(points[i], points[i]));
		}

		if (vSqr <= 100.0f * float.epsilon * maxSqr)
		{
			g_GJK_Iterations = iter;
			v = x2 - x1;
			vSqr = bDot(v, v);
			return sqrt(vSqr);
		}
	}

	g_GJK_Iterations = maxIterations;
	return sqrt(vSqr);
}

static float distanceCC(inout bVec2 x1, inout bVec2 x2, Circle circle1, bXForm xf1, Circle circle2, bXForm xf2)
{
	bVec2 p1 = bMul(xf1, circle1.localPosition);
	bVec2 p2 = bMul(xf2, circle2.localPosition);

	bVec2 d = p2 - p1;
	float dSqr = bDot(d, d);
	float r1 = circle1.radius - k_toiSlop;
	float r2 = circle2.radius - k_toiSlop;
	float r = r1 + r2;
	if (dSqr > r * r)
	{
		float dLen = d.normalize();
		float distance = dLen - r;
		x1 = p1 + r1 * d;
		x2 = p2 - r2 * d;
		return distance;
	}
	else if (dSqr > float.epsilon * float.epsilon)
	{
		d.normalize();
		x1 = p1 + r1 * d;
		x2 = x1;
		return 0.0f;
	}

	x1 = p1;
	x2 = x1;
	return 0.0f;
}

// This is used for polygon-vs-circle distance.
struct Point
{
	bVec2 support(bXForm foo, bVec2 bar)
	{
		return p;
	}

	bVec2 firstVertex(bXForm fooBar)
	{
		return p;
	}

	bVec2 p;
}

// GJK is more robust with polygon-vs-point than polygon-vs-circle.
// So we convert polygon-vs-circle to polygon-vs-point.
static float distancePC(inout bVec2 x1, inout bVec2 x2, Polygon polygon, bXForm xf1, Circle circle, bXForm xf2)
{
	Point point;
	point.p = bMul(xf2, circle.localPosition);
    bXForm identity;
    identity.setIdentity;

	float distance = distanceGeneric(x1, x2, polygon, xf1, point, identity);

	return distance;
	float r = circle.radius - k_toiSlop;

	if (distance > r)
	{
		distance -= r;
		bVec2 d = x2 - x1;
		d.normalize();
		x2 -= r * d;
	}
	else
	{
		distance = 0.0f;
		x2 = x1;
	}

}

float distance(inout bVec2 x1, inout bVec2 x2, Shape shape1, bXForm xf1, Shape shape2, bXForm xf2)
{
	ShapeType type1 = shape1.type;
	ShapeType type2 = shape2.type;

	if (type1 == ShapeType.CIRCLE && type2 == ShapeType.CIRCLE)
	{
		return distanceCC(x1, x2, cast (Circle) shape1, xf1, cast (Circle) shape2, xf2);
	}

	if (type1 == ShapeType.POLYGON && type2 == ShapeType.CIRCLE)
	{
		return distancePC(x1, x2, cast (Polygon)shape1, xf1, cast (Circle)shape2, xf2);
	}

	if (type1 == ShapeType.CIRCLE && type2 == ShapeType.POLYGON)
	{
		return distancePC(x2, x1, cast (Polygon) shape2, xf2, cast (Circle) shape1, xf1);
	}

	if (type1 == ShapeType.POLYGON && type2 == ShapeType.POLYGON)
	{
		return distanceGeneric(x1, x2, cast (Polygon)shape1, xf1, cast (Polygon)shape2, xf2);
	}

	return 0.0f;
}
