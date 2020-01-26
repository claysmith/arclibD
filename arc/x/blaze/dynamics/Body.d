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
module arc.x.blaze.dynamics.Body;

import arc.x.blaze.world;
import arc.x.blaze.common.math;
import arc.x.blaze.common.constants;
import arc.x.blaze.collision.shapes.shape;
import arc.x.blaze.collision.shapes.fluidParticle;
import arc.x.blaze.dynamics.bodyDef;
import arc.x.blaze.dynamics.joints.joint;
import arc.x.blaze.dynamics.contact.contact;

/// A rigid body.
class Body {

    /** The body's origin transform */
    bXForm xf;
    /** The body's linear velocity */
    bVec2 linearVelocity;
    /** the body's angular velocity */
    float angularVelocity;
    /** The force exerted on this body */
    bVec2 force;
    /** The torque exerted on this body */
    float torque;
    /** Is this body static (immovable)? */
    bool isStatic;
    /** Next body in the world linked body list */
    Body prev;
    /** Previous body in the world linked body list */
    Body next;

    /// Linear damping is use to reduce the linear velocity. The damping parameter
	/// can be larger than 1.0f but the damping effect becomes sensitive to the
	/// time step when the damping parameter is large.
    float linearDamping;

    /// Angular damping is use to reduce the angular velocity. The damping parameter
	/// can be larger than 1.0f but the damping effect becomes sensitive to the
	/// time step when the damping parameter is large.
    float angularDamping;

    Object userData;

    /// Creates a shape and attach it to this body.
    /// @param shapeDef the shape definition.
    /// @warning This function is locked during callbacks.
    Shape createShape(ShapeDef def) {

        assert(!m_world.lock);
        if (m_world.lock) {
            return null;
        }

        Shape s = Shape.create(def);
        s.next = m_shapeList;
        m_shapeList = s;
        ++m_shapeCount;

        s.rBody = this;
        s.ID = m_world.broadPhase.shapes.length + 1;

        // Add the shape to the world's broad-phase.
        m_world.broadPhase.addShape(s);

        // Compute the sweep radius for CCD.
        s.updateAABB();
        s.updateSweepRadius(sweep.localCenter);

        return s;
    }

    /// Destroy a shape. This removes the shape from the broad-phase and
    /// therefore destroys any contacts associated with this shape. All shapes
    /// attached to a body are implicitly destroyed when the body is destroyed.
    /// @param shape the shape to be removed.
    /// @warning This function is locked during callbacks.
    void destroyShape(Shape s) {

        assert(!m_world.lock);
        if (m_world.lock) {
            return;
        }

        assert(s.rBody is this);
        m_world.broadPhase.removeShape(s);

        assert(m_shapeCount > 0);
        Shape node = m_shapeList;
        bool found = false;
        while (node !is null) {
            if (node is s) {
                node = s.next;
                found = true;
                break;
            }

            node = node.next;
        }

        // You tried to remove a shape that is not attached to this body.
        assert(found);

        s.rBody = null;
        s.next = null;

        --m_shapeCount;
        delete s;
    }

    /// Set the mass properties. Note that this changes the center of mass position.
    /// If you are not sure how to compute mass properties, use SetMassFromShapes.
    /// The inertia tensor is assumed to be relative to the center of mass.
    /// @param massData the mass properties.
    // TODO_ERIN adjust linear velocity and torque to account for movement of center.
    void setMass(MassData massData) {

        assert(!m_world.lock);
        if (m_world.lock) {
            return;
        }

        m_invMass = 0.0f;
        m_I = 0.0f;
        m_invI = 0.0f;

        m_mass = massData.mass;

        if (m_mass > 0.0f) {
            m_invMass = 1.0f / m_mass;
        }

        if ((flags & FIXED_ROTATION) == 0) {
            m_I = massData.I;
        }

        if (m_I > 0.0f) {
            m_invI = 1.0f / m_I;
        }

        // Move center of mass.
        sweep.localCenter = massData.center;
        sweep.c0 = sweep.c = bMul(xf, sweep.localCenter);

        // Update the sweep radii of all child shapes.
        for (Shape s = m_shapeList; s; s = s.next) {
            s.updateSweepRadius(sweep.localCenter);
        }

        bool oldType = isStatic;
        if (m_invMass == 0.0f && m_invI == 0.0f) {
            isStatic = true;
        } else {
            isStatic = false;
        }
    }

