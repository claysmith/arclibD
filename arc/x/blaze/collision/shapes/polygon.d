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
module arc.x.blaze.collision.shapes.polygon;

import arc.x.blaze.common.math;
import arc.x.blaze.common.constants;
import arc.x.blaze.collision.shapes.shape;
import arc.x.blaze.collision.shapes.shapeType;
import arc.x.blaze.collision.collision;

/** Convex polygon. The vertices must be in CCW order for a right-handed
 * coordinate system with the z-axis coming out of the screen.
 */
class PolyDef : ShapeDef {

    /** The polygon vertices in local coordinates. */
    bVec2[] vertices;

    this() {
        type = ShapeType.POLYGON;
    }

    this(float density, bVec2[] vertices) {
        super.density = density;
        this.vertices = vertices.dup;
        type = ShapeType.POLYGON;
    }

    /**
     * Build vertices to represent an axis-aligned box.
     * @param hx the half-width.
     * @param hy the half-height.
     */
    override void setAsBox(float hx, float hy) {
        vertices.length = 4;
        vertices[0].set(-hx, -hy);
        vertices[1].set( hx, -hy);
        vertices[2].set( hx,  hy);
        vertices[3].set(-hx,  hy);
    }

    /**
     * Build vertices to represent an oriented box.
     * @param hx the half-width.
     * @param hy the half-height.
     * @param center the center of the box in local coordinates.
     * @param angle the rotation of the box in local coordinates.
     */
    void setAsBox(float hx, float hy, bVec2 center, float angle) {
        setAsBox(hx, hy);
        bXForm xf;
        xf.position = center;
        xf.R.set(angle);

        for (int i = 0; i < vertices.length; ++i) {
            vertices[i] = bMul(xf, vertices[i]);
        }
    }
}

class Polygon : Shape {

    /** Get the first vertex and apply the supplied transform. */
    bVec2 firstVertex(bXForm xf) {
        return bMul(xf, m_coreVertices[0]);
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
        bMat22 R = bMul(xf.R, m_obb.R);
        bMat22 absR = bzAbs(R);
        bVec2 h = bMul(absR, m_obb.extents);
        bVec2 position = xf.position + bMul(xf.R, m_obb.center);
        m_aabb.lowerBound = position - h;
        m_aabb.upperBound = position + h;
    }

    /** Get the oriented bounding box relative to the parent body. */
    OBB obb() {
        return m_obb;
    }

    /** Get local centroid relative to the parent body. */
    bVec2 centroid() {
        return m_centroid;
    }

    /** Get the centroid and apply the supplied transform. */
    bVec2 centroid(bXForm xf) {
        return bMul(xf, m_centroid);
    }

    /** Get the vertex count */
    int vertexCount() {
        return m_vertexCount;
    }

    /** Get the vertices in local coordinates. */
    bVec2[] vertices() {
        return m_vertices;
    }

    /** Get the vertices in world coordinates */
    bVec2[] worldVertices() {
        bVec2[] worldVertices;
        worldVertices.length = m_vertices.length;
        bXForm xf = rBody.xf;
        for (int i = 0; i < m_vertices.length; i++) {
            worldVertices[i] = bMul(xf, m_vertices[i]);
        }
        return worldVertices;
    }

	/** The polygon's centroid in world coordinates */
	bVec2 worldCenter() {
		bXForm xf = rBody.xf;
		return bMul(xf, m_centroid);
	}

    /**
     * Get the core vertices in local coordinates. These vertices
     * represent a smaller polygon that is used for time of impact
     * computations.
     */
    bVec2[] coreVertices() {
        return m_coreVertices;
    }

    /** Get the edge normal vectors. There is one for each vertex. */
    bVec2[] normals() {
        return m_normals;
    }

