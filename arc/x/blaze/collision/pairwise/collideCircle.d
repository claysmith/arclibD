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
module arc.x.blaze.collision.pairwise.collideCircle;

import arc.x.blaze.collision.collision;
import arc.x.blaze.collision.shapes.circle;
import arc.x.blaze.collision.shapes.polygon;
import arc.x.blaze.collision.shapes.fluidParticle;
import arc.x.blaze.common.math;

void collideCircles(inout Manifold manifold, Circle circle1, Circle circle2) {

    bXForm xf1 = circle1.rBody.xf;
    bXForm xf2 = circle2.rBody.xf;

    manifold.pointCount = 0;

    bVec2 p1 = bMul(xf1, circle1.localPosition);
    bVec2 p2 = bMul(xf2, circle2.localPosition);

    bVec2 d = p2 - p1;
    float distSqr = bDot(d, d);
    float r1 = circle1.radius;
    float r2 = circle2.radius;
    float radiusSum = r1 + r2;
    if (distSqr > radiusSum * radiusSum) {
        return;
    }

    float separation;
    if (distSqr < float.epsilon) {
        separation = -radiusSum;
        manifold.normal.set(0.0f, 1.0f);
    } else {
        float dist = sqrt(distSqr);
        separation = dist - radiusSum;
        float a = 1.0f / dist;
        manifold.normal.x = a * d.x;
        manifold.normal.y = a * d.y;
    }

    manifold.pointCount = 1;
    manifold.points[0].id.key = 0;
    manifold.points[0].separation = separation;

    p1 += r1 * manifold.normal;
    p2 -= r2 * manifold.normal;

    bVec2 p = 0.5f * (p1 + p2);

    manifold.points[0].localPoint1 = bMulT(xf1, p);
    manifold.points[0].localPoint2 = bMulT(xf2, p);
}

void collidePolygonCircle(inout Manifold manifold, Polygon polygon, Circle circle) {

    bXForm xf1 = polygon.rBody.xf;
    bXForm xf2 = circle.rBody.xf;

    manifold.pointCount = 0;

    // Compute circle position in the frame of the polygon.
    bVec2 c = bMul(xf2, circle.localPosition);
    bVec2 cLocal = bMulT(xf1, c);

    // Find the min separating edge.
    int normalIndex = 0;
    float separation = -float.max;
    float radius = circle.radius;
    int vertexCount = polygon.vertices.length;
    bVec2[] vertices = polygon.vertices;
    bVec2[] normals = polygon.normals;

    for (int i = 0; i < vertexCount; ++i) {
        float s = bDot(normals[i], cLocal - vertices[i]);

        if (s > radius) {
            // Early out.
            return;
        }

        if (s > separation) {
            separation = s;
            normalIndex = i;
        }
    }

    // If the center is inside the polygon ...
    if (separation < float.epsilon) {
        manifold.pointCount = 1;
        manifold.normal = bMul(xf1.R, normals[normalIndex]);
        manifold.points[0].id.features.incidentEdge = cast(ubyte) normalIndex;
        manifold.points[0].id.features.incidentVertex = ubyte.max;
        manifold.points[0].id.features.referenceEdge = 0;
        manifold.points[0].id.features.flip = 0;
        bVec2 position = c - radius * manifold.normal;
        manifold.points[0].localPoint1 = bMulT(xf1, position);
        manifold.points[0].localPoint2 = bMulT(xf2, position);
        manifold.points[0].separation = separation - radius;
        return;
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
        manifold.points[0].id.features.incidentEdge = ubyte.max;
        manifold.points[0].id.features.incidentVertex = cast(ubyte) vertIndex1;
    } else if (u >= length) {
        p = vertices[vertIndex2];
        manifold.points[0].id.features.incidentEdge = ubyte.max;
        manifold.points[0].id.features.incidentVertex = cast(ubyte) vertIndex2;
    } else {
        p = vertices[vertIndex1] + u * e;
        manifold.points[0].id.features.incidentEdge = cast(ubyte) normalIndex;
        manifold.points[0].id.features.incidentVertex = ubyte.max;
    }

    bVec2 d = cLocal - p;
    float dist = d.normalize;
    if (dist > radius) {
        return;
    }

    manifold.pointCount = 1;
    manifold.normal = bMul(xf1.R, d);
    bVec2 position = c - radius * manifold.normal;
    manifold.points[0].localPoint1 = bMulT(xf1, position);
    manifold.points[0].localPoint2 = bMulT(xf2, position);
    manifold.points[0].separation = dist - radius;
    manifold.points[0].id.features.referenceEdge = 0;
    manifold.points[0].id.features.flip = 0;
}

bool collideCircleFluid(Circle circle, FluidParticle particle, inout bVec2 penetration, inout bVec2 penetrationNormal) {

    bXForm xf1 = circle.rBody.xf;

    bVec2 p1 = bMul(xf1, circle.localPosition);
    bVec2 p2 = particle.position;
    bVec2 normal;

    bVec2 d = p2 - p1;
    float distSqr = bDot(d, d);
    float r1 = circle.radius;
    float r2 = 0.0f;
    float radiusSum = r1 + r2;
    if (distSqr > radiusSum * radiusSum) {
        return false;
    }

    float separation;
    if (distSqr < float.epsilon) {
        separation = -radiusSum;
        normal.set(0.0f, 1.0f);
    } else {
        float dist = sqrt(distSqr);
        separation = dist - radiusSum;
        float a = 1.0f / dist;
        normal.x = a * d.x;
        normal.y = a * d.y;
    }

    penetration = normal * separation;
    penetrationNormal = normal;
    return true;
}