    /// Compute the mass properties from the attached shapes. You typically call this
    /// after adding all the shapes. If you add or remove shapes later, you may want
    /// to call this again. Note that this changes the center of mass position.
    // TODO_ERIN adjust linear velocity and torque to account for movement of center.
    void setMassFromShapes() {

        assert(!m_world.lock);
        if (m_world.lock) {
            return;
        }

        // Compute mass data from shapes. Each shape has its own density.
        m_mass = 0.0f;
        m_invMass = 0.0f;
        m_I = 0.0f;
        m_invI = 0.0f;

        bVec2 center;
        for (Shape s = m_shapeList; s; s = s.next) {
            MassData massData;
            s.computeMass(massData);
            m_mass += massData.mass;
            center += massData.mass * massData.center;
            m_I += massData.I;
        }

        // Compute center of mass, and shift the origin to the COM.
        if (m_mass > 0.0f) {
            m_invMass = 1.0f / m_mass;
            center *= m_invMass;
        }

        if (m_I > 0.0f && (flags & FIXED_ROTATION) == 0) {
            // Center the inertia about the center of mass.
            m_I -= m_mass * bDot(center, center);
            assert(m_I > 0.0f);
            m_invI = 1.0f / m_I;
        } else {
            m_I = 0.0f;
            m_invI = 0.0f;
        }

        // Move center of mass.
        sweep.localCenter = center;
        sweep.c0 = sweep.c = bMul(xf, sweep.localCenter);

        // Update the sweep radii of all child shapes.
        for (Shape s = m_shapeList; s; s = s.next) {
            s.updateSweepRadius(sweep.localCenter);
        }

        bool oldType = isStatic;
        if (m_invMass == 0.0f && m_invI == 0.0f) {
            isStatic = true;;
        } else {
            isStatic = false;
        }

        // If the body type changed, we need to refilter the broad-phase proxies.
        if (oldType != isStatic) {
            for (Shape s = m_shapeList; s; s = s.next) {
                //s.refilterProxy(m_world.broadPhase, xf);
            }
        }
    }

    /// Set the position of the body's origin and rotation (radians).
    /// This breaks any contacts and wakes the other bodies.
    /// @param position the new world position of the body's origin (not necessarily
    /// the center of mass).
    /// @param angle the new world rotation angle of the body in radians.
    /// @return false if the movement put a shape outside the world. In this case the
    /// body is automatically frozen.
    bool xForm(bVec2 position, float angle) {

        assert(!m_world.lock);
        if (m_world.lock) {
            return true;
        }

        if (isFrozen) {
            return false;
        }

        xf.R.set(angle);
        xf.position = position;

        sweep.c0 = sweep.c = bMul(xf, sweep.localCenter);
        sweep.a0 = sweep.a = angle;

        bool freeze = false;
        for (Shape s = m_shapeList; s; s = s.next) {
            bool inRange = s.synchronize(xf, xf);

            if (inRange == false) {
                freeze = true;
                break;
            }
        }

        if (freeze == true) {
            flags |= FROZEN;
            linearVelocity.zero();
            angularVelocity = 0.0f;
            for (Shape s = m_shapeList; s; s = s.next) {
                m_world.broadPhase.removeShape(s);
            }

            // Failure
            return false;
        }

        // Success
        //m_world.broadPhase.commit();
        return true;
    }

    /// Get the world body origin position.
    /// @return the world position of the body's origin.
    bVec2 position() {
        return xf.position;
    }

    /// Get the angle in radians.
    /// @return the current world rotation angle in radians.
    float angle() {
        return sweep.a;
    }

    /** Set the body's angle in radians */
    void angle(float a) {
        sweep.a = a;
    }

    /// Get the world position of the center of mass.
    bVec2 worldCenter() {
        return sweep.c;
    }

    /// Get the local position of the center of mass.
    bVec2 localCenter() {
        return sweep.localCenter;
    }

    /// Apply a force at a world point. If the force is not
    /// applied at the center of mass, it will generate a torque and
    /// affect the angular velocity. This wakes up the body.
    /// @param force the world force vector, usually in Newtons (N).
    /// @param point the world position of the point of application.
    void applyForce(bVec2 force, bVec2 point) {
        if (isSleeping()) {
            wakeup();
        }
        this.force += force;
        this.torque += bCross(point - sweep.c, force);
    }