    this (ShapeDef def) {
        assert(def.type == ShapeType.POLYGON);
        super(def);
        m_type = ShapeType.POLYGON;
        PolyDef poly = cast (PolyDef) def;

        // Get the vertices transformed into the body frame.
        m_vertexCount = poly.vertices.length;
        assert(3 <= m_vertexCount && m_vertexCount <= k_maxPolygonVertices);

        // Copy vertices.
        m_vertices = poly.vertices.dup;
        m_normals.length = m_vertexCount;
        m_coreVertices.length = m_vertexCount;

        // Compute normals. Ensure the edges have non-zero length.
        for (int i = 0; i < m_vertexCount; ++i) {
            int i1 = i;
            int i2 = i + 1 < m_vertexCount ? i + 1 : 0;
            bVec2 edge = m_vertices[i2] - m_vertices[i1];
            assert(edge.lengthSquared > float.epsilon * float.epsilon);
            m_normals[i] = bCross(edge, 1.0f);
            m_normals[i].normalize;
        }

        // Ensure the polygon is convex.
        // http://local.wasp.uwa.edu.au/~pbourke/geometry/clockwise/source1.c
        int i,j,k;
        int flag = 0;
        double z;
        bVec2[] p;
        p = vertices.dup;
        int n = vertices.length;

        for (i=0;i<n;i++) {
            j = (i + 1) % n;
            k = (i + 2) % n;
            z  = (p[j].x - p[i].x) * (p[k].y - p[j].y);
            z -= (p[j].y - p[i].y) * (p[k].x - p[j].x);
            if (z < 0)
                flag |= 1;
            else if (z > 0)
                flag |= 2;
            if (flag == 3)
                throw new Exception("Your polygon must be convex");
        }

        if(flag is 0) {
            throw new Exception("Incomputable polgon eg: colinear points");
        }

        // Ensure the polygon is counter-clockwise.
        float ccw = bCross(vertices[1] - vertices[0], vertices[2] - vertices[1]);
        if(ccw <= k_angularSlop) {
            throw new Exception("Polygon must be ordered counter-clockwise");
        }

        // Compute the polygon centroid.
        m_centroid = computeCentroid(poly.vertices);

        // Compute the oriented bounding box.
        computeOBB(m_obb, m_vertices);

        // Create core polygon shape by shifting edges inward.
        // Also compute the min/max radius for CCD.
        for (i = 0; i < m_vertexCount; ++i) {
            int i1 = i - 1 >= 0 ? i - 1 : m_vertexCount - 1;
            int i2 = i;

            bVec2 n1 = m_normals[i1];
            bVec2 n2 = m_normals[i2];
            bVec2 v = m_vertices[i] - m_centroid;

            bVec2 d;
            d.x = bDot(n1, v) - k_toiSlop;
            d.y = bDot(n2, v) - k_toiSlop;

            // Shifting the edge inward by _toiSlop should
            // not cause the plane to pass the centroid.

            // Your shape has a radius/extent less than _toiSlop.
            assert(d.x >= 0.0f);
            assert(d.y >= 0.0f);
            bMat22 A;
            A.col1.x = n1.x;
            A.col2.x = n1.y;
            A.col1.y = n2.x;
            A.col2.y = n2.y;
            m_coreVertices[i] = A.solve(d) + m_centroid;
        }
    }

    void updateSweepRadius(bVec2 center) {

        // Update the sweep radius (maximum radius) as measured from
        // a local center point.
        m_sweepRadius = 0.0f;
        for (int i = 0; i < m_vertexCount; ++i) {
            bVec2 d = m_coreVertices[i] - center;
            m_sweepRadius = max(m_sweepRadius, d.length());
        }
    }

    bool testPoint(bXForm xf, bVec2 p) {

        bVec2 pLocal = bMulT(xf.R, p - xf.position);
        for (int i = 0; i < m_vertexCount; ++i) {
            float bDot = bDot(m_normals[i], pLocal - m_vertices[i]);
            if (bDot > 0.0f) {
                return false;
            }
        }
        return true;
    }

