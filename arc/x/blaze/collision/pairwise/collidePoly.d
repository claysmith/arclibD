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

module arc.x.blaze.collision.pairwise.collidePoly;

import arc.x.blaze.collision.collision;
import arc.x.blaze.collision.shapes.polygon;
import arc.x.blaze.collision.shapes.fluidParticle;
import arc.x.blaze.common.math;
import arc.x.blaze.common.constants;


struct ClipVertex {
    bVec2 v;
    ContactID id;
}

static int clipSegmentToLine(ClipVertex vOut[2], ClipVertex vIn[2], bVec2 normal, float offset) {
    // Start with no output points
    int numOut = 0;
    // Calculate the distance of end points to the line
    float distance0 = bDot(normal, vIn[0].v) - offset;
    float distance1 = bDot(normal, vIn[1].v) - offset;

    // If the points are behind the plane
    if (distance0 <= 0.0f) vOut[numOut++] = vIn[0];
    if (distance1 <= 0.0f) vOut[numOut++] = vIn[1];

    // If the points are on different sides of the plane
    if (distance0 * distance1 < 0.0f) {
        // Find intersection point of edge and plane
        float interp = distance0 / (distance0 - distance1);
        vOut[numOut].v = vIn[0].v + interp * (vIn[1].v - vIn[0].v);
        if (distance0 > 0.0f) {
            vOut[numOut].id = vIn[0].id;
        } else {
            vOut[numOut].id = vIn[1].id;
        }
        ++numOut;
    }

    return numOut;
}

// Find the separation between poly1 and poly2 for a give edge normal on poly1.
static float edgeSeparation(Polygon poly1, bXForm xf1, int edge1, Polygon poly2, bXForm xf2) {

    int count1 = poly1.vertices.length;
    bVec2[] vertices1 = poly1.vertices.dup;
    bVec2[] normals1 = poly1.normals.dup;
    int count2 = poly2.vertices.length;
    bVec2[] vertices2 = poly2.vertices.dup;

    assert(0 <= edge1 && edge1 < count1);

    // Convert normal from poly1's frame into poly2's frame.
    bVec2 normal1World = bMul(xf1.R, normals1[edge1]);
    bVec2 normal1 = bMulT(xf2.R, normal1World);

    // Find support vertex on poly2 for -normal.
    int index = 0;
    float minDot = float.max;

    for (int i = 0; i < count2; ++i) {
        float bDot = bDot(vertices2[i], normal1);
        if (bDot < minDot) {
            minDot = bDot;
            index = i;
        }
    }

    bVec2 v1 = bMul(xf1, vertices1[edge1]);
    bVec2 v2 = bMul(xf2, vertices2[index]);
    float separation = bDot(v2 - v1, normal1World);
    return separation;
}

// Find the max separation between poly1 and poly2 using edge normals from poly1.
static float findMaxSeparation(inout int edgeIndex, Polygon poly1, bXForm xf1, Polygon poly2, bXForm xf2) {

    int count1 = poly1.vertices.length;
    bVec2[] normals1 = poly1.normals.dup;

    // Vector pointing from the centroid of poly1 to the centroid of poly2.
    bVec2 d = bMul(xf2, poly2.centroid) - bMul(xf1, poly1.centroid);
    bVec2 dLocal1 = bMulT(xf1.R, d);

    // Find edge normal on poly1 that has the largest projection onto d.
    int edge = 0;
    float maxDot = -float.max;
    for (int i = 0; i < count1; ++i) {
        float bDot = bDot(normals1[i], dLocal1);
        if (bDot > maxDot) {
            maxDot = bDot;
            edge = i;
        }
    }

    // Get the separation for the edge normal.
    float s = edgeSeparation(poly1, xf1, edge, poly2, xf2);
    if (s > 0.0f) {
        return s;
    }

    // Check the separation for the previous edge normal.
    int prevEdge = edge - 1 >= 0 ? edge - 1 : count1 - 1;
    float sPrev = edgeSeparation(poly1, xf1, prevEdge, poly2, xf2);
    if (sPrev > 0.0f) {
        return sPrev;
    }

    // Check the separation for the next edge normal.
    int nextEdge = edge + 1 < count1 ? edge + 1 : 0;
    float sNext = edgeSeparation(poly1, xf1, nextEdge, poly2, xf2);
    if (sNext > 0.0f) {
        return sNext;
    }

    // Find the best edge and the search direction.
    int bestEdge;
    float bestSeparation;
    int increment;
    if (sPrev > s && sPrev > sNext) {
        increment = -1;
        bestEdge = prevEdge;
        bestSeparation = sPrev;
    } else if (sNext > s) {
        increment = 1;
        bestEdge = nextEdge;
        bestSeparation = sNext;
    } else {
        edgeIndex = edge;
        return s;
    }

    // Perform a local search for the best edge normal.
    for ( ; ; ) {
        if (increment == -1)
            edge = bestEdge - 1 >= 0 ? bestEdge - 1 : count1 - 1;
        else
            edge = bestEdge + 1 < count1 ? bestEdge + 1 : 0;

        s = edgeSeparation(poly1, xf1, edge, poly2, xf2);
        if (s > 0.0f) {
            return s;
        }

        if (s > bestSeparation) {
            bestEdge = edge;
            bestSeparation = s;
        } else {
            break;
        }
    }

    edgeIndex = bestEdge;
    return bestSeparation;
}

