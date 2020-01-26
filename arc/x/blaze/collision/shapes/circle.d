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
module arc.x.blaze.collision.shapes.circle;

import arc.x.blaze.common.math;
import arc.x.blaze.common.constants;
import arc.x.blaze.collision.shapes.shape;
import arc.x.blaze.collision.shapes.shapeType;
import arc.x.blaze.collision.collision;

/** This is used to build circle shapes. */
class CircleDef : ShapeDef
{
	this(float density, float radius)
	{
		type = ShapeType.CIRCLE;
		localPosition.zero();
		this.radius = radius;
		super.density = density;
	}

	bVec2 localPosition;
	float radius = 0.0f;
}

/** A circle shape. */
class Circle : Shape {

    this (ShapeDef def) {
        assert(def.type == ShapeType.CIRCLE);
        super(def);
        CircleDef circleDef = cast(CircleDef) def;
        m_type = ShapeType.CIRCLE;
        m_localPosition = circleDef.localPosition;
        m_radius = circleDef.radius;
		area = PI * m_radius * m_radius;
    }

    ///
    bool testPoint(bXForm xf, bVec2 p) {
        bVec2 center = xf.position + bMul(xf.R, m_localPosition);
        bVec2 d = p - center;
        return bDot(d, d) <= m_radius * m_radius;
    }

    /** Returns the axis aligned bounding box associated with the shape, in
     * reference to the parent body's transform
     */
    AABB aabb() {
        return m_aabb;
    }

    /** Update the AABB */
    void updateAABB() {
        bXForm xf = rBody.xf;
        bVec2 p = xf.position + bMul(xf.R, m_localPosition);
        m_aabb.lowerBound.set(p.x - m_radius, p.y - m_radius);
        m_aabb.upperBound.set(p.x + m_radius, p.y + m_radius);
    }

	bVec2 worldCenter() {
		bXForm xf = rBody.xf;
		return bMul(xf, m_localPosition);
	}

    /**
     * Collision Detection in Interactive 3D Environments by Gino van den Bergen
     * From Section 3.1.2
     * x = s + a * r
     * norm(x) = radius
     */
    SegmentCollide testSegment(bXForm xf, inout float lambda, inout bVec2 normal, Segment segment, float maxLambda)  {
        bVec2 position = xf.position + bMul(xf.R, m_localPosition);
        bVec2 s = segment.p1 - position;
        float b = bDot(s, s) - m_radius * m_radius;

        // Does the segment start inside the circle?
        if (b < 0.0f) {
            lambda = 0;
            return SegmentCollide.STARTS_INSIDE;
        }

        // Solve quadratic equation.
        bVec2 r = segment.p2 - segment.p1;
        float c =  bDot(s, r);
        float rr = bDot(r, r);
        float sigma = c * c - rr * b;

        // Check for negative discriminant and short segment.
        if (sigma < 0.0f || rr < float.epsilon) {
            return SegmentCollide.MISS;
        }

        // Find the point of intersection of the line with the circle.
        float a = -(c + sqrt(sigma));

        // Is the intersection point on the segment?
        if (0.0f <= a && a <= maxLambda * rr) {
            a /= rr;
            lambda = a;
            normal = s + a * r;
            normal.normalize;
            return SegmentCollide.HIT;
        }

        return SegmentCollide.MISS;
    }

    void computeAABB(inout AABB aabb, bXForm xf)
    {
        bVec2 p = xf.position + bMul(xf.R, m_localPosition);
        aabb.lowerBound.set(p.x - m_radius, p.y - m_radius);
        aabb.upperBound.set(p.x + m_radius, p.y + m_radius);
    }

    void computeSweptAABB(bXForm xf1, bXForm xf2)
    {
        bVec2 p1 = xf1.position + bMul(xf1.R, m_localPosition);
        bVec2 p2 = xf2.position + bMul(xf2.R, m_localPosition);
        bVec2 lower = bzMin(p1, p2);
        bVec2 upper = bzMax(p1, p2);
        m_aabb.lowerBound.set(lower.x - m_radius, lower.y - m_radius);
        m_aabb.upperBound.set(upper.x + m_radius, upper.y + m_radius);
    }

    void computeMass(inout MassData massData)
    {
        massData.mass = m_density * PI * m_radius * m_radius;
        massData.center = m_localPosition;
        // inertia about the local origin
        massData.I = massData.mass * (0.5f * m_radius * m_radius + bDot(m_localPosition, m_localPosition));
    }

    /** Get the local position of this circle in its parent body. */
    bVec2 localPosition() {
        return m_localPosition;
    }

    /** Get the radius of this circle. */
    float radius() {
        return m_radius;
    }
    
    bVec2 support(bXForm xf, bVec2 d) {
        d.normalize();
        bVec2 r = m_radius * d;
        r += worldCenter;
        return r;
    }

protected:

    void updateSweepRadius(bVec2 center) {
        // Update the sweep radius (maximum radius) as measured from
        // a local center point.
        bVec2 d = m_localPosition - center;
        m_sweepRadius = d.length + m_radius - k_toiSlop;
    }

    // Local position in parent body
    bVec2 m_localPosition;
    float m_radius = 0.0f;
};




