/*
 *  Copyright (c) 2008 Rene Schulte. http://www.rene-schulte.info/
 *  Ported to D by Mason Green. http:/www.dsource.org/projects/blaze
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
module arc.x.blaze.collision.shapes.fluidParticle;

import arc.x.blaze.common.math;
import arc.x.blaze.common.constants;
import arc.x.blaze.dynamics.Body;
import arc.x.blaze.world;
import arc.x.blaze.collision.shapes.shape;
import arc.x.blaze.collision.shapes.shapeType;
import arc.x.blaze.collision.collision;

/**
 * A fluid particle
 */
public class FluidParticle : Shape {

    public bVec2 velocity;
    public bVec2 position;
    public bVec2 positionOld;
    public float mass;
    public float massInv;
    public float density;
    public bVec2 force;
    public float pressure;
    public int[] neighbors;
    private float gridSize;
    public static float margin;

    /**
     * Constructor
     */
    this(bVec2 position, float restitution, float friction) {
        super.m_type = ShapeType.FLUID;
        super.restitution = restitution;
        super.friction = friction;
        this.setMass(1.25);
        this.gridSize = CELL_SPACE * 1.25f;
        this.margin = 0.01f;
        this.position = position;
        this.positionOld = position;
        this.density = DENSITY_OFFSET;
        updatePressure();
    }

    /**
     * Updates the pressure using a modified ideal gas state equation
     * (see the paper "Smoothed particles: A new paradigm for animating highly deformable bodies." by Desbrun)
     */
    public void updatePressure() {
        pressure = GAS_CONSTANT * (density - DENSITY_OFFSET);
    }

    /**
     * Updates the particle.
     */
    public void update(TimeStep step, bVec2 gravity) {

        bVec2 acceleration = force * massInv;
        acceleration += gravity;

        // Vertlet integration
        bVec2 t;
        float damping = 0.01f;
        bVec2 oldPos = position;
        // Position = Position + (1.0f - Damping) * (Position - PositionOld) + dt * dt * a;
        acceleration *= (step.dt * step.dt);
        t = position - positionOld;
        t *= (1.0f - damping);
        t += acceleration;
        position += t;
        positionOld = oldPos;

        // calculate velocity
        // Velocity = (Position - PositionOld) / dt;
        t = position - positionOld;
        velocity = t * 1.0 * step.inv_dt;
    }

    /** Returns the axis aligned bounding box associated with the shape, in
     * reference to the parent body's transform
     */
    AABB aabb() {
        return m_aabb;
    }

    /** Update the AABB */
    void updateAABB() {
        m_aabb.lowerBound.x = position.x - gridSize;
        m_aabb.lowerBound.y = position.y - gridSize;
        m_aabb.upperBound.x = position.x + gridSize;
        m_aabb.upperBound.y = position.y + gridSize;
    }

	/** The particles position in world coordinates */
	bVec2 worldCenter() {
		return position;
	}

    public void setMass(float mass) {
        this.mass = mass;
        massInv = mass > 0.0f ? 1.0f / mass : 0.0f;
    }

    public void addNeighbor(uint ID) {
        neighbors ~= ID;
    }

    public void addForce(bVec2 force) {
        this.force += force;
    }

    bool containsPoint(bVec2 v) {
        return false;
    }

    float calculateInertia(float m, bVec2 offset) {
        return 0.0f;
    }

    void applyImpulse(bVec2 penetration, bVec2 penetrationNormal, float rest, float fric) {

        // Move this method to FluidParticle

        // Handle collision
        // Calc new velocity using elastic collision with friction
        // -> Split oldVelocity in normal and tangential component, revert normal component and add it afterwards
        // v = pos - oldPos;
        //vn = n * Vector2.Dot(v, n) * -Bounciness;
        //vt = t * Vector2.Dot(v, t) * (1.0f - Friction);
        //v = vn + vt;
        //oldPos = pos - v;

        bVec2 v, vn, vt;

        v = position - positionOld;
        bVec2 tangent = penetrationNormal.rotateRight90;
        float dp = v.bDot(penetrationNormal);
        vn = penetrationNormal * dp * -rest;
        dp = v.bDot(tangent);
        vt = tangent * dp * (1.0f - fric);
        v = vn + vt;
        position -= penetration;
        positionOld = position - v;
    }

    void computeSweptAABB(bXForm xf1, bXForm xf2) {
        updateAABB();
    }

	void triangulate() {}
    void updateSweepRadius(bVec2 center) {}
    void computeMass(inout MassData massData) {}
    void computeAABB(inout AABB aabb, bXForm xf) {}
    SegmentCollide testSegment(bXForm xf, inout float lambda, inout bVec2 normal,
                               Segment segment, float maxLambda) { return SegmentCollide.MISS; }
    bool testPoint(bXForm xf, bVec2 p) { return false; }
    bVec2 support(bXForm xf, bVec2 d) { return bVec2(0,0); }
}

