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
module arc.x.blaze.collision.shapes.shape;

import arc.x.blaze.common.math;
import arc.x.blaze.dynamics.Body;
import arc.x.blaze.dynamics.joints.joint;
import arc.x.blaze.collision.collision;
import arc.x.blaze.collision.shapes.polygon;
import arc.x.blaze.collision.shapes.circle;
import arc.x.blaze.collision.shapes.fluidParticle;
import arc.x.blaze.collision.shapes.shapeType;
import arc.x.blaze.collision.nbody.broadPhase;

/// This holds the mass data computed for a shape.
struct MassData {
    /// The mass of the shape, usually in kilograms.
    float mass;

    /// The position of the shape's centroid relative to the shape's origin.
    bVec2 center;

    /// The rotational inertia of the shape.
    float I;
}

/// This holds contact filtering data.
struct FilterData {
    /// The collision category bits. Normally you would just set one bit.
    uint categoryBits;

    /// The collision mask bits. This states the categories that this
    /// shape would accept for collision.
    uint maskBits;

    /// Collision groups allow a certain group of objects to never collide (negative)
    /// or always collide (positive). Zero means no collision group. Non-zero group
    /// filtering always wins against the mask bits.
    uint groupIndex;
}

/** Return codes from TestSegment */
enum SegmentCollide {
    STARTS_INSIDE = -1,
    MISS = 0,
    HIT = 1
}

/** A shape definition is used to construct a shape. This class defines an
 * abstract shape definition. You can reuse shape definitions safely.
 */
class ShapeDef {
    /** The constructor sets the default shape definition values. */
    this () {
        type = ShapeType.UNKNOWN;
        userData = null;
        friction = 1.0f;
        restitution = 0.0f;
        density = 0.0f;
        filter.categoryBits = 0x0001;
        filter.maskBits = 0xFFFF;
        filter.groupIndex = 0;
        isSensor = false;
    }

    /** The Body this shape belongs to */
    Body rBody;

    /** Holds the shape type for down-casting. */
    ShapeType type;

    /** Use this to store application specify shape data. */
    Object userData;

    /** The shape's friction coefficient, usually in the range [0,1]. */
    float friction;

    /** The shape's restitution (elasticity) usually in the range [0,1]. */
    float restitution;

    /** The shape's density, usually in kg/m^2. */
    float density;

    /**
     * A sensor shape collects contact information but never generates a collision
     * response.
     */
    bool isSensor;

    /** Contact filtering data. */
    FilterData filter;

    void setAsBox(float hx, float hy) {
    }
}

/** A shape is used for collision detection. Shapes are created in World.
 * You can use shape for collision detection before they are attached to the world.
 * @warning you cannot reuse shapes.
 */
class Shape {

    /** Get the maximum radius about the parent body's center of mass. */
    float sweepRadius() {
        return m_sweepRadius;
    }

    /**
     * Get the type of this shape. You can use this to down cast to the concrete shape.
     * @return the shape type.
     */
    ShapeType type() {
        return m_type;
    }

    /**
     * Get the shape's triangle list. Vertices are in world coordinates
     * @return the triangle list.
     */
    bTri2[] triangleList() {
        return m_triangleList;
    }

    /**
     * Is this shape a sensor (non-solid)?
     * @return the true if the shape is a sensor.
     */
    bool isSensor() {
        return m_isSensor;
    }

	/** AABB y upper bound */
	float ymax() {
		return m_aabb.upperBound.y;
	}

	/** AABB y lower bound */
	float ymin() {
		return m_aabb.lowerBound.y;
	}

	/** AABB x maximum bound */
	float xmax() {
		return m_aabb.upperBound.x;
	}

	/** AABB x minimum bound */
	float xmin() {
		return m_aabb.lowerBound.x;
	}

    /** /Shape definition Constructor */
    this (ShapeDef def) {
        userData = def.userData;
        friction = def.friction;
        restitution = def.restitution;
        m_density = def.density;
        rBody = def.rBody;
        m_sweepRadius = 0.0f;
        next = null;
        filter = def.filter;
        m_isSensor = def.isSensor;
    }

    /** Generic constructor (Used by FluidParticles) */
    this() {}

    bool synchronize(bXForm transform1, bXForm transform2) {

        // Compute an AABB that covers the swept shape (may miss some rotation effect).
        computeSweptAABB(transform1, transform2);

        return false;

    }

    void refilterProxy(BroadPhase broadPhase, bXForm transform) {
        /*
        if (m_proxyId == k_nullProxy) {
            return;
        }

        broadPhase.destroyProxy(m_proxyId);

        b2AABB aabb;
        computeAABB(aabb, transform);

        bool inRange = broadPhase.inRange(aabb);

        if (inRange) {
            m_proxyId = broadPhase->CreateProxy(aabb, this);
        } else {
            m_proxyId = b2_nullProxy;
        }
        */
    }

    /**
     * Test a point for containment in this shape. This only works for convex shapes.
     * @param xf the shape world transform.
     * @param p a point in world coordinates.
     */
    abstract bool testPoint(bXForm xf, bVec2 p);

    /**
     * Perform a ray cast against this shape.
     * @param xf the shape world transform.
     * @param lambda returns the hit fraction. You can use this to compute the contact point
     * p = (1 - lambda) * segment.p1 + lambda * segment.p2.
     * @param normal returns the normal at the contact point. If there is no intersection, the normal
     * is not set.
     * @param segment defines the begin and end point of the ray cast.
     * @param maxLambda a number typically in the range [0,1].
     */
    abstract SegmentCollide testSegment(bXForm xf, inout float lambda, inout bVec2 normal, Segment segment, float maxLambda);

    /// Given a transform, compute the associated axis aligned bounding box for this shape.
    /// @param aabb returns the axis aligned box.
    /// @param xf the world transform of the shape.
    abstract void computeAABB(inout AABB aabb, bXForm xf);
    abstract void updateAABB();
    abstract AABB aabb();
    abstract void updateSweepRadius(bVec2 center);

    /// Given two transforms, compute the associated swept axis aligned bounding box for this shape.
    /// @param aabb returns the axis aligned box.
    /// @param xf1 the starting shape world transform.
    /// @param xf2 the ending shape world transform.
    abstract void computeSweptAABB(bXForm xf1, bXForm xf2);

    /// Compute the mass properties of this shape using its dimensions and density.
    /// The inertia tensor is computed about the local origin, not the centroid.
    /// @param massData returns the mass data for this shape.
    abstract void computeMass(inout MassData massData);

    /**
	* Triangulate the shape.
	* Currently this is only used by the buoyancy solver.
	*/
	void triangulate() {
		assert(0);
	}

	/**
	* The shape's world center
	*/
	abstract bVec2 worldCenter();
    
    /**
	* The shape's support point (for MPR & GJK)
	*/
    abstract bVec2 support(bXForm xf, bVec2 d);

    static Shape create(ShapeDef def) {
        switch (def.type) {
        case ShapeType.CIRCLE: {
            return new Circle(def);
        }
        case ShapeType.POLYGON: {
            return new Polygon(def);
        }
        default:
            throw new Exception ("Unknown shape type!");
        }
    }

	float area;
    float friction;
    float restitution;
    Shape next;
    Object userData;
    // The body this shape is attached to
    Body rBody;
    FilterData filter;
    ushort ID;

protected:

    ShapeType m_type;
    // Axis aligned bounding box
    AABB m_aabb;
    // Sweep radius relative to the parent body's center of mass.
    float m_sweepRadius;
    float m_density;
    bool m_isSensor;
    bTri2[] m_triangleList;
}
