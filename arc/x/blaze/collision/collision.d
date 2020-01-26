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
module arc.x.blaze.collision.collision;

import arc.x.blaze.common.math;
import arc.x.blaze.common.constants;

/** Contact point ID */
union ContactID {
    /** Contact features */
    struct Features {
        uint referenceEdge;
        uint incidentEdge;
        uint incidentVertex;
        uint flip;
    }
    ///
    Features features;
    ///
    int key;
}

/**
 * A manifold point is a contact point belonging to a contact
 * manifold. It holds details related to the geometry and dynamics
 * of the contact points.
 * The point is stored in local coordinates because CCD
 * requires sub-stepping in which the separation is stale.
 */
struct ManifoldPoint {
    bVec2 localPoint1;		///< local position of the contact point in body1
    bVec2 localPoint2;		///< local position of the contact point in body2
    float separation;		///< the separation of the shapes along the normal vector
    float normalImpulse;	///< the non-penetration impulse
    float tangentImpulse;	///< the friction impulse
    ContactID id;			///< uniquely identifies a contact point between two shapes
}

/** A manifold for two touching convex shapes. */
struct Manifold {
    ManifoldPoint points[k_maxManifoldPoints];	///< the points of contact
    bVec2 normal;	        ///< the shared unit normal vector
    int pointCount;	        ///< the number of manifold points
}

/** An axis aligned bounding box. */
struct AABB {
    bVec2 lowerBound;	///< the lower vertex (lower left)
    bVec2 upperBound;	///< the upper vertex (upper right)
}

/** An oriented bounding box. */
struct OBB {
    bMat22 R;			///< the rotation matrix
    bVec2 center;		///< the local centroid
    bVec2 extents;		///< the half-widths
}

/** Test if two AABB's overlap */
bool testOverlap(AABB a, AABB b) {

    bVec2 firstMin = a.lowerBound;
    bVec2 firstMax = a.upperBound;
    bVec2 secondMin = b.lowerBound;
    bVec2 secondMax = b.upperBound;

    bool overlap = (firstMin.x < secondMax.x) && (firstMax.x > secondMin.x) &&
                   (firstMin.y < secondMax.y) && (firstMax.y > secondMin.y);

    return overlap;
}

/** Test if AABB contains the given point */
bool testOverlap(AABB a, bVec2 point) {
    /// Using epsilon to try and gaurd against float rounding errors.
    if ((point.x < (a.upperBound.x + float.epsilon) && point.x > (a.lowerBound.x - float.epsilon)
            && (point.y < (a.upperBound.y + float.epsilon) && point.y > (a.lowerBound.y - float.epsilon)))) {
        return true;
    } else {
        return false;
    }

}

/** A line segment. */
struct Segment {

    bVec2 p1;	///< the starting point
    bVec2 p2;	///< the ending point

    // Ray cast against this segment with another segment.
    // Collision Detection in Interactive 3D Environments by Gino van den Bergen
    // From Section 3.4.1
    // x = mu1 * p1 + mu2 * p2
    // mu1 + mu2 = 1 && mu1 >= 0 && mu2 >= 0
    // mu1 = 1 - mu2;
    // x = (1 - mu2) * p1 + mu2 * p2
    //   = p1 + mu2 * (p2 - p1)
    // x = s + a * r (s := start, r := end - start)
    // s + a * r = p1 + mu2 * d (d := p2 - p1)
    // -a * r + mu2 * d = b (b := s - p1)
    // [-r d] * [a; mu2] = b
    // Cramer's rule:
    // denom = det[-r d]
    // a = det[b d] / denom
    // mu2 = det[-r b] / denom
    bool testSegment(inout float lambda, inout bVec2 normal, Segment segment, float maxLambda) {
        bVec2 s = segment.p1;
        bVec2 r = segment.p2 - s;
        bVec2 d = p2 - p1;
        bVec2 n = bCross(d, 1.0f);

        float k_slop = 100.0f * float.epsilon;
        float denom = -bDot(r, n);

        // Cull back facing collision and ignore parallel segments.
        if (denom > k_slop) {
            // Does the segment intersect the infinite line associated with this segment?
            bVec2 b = s - p1;
            float a = bDot(b, n);

            if (0.0f <= a && a <= maxLambda * denom) {
                float mu2 = -r.x * b.y + r.y * b.x;

                // Does the segment intersect this segment?
                if (-k_slop * denom <= mu2 && mu2 <= denom * (1.0f + k_slop)) {
                    a /= denom;
                    n.normalize();
                    lambda = a;
                    normal = n;
                    return true;
                }
            }
        }

        return false;
    }
}