static void findIncidentEdge(ClipVertex c[2], Polygon poly1, bXForm xf1, int edge1, Polygon poly2, bXForm xf2) {
    int count1 = poly1.vertices.length;
    bVec2[] normals1 = poly1.normals;

    int count2 = poly2.vertices.length;
    bVec2[] vertices2 = poly2.vertices;
    bVec2[] normals2 = poly2.normals;

    assert(0 <= edge1 && edge1 < count1);

    // Get the normal of the reference edge in poly2's frame.
    bVec2 normal1 = bMulT(xf2.R, bMul(xf1.R, normals1[edge1]));

    // Find the incident edge on poly2.
    int index = 0;
    float minDot = float.max;
    for (int i = 0; i < count2; ++i) {
        float bDot = bDot(normal1, normals2[i]);
        if (bDot < minDot) {
            minDot = bDot;
            index = i;
        }
    }

    // Build the clip vertices for the incident edge.
    int i1 = index;
    int i2 = i1 + 1 < count2 ? i1 + 1 : 0;

    c[0].v = bMul(xf2, vertices2[i1]);
    c[0].id.features.referenceEdge = cast(ubyte) edge1;
    c[0].id.features.incidentEdge = cast(ubyte) i1;
    c[0].id.features.incidentVertex = 0;

    c[1].v = bMul(xf2, vertices2[i2]);
    c[1].id.features.referenceEdge = cast(ubyte) edge1;
    c[1].id.features.incidentEdge = cast(ubyte) i2;
    c[1].id.features.incidentVertex = 1;
}

// Find edge normal of max separation on A - return if separating axis is found
// Find edge normal of max separation on B - return if separation axis is found
// Choose reference edge as min(minA, minB)
// Find incident edge
// Clip