    void applyBuoyancyForce(FluidParticle particle) {
        if (isSleeping()) {
            wakeup();
        }
        // Apply buoyancy force to body
        float angDrag = 0.05f;
        float linDrag = 0.5f;
        bVec2 f = particle.force * linDrag;
        bVec2 r = particle.position - position;
        this.force += f;
        this.torque += r.x * f.y * angDrag - r.y * f.x * angDrag;
    }
    /// Apply a torque. This affects the angular velocity
    /// without affecting the linear velocity of the center of mass.
    /// This wakes up the body.
    /// @param torque about the z-axis (out of the screen), usually in N-m.
    void applyTorque(float torque) {
        if (isSleeping()) {
            wakeup();
        }
        this.torque += torque;
    }

    /// Apply an impulse at a point. This immediately modifies the velocity.
    /// It also modifies the angular velocity if the point of application
    /// is not at the center of mass. This wakes up the body.
    /// @param impulse the world impulse vector, usually in N-seconds or kg-m/s.
    /// @param point the world position of the point of application.
    void applyImpulse(bVec2 impulse, bVec2 point) {
        if (isSleeping()) {
            wakeup();
        }
        linearVelocity += m_invMass * impulse;
        angularVelocity += m_invI * bCross(point - sweep.c, impulse);
    }

    /// Get the total mass of the body.
    /// @return the mass, usually in kilograms (kg).
    float mass() {
        return m_mass;
    }

    float invMass() {
        return m_invMass;
    }

    float invI() {
        return m_invI;
    }

    /// Get the central rotational inertia of the body.
    /// @return the rotational inertia, usually in kg-m^2.
    float inertia() {
        return m_I;
    }

    /// Get the world coordinates of a point given the local coordinates.
    /// @param localPoint a point on the body measured relative the the body's origin.
    /// @return the same point expressed in world coordinates.
    bVec2 worldPoint(bVec2 localPoint) {
        return bMul(xf, localPoint);
    }

    /// Get the world coordinates of a vector given the local coordinates.
    /// @param localVector a vector fixed in the body.
    /// @return the same vector expressed in world coordinates.
    bVec2 worldVector(bVec2 localVector) {
        return bMul(xf.R, localVector);
    }

    /// Gets a local point relative to the body's origin given a world point.
    /// @param a point in world coordinates.
    /// @return the corresponding local point relative to the body's origin.
    bVec2 localPoint(bVec2 worldPoint) {
        return bMulT(xf, worldPoint);
    }

    /// Gets a local vector given a world vector.
    /// @param a vector in world coordinates.
    /// @return the corresponding local vector.
    bVec2 localVector(bVec2 worldVector) {
        return bMulT(xf.R, worldVector);
    }

    /// Get the world linear velocity of a world point attached to this body.
    /// @param a point in world coordinates.
    /// @return the world velocity of a point.
    bVec2 linearVelocityFromWorldPoint(bVec2 worldPoint) {
        return linearVelocity + bCross(angularVelocity, worldPoint - sweep.c);
    }

    /// Get the world velocity of a local point.
    /// @param a point in local coordinates.
    /// @return the world velocity of a point.
    bVec2 linearVelocityFromLocalPoint(bVec2 localPoint) {
        return linearVelocityFromWorldPoint(worldPoint(localPoint));
    }

    /// Is this body treated like a bullet for continuous collision detection?
    int bullet() {
        return (flags & BULLET);
    }

    /// Should this body be treated like a bullet for continuous collision detection?
    void bullet(bool flag) {
        if (flag) {
            flags |= BULLET;
        } else {
            flags &= ~BULLET;
        }
    }

    /// Is this body frozen?
    int isFrozen() {
        return (flags & FROZEN);
    }

    /// Is this body sleeping (not simulating).
    int isSleeping() {
        return (flags & SLEEP);
    }

    /// You can disable sleeping on this body.
    void allowSleeping(bool flag) {
        if (flag) {
            flags |= ALLOW_SLEEP;
        } else {
            flags &= ~ALLOW_SLEEP;
            wakeup();
        }
    }

    /// Wake up this body so it will begin simulating.
    void wakeup() {
        flags &= ~SLEEP;
        m_sleepTime = 0.0f;
    }