    SegmentCollide testSegment(bXForm xf, inout float lambda, inout bVec2 normal, Segment segment, float maxLambda) {

        float lower = 0.0f;
        float upper = maxLambda;

        bVec2 p1 = bMulT(xf.R, segment.p1 - xf.position);
        bVec2 p2 = bMulT(xf.R, segment.p2 - xf.position);
        bVec2 d = p2 - p1;
        int index = -1;

        for (int i = 0; i < m_vertexCount; ++i) {
            // p = p1 + a * d
            // bDot(normal, p - v) = 0
            // bDot(normal, p1 - v) + a * bDot(normal, d) = 0
            float numerator = bDot(m_normals[i], m_vertices[i] - p1);
            float denominator = bDot(m_normals[i], d);

            if (denominator == 0.0f) {
                if (numerator < 0.0f) {
                    return SegmentCollide.MISS;
                }
            } else {
                // Note: we want this predicate without division:
                // lower < numerator / denominator, where denominator < 0
                // Since denominator < 0, we have to flip the inequality:
                // lower < numerator / denominator <==> denominator * lower > numerator.
                if (denominator < 0.0f && numerator < lower * denominator) {
                    // Increase lower.
                    // The segment enters this half-space.
                    lower = numerator / denominator;
                    index = i;
                } else if (denominator > 0.0f && numerator < upper * denominator) {
                    // Decrease upper.
                    // The segment exits this half-space.
                    upper = numerator / denominator;
                }
            }

            if (upper < lower) {
                return SegmentCollide.MISS;
            }
        }

        assert(0.0f <= lower && lower <= maxLambda);

        if (index >= 0) {
            lambda = lower;
            normal = bMul(xf.R, m_normals[index]);
            return SegmentCollide.HIT;
        }

        lambda = 0;
        return SegmentCollide.STARTS_INSIDE;
    }

    void computeAABB(inout AABB aabb, bXForm xf) {
        bMat22 R = bMul(xf.R, m_obb.R);
        bMat22 absR = bzAbs(R);
        bVec2 h = bMul(absR, m_obb.extents);
        bVec2 position = xf.position + bMul(xf.R, m_obb.center);
        aabb.lowerBound = position - h;
        aabb.upperBound = position + h;
    }

    void computeSweptAABB(bXForm xf1, bXForm xf2) {
        AABB aabb1, aab;
        computeAABB(aabb1, xf1);
        computeAABB(aab, xf2);
        m_aabb.lowerBound = bzMin(aabb1.lowerBound, aab.lowerBound);
        m_aabb.upperBound = bzMax(aabb1.upperBound, aab.upperBound);
    }

    void computeMass(inout MassData massData) {

        // Polygon mass, centroid, and inertia.
        // Let rho be the polygon density in mass per unit area.
        // Then:
        // mass = rho * int(dA)
        // centroid.x = (1/mass) * rho * int(x * dA)
        // centroid.y = (1/mass) * rho * int(y * dA)
        // I = rho * int((x*x + y*y) * dA)
        //
        // We can compute these integrals by summing all the integrals
        // for each triangle of the polygon. To evaluate the integral
        // for a single triangle, we make a change of variables to
        // the (u,v) coordinates of the triangle:
        // x = x0 + e1x * u + e2x * v
        // y = y0 + e1y * u + e2y * v
        // where 0 <= u && 0 <= v && u + v <= 1.
        //
        // We integrate u from [0,1-v] and then v from [0,1].
        // We also need to use the Jacobian of the transformation:
        // D = bCross(e1, e2)
        //
        // Simplification: triangle centroid = (1/3) * (p1 + p2 + p3)
        //
        // The rest of the derivation is handled by computer algebra.

        assert(m_vertexCount >= 3);

        bVec2 center;
		area = 0.0f;
        float I = 0.0f;

        // pRef is the reference point for forming triangles.
        // It's location doesn't change the result (except for rounding error).
        bVec2 pRef;

        // This code would put the reference point inside the polygon.
        for (int i = 0; i < m_vertexCount; ++i) {
            pRef += m_vertices[i];
        }
        pRef *= 1.0f / m_vertexCount;

        const float k_inv3 = 1.0f / 3.0f;

        for (int i = 0; i < m_vertexCount; ++i) {
            // Triangle vertices.
            bVec2 p1 = pRef;
            bVec2 p2 = m_vertices[i];
            bVec2 p3 = i + 1 < m_vertexCount ? m_vertices[i+1] : m_vertices[0];

            bVec2 e1 = p2 - p1;
            bVec2 e2 = p3 - p1;

            float D = bCross(e1, e2);

            float triangleArea = 0.5f * D;
            area += triangleArea;

            // Area weighted centroid
            center += triangleArea * k_inv3 * (p1 + p2 + p3);

            float px = p1.x, py = p1.y;
            float ex1 = e1.x, ey1 = e1.y;
            float ex2 = e2.x, ey2 = e2.y;

            float intx2 = k_inv3 * (0.25f * (ex1*ex1 + ex2*ex1 + ex2*ex2) + (px*ex1 + px*ex2)) + 0.5f*px*px;
            float inty2 = k_inv3 * (0.25f * (ey1*ey1 + ey2*ey1 + ey2*ey2) + (py*ey1 + py*ey2)) + 0.5f*py*py;

            I += D * (intx2 + inty2);
        }

        // Total mass
        massData.mass = m_density * area;

        // Center of mass
        assert(area > float.epsilon);
        center *= 1.0f / area;
        massData.center = center;

        // Inertia tensor relative to the local origin.
        massData.I = m_density * I;
    }