// The normal points from 1 to 2
void collidePolygons(inout Manifold manifold, Polygon polyA, Polygon polyB) {

    bXForm xfA = polyA.rBody.xf;
    bXForm xfB = polyB.rBody.xf;

    manifold.pointCount = 0;

    int edgeA = 0;
    float separationA = findMaxSeparation(edgeA, polyA, xfA, polyB, xfB);
    if (separationA > 0.0f) {
        return;
    }

    int edgeB = 0;
    float separationB = findMaxSeparation(edgeB, polyB, xfB, polyA, xfA);
    if (separationB > 0.0f) {
        return;
    }

    Polygon poly1;	// reference poly
    Polygon poly2;	// incident poly
    bXForm xf1, xf2;
    int edge1;		// reference edge
    ubyte flip;
    const float k_relativeTol = 0.98f;
    const float k_absoluteTol = 0.001f;

    // TODO_ERIN use "radius" of poly for absolute tolerance.
    if (separationB > k_relativeTol * separationA + k_absoluteTol) {
        poly1 = polyB;
        poly2 = polyA;
        xf1 = xfB;
        xf2 = xfA;
        edge1 = edgeB;
        flip = 1;
    } else {
        poly1 = polyA;
        poly2 = polyB;
        xf1 = xfA;
        xf2 = xfB;
        edge1 = edgeA;
        flip = 0;
    }

    ClipVertex incidentEdge[2];
    findIncidentEdge(incidentEdge, poly1, xf1, edge1, poly2, xf2);

    int count1 = poly1.vertices.length;
    bVec2[] vertices1 = poly1.vertices;

    bVec2 v11 = vertices1[edge1];
    bVec2 v12 = edge1 + 1 < count1 ? vertices1[edge1+1] : vertices1[0];

    bVec2 dv = v12 - v11;
    bVec2 sideNormal = bMul(xf1.R, v12 - v11);
    sideNormal.normalize();
    bVec2 frontNormal = bCross(sideNormal, 1.0f);

    v11 = bMul(xf1, v11);
    v12 = bMul(xf1, v12);

    float frontOffset = bDot(frontNormal, v11);
    float sideOffset1 = -bDot(sideNormal, v11);
    float sideOffset2 = bDot(sideNormal, v12);

    // Clip incident edge against extruded edge1 side edges.
    ClipVertex clipPoints1[2];
    ClipVertex clipPoints2[2];
    int np;

    // Clip to box side 1
    np = clipSegmentToLine(clipPoints1, incidentEdge, -sideNormal, sideOffset1);

    if (np < 2) {
        return;
    }

    // Clip to negative box side 1
    np = clipSegmentToLine(clipPoints2, clipPoints1,  sideNormal, sideOffset2);

    if (np < 2) {
        return;
    }

    // Now clipPoints2 contains the clipped points.
    manifold.normal = flip ? -frontNormal : frontNormal;

    int pointCount = 0;
    for (int i = 0; i < k_maxManifoldPoints; ++i) {
        float separation = bDot(frontNormal, clipPoints2[i].v) - frontOffset;
        if (separation <= 0.0f) {
            ManifoldPoint* cp = &manifold.points[pointCount];
            cp.separation = separation;
            cp.localPoint1 = bMulT(xfA, clipPoints2[i].v);
            cp.localPoint2 = bMulT(xfB, clipPoints2[i].v);
            cp.id = clipPoints2[i].id;
            cp.id.features.flip = flip;
            pointCount++;
        }
    }

    manifold.pointCount = pointCount;
}

// To Do
bool collidePolyFluid(Polygon polygon, FluidParticle particle, inout bVec2 penetration, inout bVec2 penetrationNormal) {

    bXForm xf1 = polygon.rBody.xf;
    bXForm xf2;
    xf2.position = particle.position;

    // Compute circle position in the frame of the polygon.
    bVec2 c = bMul(xf2, bVec2.zeroVect);
    bVec2 cLocal = bMulT(xf1, c);

    // Find the min separating edge.
    int normalIndex = 0;
    float separation = -float.max;
    float radius = particle.margin;
    int vertexCount = polygon.vertices.length;
    bVec2[] vertices = polygon.vertices;
    bVec2[] normals = polygon.normals;

    for (int i = 0; i < vertexCount; ++i) {
        float s = bDot(normals[i], cLocal - vertices[i]);

        if (s > radius) {
            // Early out.
            return false;
        }

        if (s > separation) {
            separation = s;
            normalIndex = i;
        }
    }

    // If the center is inside the polygon ...
    if (separation < float.epsilon) {
        penetrationNormal = bMul(xf1.R, normals[normalIndex]);
        separation = separation - radius;
        penetration = penetrationNormal * separation;
        return true;
    }

    // Project the circle center onto the edge segment.
    int vertIndex1 = normalIndex;
    int vertIndex2 = vertIndex1 + 1 < vertexCount ? vertIndex1 + 1 : 0;
    bVec2 e = vertices[vertIndex2] - vertices[vertIndex1];

    float length = e.normalize;
    assert(length > float.epsilon);

    // Project the center onto the edge.
    float u = bDot(cLocal - vertices[vertIndex1], e);
    bVec2 p;
    if (u <= 0.0f) {
        p = vertices[vertIndex1];
    } else if (u >= length) {
        p = vertices[vertIndex2];
    } else {
        p = vertices[vertIndex1] + u * e;
    }

    bVec2 d = cLocal - p;
    float dist = d.normalize;
    if (dist > radius) {
        return false;
    }

    penetrationNormal = bMul(xf1.R, d);
    separation = dist - radius;
    penetration = penetrationNormal * separation;
    return true;
}