    /// Put this body to sleep so it will stop simulating.
    /// This also sets the velocity to zero.
    void putToSleep() {
        flags |= SLEEP;
        m_sleepTime = 0.0f;
        linearVelocity.zero();
        angularVelocity = 0.0f;
        force.zero();
        torque = 0.0f;
    }

    /// Get the list of all shapes attached to this body.
    Shape shapeList() {
        return m_shapeList;
    }

    /** Get the number of shapes attached to this body */
    int shapeCount() {
        return m_shapeCount;
    }

    /// Get the parent world of this body.
    World world() {
        return m_world;
    }

    //--------------- Internals Below -------------------

    // The swept motion for CCD
    bSweep sweep;

    // flags
    static const FROZEN		    = 0x0002;
    static const ISLAND		    = 0x0004;
    static const SLEEP			= 0x0008;
    static const ALLOW_SLEEP	= 0x0010;
    static const BULLET		    = 0x0020;
    static const FIXED_ROTATION	= 0x0040;

    ushort flags;

    /** Constructor */
    this (BodyDef bd, World world) {

        assert(!world.lock);

        m_world = world;

        flags = 0;

        if (bd.isBullet) {
            flags |= BULLET;
        }
        if (bd.fixedRotation) {
            flags |= FIXED_ROTATION;
        }
        if (bd.allowSleep) {
            flags |= ALLOW_SLEEP;
        }
        if (bd.isSleeping) {
            flags |= SLEEP;
        }

        xf.position = bd.position;
        xf.R.set(bd.angle);

        sweep.localCenter = bd.massData.center;
        sweep.t0 = 1.0f;
        sweep.a0 = sweep.a = bd.angle;
        sweep.c0 = sweep.c = bMul(xf, sweep.localCenter);

        prev = null;
        next = null;
        jointList = null;
        contactList = null;

        linearDamping = bd.linearDamping;
        angularDamping = bd.angularDamping;

        force.zero();
        torque = 0.0f;

        linearVelocity.zero();
        angularVelocity = 0.0f;

        m_sleepTime = 0.0f;

        m_invMass = 0.0f;
        m_I = 0.0f;
        m_invI = 0.0f;

        m_mass = bd.massData.mass;

        if (m_mass > 0.0f) {
            m_invMass = 1.0f / m_mass;
        }

        if ((flags & FIXED_ROTATION) == 0) {
            m_I = bd.massData.I;
        }

        if (m_I > 0.0f) {
            m_invI = 1.0f / m_I;
        }

        if (m_invMass == 0.0f && m_invI == 0.0f) {
            isStatic = true;
        } else {
            isStatic = false;
        }

        userData = bd.userData;

        m_shapeList = null;
        m_shapeCount = 0;
    }

    bool synchronizeShapes() {
        bXForm xf1;
        xf1.R.set(sweep.a0);
        xf1.position = sweep.c0 - bMul(xf1.R, sweep.localCenter);

        for (Shape s = m_shapeList; s; s = s.next) {
            s.synchronize(xf1, xf);
        }
        // Success
        return true;
    }

    /** Update rotation and position */
    void synchronizeTransform() {
        xf.R.set(sweep.a);
        xf.position = sweep.c - bMul(xf.R, sweep.localCenter);
    }

    // This is used to prevent connected bodies from colliding.
    // It may lie, depending on the collideConnected flag.
    bool isConnected(Body other) {
        for (JointEdge jn = jointList; jn; jn = jn.next) {
            if (jn.other == other)
                return jn.joint.collideConnected == false;
        }

        return false;
    }

    void advance(float t) {
        // Advance to the new safe time.
        sweep.advance(t);
        sweep.c = sweep.c0;
        sweep.a = sweep.a0;
        synchronizeTransform();
    }

    int islandIndex() {
        return m_islandIndex;
    }

    void islandIndex(int i) {
        m_islandIndex = i;
    }

    float sleepTime() {
        return m_sleepTime;
    }

    void sleepTime(float time) {
        m_sleepTime = time;
    }

    JointEdge jointList;
    ContactEdge contactList;

private:
    World m_world;
    float m_sleepTime;
    float m_mass, m_invMass;
    float m_I, m_invI;
    Shape m_shapeList;
    int m_shapeCount;
    int m_islandIndex;
}