    bVec2 support(bXForm xf, bVec2 d) {

        bVec2 dLocal = bMulT(xf.R, d);
        int bestIndex = 0;
        float bestValue = bDot(m_coreVertices[0], dLocal);
        for (int i = 1; i < m_vertexCount; ++i) {
            float value = bDot(m_coreVertices[i], dLocal);
            if (value > bestValue) {
                bestIndex = i;
                bestValue = value;
            }
        }

        return bMul(xf, m_coreVertices[bestIndex]);
    }

    /**
	* Triangulate the shape in world coordinates.
	* Used by the buoyancy solver.
	*/
	override void triangulate() {
		m_triangleList.length = 0;
        //triangulate by center-point
        bXForm xf = rBody.xf;
		bVec2 p1 = bMul(xf, m_centroid);
		bVec2[] v = worldVertices();
		int count = v.length;
		for (int i = 0; i < count; ++i) {
			// Triangle vertices.
			bVec2 p2 = v[i];
			bVec2 p3 = i + 1 < count ? v[i+1] : v[0];
			m_triangleList ~= bTri2(p1, p2, p3);
		}
    }

private:

    // Local position of the polygon centroid.
    bVec2 m_centroid;

    OBB m_obb;

    bVec2[] m_vertices;
    bVec2[] m_normals;
    bVec2[] m_coreVertices;
    int m_vertexCount;

}

bVec2 computeCentroid(bVec2[] vs) {

    int count = vs.length;
    assert(count >= 3);

    bVec2 c;
    float area = 0.0f;

    // pRef is the reference point for forming triangles.
    // It's location doesn't change the result (except for rounding error).
    bVec2 pRef;


    // This code would put the reference point inside the polygon.
    for (int i = 0; i < count; ++i) {
        pRef += vs[i];
    }
    pRef *= 1.0f / count;


    const float inv3 = 1.0f / 3.0f;

    for (int i = 0; i < count; ++i) {
        // Triangle vertices.
        bVec2 p1 = pRef;
        bVec2 p2 = vs[i];
        bVec2 p3 = i + 1 < count ? vs[i+1] : vs[0];

        bVec2 e1 = p2 - p1;
        bVec2 e2 = p3 - p1;

        float D = bCross(e1, e2);

        float triangleArea = 0.5f * D;
        area += triangleArea;

        // Area weighted centroid
        c += triangleArea * inv3 * (p1 + p2 + p3);
    }

    // Centroid
    assert(area > float.epsilon);
    c *= 1.0f / area;
    return c;
}

// http://www.geometrictools.com/Documentation/minNumimumAreaRectangle.pdf
void computeOBB(inout OBB obb, bVec2[] vs) {

    bVec2[] p;
    p = vs.dup;
    p ~= p[0];

    float minArea = float.max;

    for (int i = 1; i <= vs.length; ++i) {
        bVec2 root = p[i-1];
        bVec2 ux = p[i] - root;
        float length = ux.normalize;
        assert(length > float.epsilon);
        bVec2 uy = bVec2(-ux.y, ux.x);
        bVec2 lower = bVec2(float.max, float.max);
        bVec2 upper = bVec2(-float.max, -float.max);

        for (int j = 0; j < p.length; ++j) {
            bVec2 d = p[j] - root;
            bVec2 r;
            r.x = bDot(ux, d);
            r.y = bDot(uy, d);
            lower = bzMin(lower, r);
            upper = bzMax(upper, r);
        }

        float area = (upper.x - lower.x) * (upper.y - lower.y);
        if (area < 0.95f * minArea) {
            minArea = area;
            obb.R.col1 = ux;
            obb.R.col2 = uy;
            bVec2 center = 0.5f * (lower + upper);
            obb.center = root + bMul(obb.R, center);
            obb.extents = 0.5f * (upper - lower);
        }
    }

    assert(minArea < float.max);
}
