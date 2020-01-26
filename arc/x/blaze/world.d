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
module arc.x.blaze.world;

import arc.x.blaze.common.math;
import arc.x.blaze.dynamics.island;
import arc.x.blaze.dynamics.Body;
import arc.x.blaze.dynamics.bodyDef;
import arc.x.blaze.dynamics.contact.contact;
import arc.x.blaze.dynamics.contact.contactManager;
import arc.x.blaze.dynamics.forces.forceGenerator;
import arc.x.blaze.dynamics.forces.forceRegistry;
import arc.x.blaze.dynamics.forces.buoyancy;
import arc.x.blaze.dynamics.joints.joint;
import arc.x.blaze.dynamics.worldCallbacks;
import arc.x.blaze.collision.shapes.shape;
import arc.x.blaze.collision.shapes.shapeType;
import arc.x.blaze.collision.nbody.broadPhase;
import arc.x.blaze.collision.nbody.sortAndSweep;
import arc.x.blaze.collision.nbody.bruteForce;
import arc.x.blaze.collision.pairwise.timeOfImpact;
import arc.x.blaze.collision.collision;
import arc.x.blaze.dynamics.fluid.SPHSimulation;
import arc.x.blaze.collision.shapes.fluidParticle;

struct TimeStep {
    float dt;			// time step
    float inv_dt;		// inverse time step (0 if dt == 0).
    float dtRatio;	// dt * inv_dt0
    int velocityIterations;
    int positionIterations;
    bool warmStarting;
}

/// The world class manages all physics entities, dynamic simulation,
/// and asynchronous queries. The world also contains efficient memory
/// management facilities.
class World {

    /// Construct a world object.
    /// @param gravity the world gravity vector.
    /// @param doSleep improve performance by not simulating inactive bodies.
    this (bVec2 gravity, bool doSleep) {

        m_destructionListener = null;
        m_boundaryListener = null;
        m_contactListener = null;

        m_bodyList = null;
        contactList = null;
        m_jointList = null;

        m_bodyCount = 0;
        contactCount = 0;
        m_jointCount = 0;

        m_warmStarting = true;
        m_continuousPhysics = true;

        m_allowSleep = doSleep;
        m_gravity = gravity;

        m_lock = false;

        m_inv_dt0 = 0.0f;

		m_forceRegistry = new ForceRegistry();
        m_contactManager = new ContactManager(this);
        broadPhase = new SortAndSweep(this);

        auto bd = new BodyDef(bVec2.zeroVect, 0.0f);
        m_groundBody = createBody(bd);
    }

    /// Allow or disallow sleeping
    void allowSleep(bool sleep) {
        m_allowSleep = sleep;
    }

    /// Register a destruction listener.
    void destructionListener(DestructionListener listener) {
        m_destructionListener = listener;
    }

    /// Register a broad-phase boundary listener.
    void boundaryListener(BoundaryListener listener) {
        m_boundaryListener = listener;
    }

    /// Register a contact filter to provide specific control over collision.
    /// Otherwise the default filter is used (_defaultFilter).
    void contactFilter(ContactFilter filter) {
        m_contactFilter = filter;
    }

    ContactFilter contactFilter() {
        return m_contactFilter;
    }

    /// Register a contact event listener
    void contactListener(ContactListener listener) {
        m_contactListener = listener;
    }

    ContactListener contactListener() {
        return m_contactListener;
    }

    /// Create a rigid body given a definition. No reference to the definition
    /// is retained.
    /// @warning This function is locked during callbacks.
    Body createBody(BodyDef def) {
        assert(!m_lock);
        if (m_lock) {
            return null;
        }

        Body b = new Body(def, this);

        // Add to world doubly linked list.
        b.prev = null;
        b.next = m_bodyList;
        if (m_bodyList) {
            m_bodyList.prev = b;
        }
        m_bodyList = b;
        ++m_bodyCount;

        return b;
    }

    /// Destroy a rigid body given a definition. No reference to the definition
    /// is retained. This function is locked during callbacks.
    /// @warning This automatically deletes all associated shapes and joints.
    /// @warning This function is locked during callbacks.
    void destroyBody(Body b) {

        assert(m_bodyCount > 0);
        assert(!m_lock);
        if (m_lock) {
            return;
        }

        // Delete the attached joints.
        JointEdge jn = b.jointList;
        while (jn) {
            JointEdge jn0 = jn;
            jn = jn.next;

            if (m_destructionListener) {
                m_destructionListener.sayGoodbye(jn0.joint);
            }

            destroyJoint(jn0.joint);
        }

        // Delete the attached shapes. This destroys broad-phase
        // proxies and pairs, leading to the destruction of contacts.
        Shape s = b.shapeList;
        while (s) {
            Shape s0 = s;
            s = s.next;

            if (m_destructionListener) {
                m_destructionListener.sayGoodbye(s0);
            }

            broadPhase.removeShape(s0);
            delete s0;
        }

        broadPhase.removeBodyContacts(b);

        // Remove world body list.
        if (b.prev) {
            b.prev.next = b.next;
        }

        if (b.next) {
            b.next.prev = b.prev;
        }

        if (b is m_bodyList) {
            m_bodyList = b.next;
        }

        --m_bodyCount;
        delete b;
    }

    /// Create a joint to constrain bodies together. No reference to the definition
    /// is retained. This may cause the connected bodies to cease colliding.
    /// @warning This function is locked during callbacks.
    Joint createJoint(JointDef def) {

        assert(!m_lock);

        Joint j = Joint.create(def);

        // Connect to the world list.
        j.prev = null;
        j.next = m_jointList;
        if (m_jointList) {
            m_jointList.prev = j;
        }
        m_jointList = j;
        ++m_jointCount;

        // Connect to the bodies' doubly linked lists.
        j.node1.joint = j;
        j.node1.other = j.rBody2;
        j.node1.prev = null;
        j.node1.next = j.rBody1.jointList;
        if (j.rBody1.jointList) j.rBody1.jointList.prev = j.node1;
        j.rBody1.jointList = j.node1;

        j.node2.joint = j;
        j.node2.other = j.rBody1;
        j.node2.prev = null;
        j.node2.next = j.rBody2.jointList;
        if (j.rBody2.jointList) j.rBody2.jointList.prev = j.node2;
        j.rBody2.jointList = j.node2;

        /*
        // If the joint prevents collisions, then reset collision filtering.
        if (!def.collideConnected) {
            // Reset the proxies on the body with the minimum number of shapes.
            Body b = def.rBody1.shapeCount < def.rBody2.shapeCount ? def.rBody1 : def.rBody2;
            for (Shape s = b.shapeList; s; s = s.next) {
                s.refilterProxy(broadPhase, b.xf);
            }
        }
        */
        return j;
    }

    /// Destroy a joint. This may cause the connected bodies to begin colliding.
    /// @warning This function is locked during callbacks.
    void destroyJoint(Joint j) {
        assert(!m_lock);

        bool collideConnected = j.collideConnected;

        // Remove from the doubly linked list.
        if (j.prev !is null) {
            j.prev.next = j.next;
        }

        if (j.next) {
            j.next.prev = j.prev;
        }

        if (j == m_jointList) {
            m_jointList = j.next;
        }

        // Disconnect from island graph.
        Body body1 = j.rBody1;
        Body body2 = j.rBody2;

        // Wake up connected bodies.
        body1.wakeup();
        body2.wakeup();

        // Remove from body 1.
        if (j.node1.prev) {
            j.node1.prev.next = j.node1.next;
        }

        if (j.node1.next) {
            j.node1.next.prev = j.node1.prev;
        }

        if (j.node1 == body1.jointList) {
            body1.jointList = j.node1.next;
        }

        j.node1.prev = null;
        j.node1.next = null;

        // Remove from body 2
        if (j.node2.prev) {
            j.node2.prev.next = j.node2.next;
        }

        if (j.node2.next) {
            j.node2.next.prev = j.node2.prev;
        }

        if (j.node2 == body2.jointList) {
            body2.jointList = j.node2.next;
        }

        j.node2.prev = null;
        j.node2.next = null;

        delete j;

        assert(m_jointCount > 0);
        --m_jointCount;

        /*
        // If the joint prevents collisions, then reset collision filtering.
        if (collideConnected == false) {
            // Reset the proxies on the body with the minimum number of shapes.
            Body b = body1.shapeCount < body2.shapeCount ? body1 : body2;
            for (Shape s = b.shapeList; s; s = s.next) {
                s.refilterProxy(broadPhase, b.xf);
            }
        }
        */
    }

	/**
	* Applies a force to a rigid body.
	*/
	bool addForce(ForceGenerator fg) {
		//TODO check for duplicates
		m_forceRegistry.add(fg);
		return true;
	}

	/**
	* Removes a force from a rigid body.
	*/
	bool removeForce(ForceGenerator fg) {
		return m_forceRegistry.remove(fg);
	}

	/**
	* Return a list of world forces
	*/
	ForceGenerator[] forces() {
	    return m_forceRegistry.forces();
    }

    /// The world provides a single static ground body with no collision shapes.
    /// You can use this to simplify the creation of joints and static shapes.
    Body groundBody() {
        return m_groundBody;
    }

    /// Take a time step. This performs collision detection, integration,
    /// and constraint solution.
    /// @param timeStep the amount of time to simulate, this should not vary.
    /// @param velocityIterations for the velocity constraint solver.
    /// @param positionIterations for the position constraint solver.
    void step(float dt, int velocityIterations, int positionIterations) {

        m_lock = true;
        TimeStep step;
        step.dt = dt;
        step.velocityIterations	= velocityIterations;
        step.positionIterations = positionIterations;

        if (dt > 0.0f) {
            step.inv_dt = 1.0f / dt;
        } else {
            step.inv_dt = 0.0f;
        }

        step.dtRatio = m_inv_dt0 * dt;
        step.warmStarting = m_warmStarting;

        /*/////////////////////////////////////////////////////////
		// Update contacts
		/////////////////////////////////////////////////////////*/

        m_contactManager.collide();

		/*/////////////////////////////////////////////////////////
		// evaluate all attached forces
		/////////////////////////////////////////////////////////*/

		m_forceRegistry.evaluate();

        // Integrate velocities, solve velocity constraints, and integrate positions.
        if (step.dt > 0.0f) {
            solve(step);
        }

        // Handle TOI events.
        if (m_continuousPhysics && step.dt > 0.0f) {
            solveTOI(step);
        }

        m_inv_dt0 = step.inv_dt;
        m_lock = false;
    }

    /// Query the world for all shapes that potentially overlap the
    /// provided AABB. You provide a shape pointer buffer of specified
    /// size. The number of shapes found is returned.
    /// @param aabb the query box.
    /// @param shapes a user allocated shape pointer array of size maxCount (or greater).
    /// @param maxCount the capacity of the shapes array.
    /// @return the number of shapes found in aabb.
    void query(AABB aabb, inout Shape[] results) {
        broadPhase.query(aabb, results);
    }

    /// Query the world for all shapes that intersect a given segment. You provide a shape
    /// pointer buffer of specified size. The number of shapes found is returned, and the buffer
    /// is filled in order of intersection
    /// @param segment defines the begin and end point of the ray cast, from p1 to p2.
    /// Use Segment.Extend to create (semi-)infinite rays
    /// @param shapes a user allocated shape pointer array of size maxCount (or greater).
    /// @param maxCount the capacity of the shapes array
    /// @param solidShapes determines if shapes that the ray starts in are counted as hits.
    /// @param userData passed through the worlds contact filter, with method RayCollide. This can be used to filter valid shapes
    /// @returns the number of shapes found
    int raycast(Segment segment, Shape[] shapes, bool solidShapes, Object userData) {
        m_raycastSegment = segment;
        m_raycastUserData = userData;
        m_raycastSolidShape = solidShapes;
        Shape[] results;
        int count; // = broadPhase.querySegment(segment,results,maxCount, RaycastSortKey);
        shapes = results.dup;
        delete results;
        return count;
    }

    /// Performs a raycast as with Raycast, finding the first intersecting shape.
    /// @param segment defines the begin and end point of the ray cast, from p1 to p2.
    /// Use Segment.Extend to create (semi-)infinite rays
    /// @param lambda returns the hit fraction. You can use this to compute the contact point
    /// p = (1 - lambda) * segment.p1 + lambda * segment.p2.
    /// @param normal returns the normal at the contact point. If there is no intersection, the normal
    /// is not set.
    /// @param solidShapes determines if shapes that the ray starts in are counted as hits.
    /// @returns the colliding shape shape, or null if not found
    Shape raycastOne(Segment segment, inout float lambda, inout bVec2 normal, bool solidShapes, Object userData) {
        int maxCount = 1;
        Shape[] shape;
        shape.length = 1;
        int count = raycast(segment, shape, solidShapes, userData);
        if (count==0) return null;
        assert(count==1);
        //Redundantly do TestSegment a second time, as the previous one's results are inaccessible
        bXForm xf = shape[0].rBody.xf;
        shape[0].testSegment(xf, lambda, normal,segment,1);
        //We already know it returns true
        return shape[0];
    }

    /** Add fluid particles to the world **/
    void addFluidParticle(Shape shape) {
        if (sph is null) {
            sph = new SPHSimulation();
        }
        if (shape.type != ShapeType.FLUID) {
            throw new Exception("Invalid shape type");
        }
        broadPhase.addShape(shape);
        sph.addParticle(cast(FluidParticle)shape);
    }

    /** Get the Fluid Particle list **/
    FluidParticle[] particles() {
        if (sph) {
            return sph.particles;
        }
        return null;
    }

    /// Get the world body list. With the returned body, use Body::GetNext to get
    /// the next body in the world list. A null body indicates the end of the list.
    /// @return the head of the world body list.
    Body bodyList() {
        return m_bodyList;
    }

    /// Get the world joint list. With the returned joint, use Joint::GetNext to get
    /// the next joint in the world list. A null joint indicates the end of the list.
    /// @return the head of the world joint list.
    Joint jointList() {
        return m_jointList;
    }

    /// Enable/disable warm starting. For testing.
    void setWarmStarting(bool flag) {
        m_warmStarting = flag;
    }

    /// Enable/disable continuous physics. For testing.
    void setContinuousPhysics(bool flag) {
        m_continuousPhysics = flag;
    }

    /// Perform validation of internal data structures.
    void validate() {
        //broadPhase.validate();
    }

    /// Get the number of bodies.
    int bodyCount() {
        return m_bodyCount;
    }

    /// Get the number joints.
    int jointCount() {
        return m_jointCount;
    }

    /// Change the global gravity vector.
    void gravity(bVec2 gravity) {
        m_gravity = gravity;
        // Wake all the bodies up
        for (Body b = m_bodyList; b; b = b.next) {
            b.wakeup();
        }
    }

    /// Get the global gravity vector.
    bVec2 gravity() {
        return m_gravity;
    }

    bool lock() {
        return m_lock;
    }

    BroadPhase broadPhase;
    // Do not access
    Contact contactList;
    int contactCount;
    SPHSimulation sph;

private:

    // Find islands, integrate and solve constraints, solve position constraints
    void solve(TimeStep step) {

        Island island;

        // Clear all the island flags.
        for (Body b = m_bodyList; b; b = b.next) {
            b.flags &= ~Body.ISLAND;
        }
        for (Contact c = contactList; c; c = c.next) {
            c.flags &= ~Contact.ISLAND;
        }
        for (Joint j = m_jointList; j; j = j.next) {
            j.islandFlag = false;
        }

        // Build and simulate all awake islands.
        int stackSize = m_bodyCount;
        Body[] stack;
        stack.length = stackSize;

        for (Body seed = m_bodyList; seed; seed = seed.next) {

            if (seed.flags & (Body.ISLAND | Body.SLEEP | Body.FROZEN)) {
                continue;
            }

            if (seed.isStatic) {
                continue;
            }

            // Reset island and stack.
            // Reset island and stack.
            island = new Island(m_contactListener);
            stack[0] = seed;
            int stackCount = 1;

            seed.flags |= Body.ISLAND;

            // Perform a depth first search (DFS) on the constraint graph.
            while (stackCount > 0) {
                // Grab the next body off the stack and add it to the island.
                Body b = stack[--stackCount];
                island.add(b);

                // Make sure the body is awake.
                b.flags &= ~Body.SLEEP;

                // To keep islands as small as possible, we don't
                // propagate islands across static bodies.
                if (b.isStatic) {
                    continue;
                }

                // Search all contacts connected to this body.
                for (ContactEdge cn = b.contactList; cn; cn = cn.next) {
                    // Has this contact already been added to an island?
                    if (cn.contact.flags & (Contact.ISLAND | Contact.NON_SOLID)) {
                        continue;
                    }

                    // Is this contact touching?
                    if (cn.contact.manifoldCount == 0) {
                        continue;
                    }

                    island.add(cn.contact);
                    cn.contact.flags |= Contact.ISLAND;

                    Body other = cn.other;

                    // Was the other body already added to this island?
                    if (other.flags & Body.ISLAND) {
                        continue;
                    }

                    assert(stackCount < stackSize);
                    stack[stackCount++] = other;
                    other.flags |= Body.ISLAND;
                }

                // Search all joints connect to this body.
                for (JointEdge jn = b.jointList; jn; jn = jn.next) {
                    if (jn.joint.islandFlag) {
                        continue;
                    }

                    island.add(jn.joint);
                    jn.joint.islandFlag = true;

                    Body other = jn.other;
                    if (other.flags & Body.ISLAND) {
                        continue;
                    }

                    assert(stackCount < stackSize);
                    stack[stackCount++] = other;
                    other.flags |= Body.ISLAND;
                }
            }

            island.solve(step, m_gravity, m_allowSleep);

            // Post solve cleanup.
            for (int i = 0; i < island.bodies.length; ++i) {
                // Allow static bodies to participate in other islands.
                Body b = island.bodies[i];
                if (b.isStatic) {
                    b.flags &= ~Body.ISLAND;
                }
            }
        }

        // Synchronize shapes, check for out of range bodies.
        for (Body b = m_bodyList; b; b = b.next) {

            if (b.flags & (Body.SLEEP | Body.FROZEN)) {
                continue;
            }

            if (b.isStatic) {
                continue;
            }

            // Update shapes (for broad-phase).
            b.synchronizeShapes();
        }

        // Update fluid dynamics
        if (sph !is null) {
            sph.update(m_gravity, step);
        }

        // Commit shape proxy movements to the broad-phase so that new contacts are created.
        // Also, some contacts can be destroyed.
        broadPhase.search();

        // Reset fluid forces
        if (sph !is null) {
            sph.resetForce();
        }

    }

    // Find TOI contacts and solve them.
    void solveTOI(TimeStep step) {

        auto island = new Island(m_contactListener);

        //Simple one pass queue
        //Relies on the fact that we're only making one pass
        //through and each body can only be pushed/popped once.
        //To push:
        //  queue[queueStart+queueSize++] = newElement;
        //To pop:
        //	poppedElement = queue[queueStart++];
        //  --queueSize;
        int queueCapacity = m_bodyCount;
        Body[] queue;
        queue.length = queueCapacity;

        for (Body b = m_bodyList; b; b = b.next) {
            b.flags &= ~Body.ISLAND;
            b.sweep.t0 = 0.0f;
        }

        for (Contact c = contactList; c; c = c.next) {
            // Invalidate TOI
            c.flags &= ~(Contact.TOI | Contact.ISLAND);
        }

        for (Joint j = m_jointList; j; j = j.next) {
            j.islandFlag = false;
        }

        // Find TOI events and solve them.
        for (;;) {
            // Find the first TOI.
            Contact minContact = null;
            float minTOI = 1.0f;

            for (Contact c = contactList; c; c = c.next) {

                if (c.flags & (Contact.SLOW | Contact.NON_SOLID)) {
                    continue;
                }

                // TODO_ERIN keep a counter on the contact, only respond to M TOIs per contact.

                float toi = 1.0f;
                if (c.flags & Contact.TOI) {
                    // This contact has a valid cached TOI.
                    toi = c.toi;
                } else {
                    // Compute the TOI for this contact.
                    Shape s1 = c.shape1;
                    Shape s2 = c.shape2;
                    Body b1 = s1.rBody;
                    Body b2 = s2.rBody;

                    if ((b1.isStatic || b1.isSleeping) && (b2.isStatic || b2.isSleeping)) {
                        continue;
                    }

                    // Put the sweeps onto the same time interval.
                    float t0 = b1.sweep.t0;

                    if (b1.sweep.t0 < b2.sweep.t0) {
                        t0 = b2.sweep.t0;
                        b1.sweep.advance(t0);
                    } else if (b2.sweep.t0 < b1.sweep.t0) {
                        t0 = b1.sweep.t0;
                        b2.sweep.advance(t0);
                    }

                    assert(t0 < 1.0f);

                    // Compute the time of impact.
                    toi = timeOfImpact(c.shape1, b1.sweep, c.shape2, b2.sweep);

                    assert(0.0f <= toi && toi <= 1.0f);

                    if (toi > 0.0f && toi < 1.0f) {
                        toi = min((1.0f - toi) * t0 + toi, 1.0f);
                    }

                    c.toi = toi;
                    c.flags |= Contact.TOI;
                }

                if (float.epsilon < toi && toi < minTOI) {
                    // This is the minimum TOI found so far.
                    minContact = c;
                    minTOI = toi;
                }
            }

            if (minContact is null || 1.0f - 100.0f * float.epsilon < minTOI) {
                // No more TOI events. Done!
                break;
            }

            // Advance the bodies to the TOI.
            Shape s1 = minContact.shape1;
            Shape s2 = minContact.shape2;
            Body b1 = s1.rBody;
            Body b2 = s2.rBody;
            b1.advance(minTOI);
            b2.advance(minTOI);

            // The TOI contact likely has some new contact points.
            minContact.update(m_contactListener);
            minContact.flags &= ~Contact.TOI;

            if (minContact.manifoldCount == 0) {
                // This shouldn't happen. Numerical error?
                //assert(false);
                continue;
            }

            // Build the TOI island. We need a dynamic seed.
            Body seed = b1;
            if (seed.isStatic) {
                seed = b2;
            }

            // Reset island and queue.
            island.clear();

            int queueStart = 0; //starting index for queue
            int queueSize = 0;  //elements in queue
            queue[queueStart + queueSize++] = seed;
            seed.flags |= Body.ISLAND;

            // Perform a breadth first search (BFS) on the contact/joint graph.
            while (queueSize > 0) {
                // Grab the next body off the stack and add it to the island.
                Body b = queue[queueStart++];
                --queueSize;

                island.add(b);

                // Make sure the body is awake.
                b.flags &= ~Body.SLEEP;

                // To keep islands as small as possible, we don't
                // propagate islands across static bodies.
                if (b.isStatic) {
                    continue;
                }

                // Search all contacts connected to this body.
                for (ContactEdge cn = b.contactList; cn; cn = cn.next) {

                    // Has this contact already been added to an island? Skip slow or non-solid contacts.
                    if (cn.contact.flags & (Contact.ISLAND | Contact.SLOW | Contact.NON_SOLID)) {
                        continue;
                    }

                    // Is this contact touching? For performance we are not updating this contact.
                    if (cn.contact.manifoldCount == 0) {
                        continue;
                    }

                    island.add(cn.contact);
                    cn.contact.flags |= Contact.ISLAND;

                    // Update other body.
                    Body other = cn.other;

                    // Was the other body already added to this island?
                    if (other.flags & Body.ISLAND) {
                        continue;
                    }

                    // March forward, this can do no harm since this is the min TOI.
                    if (other.isStatic == false) {
                        other.advance(minTOI);
                        other.wakeup();
                    }

                    assert(queueStart + queueSize < queueCapacity);
                    queue[queueStart + queueSize++] = other;
                    other.flags |= Body.ISLAND;
                }

                for (JointEdge jn = b.jointList; jn; jn = jn.next) {

                    if (jn.joint.islandFlag) {
                        continue;
                    }

                    island.add(jn.joint);

                    jn.joint.islandFlag = true;

                    Body other = jn.other;

                    if (other.flags & Body.ISLAND) {
                        continue;
                    }

                    if (!other.isStatic) {
                        other.advance(minTOI);
                        other.wakeup();
                    }

                    assert(queueStart + queueSize < queueCapacity);
                    queue[queueStart + queueSize++] = other;
                    other.flags |= Body.ISLAND;
                }
            }

            TimeStep subStep;
            subStep.warmStarting = false;
            subStep.dt = (1.0f - minTOI) * step.dt;
            assert(subStep.dt > float.epsilon);
            subStep.inv_dt = 1.0f / subStep.dt;
            subStep.dtRatio = 0.0f;
            subStep.velocityIterations = step.velocityIterations;
            subStep.positionIterations = step.positionIterations;

            island.solveTOI(subStep);

            // Post solve cleanup.
            for (int i = 0; i < island.bodies.length; ++i) {
                // Allow bodies to participate in future TOI islands.
                Body b = island.bodies[i];
                b.flags &= ~Body.ISLAND;

                if (b.flags & (Body.SLEEP | Body.FROZEN)) {
                    continue;
                }

                if (b.isStatic) {
                    continue;
                }

                // Update shapes (for broad-phase). If the shapes go out of
                // the world AABB then shapes and contacts may be destroyed,
                // including contacts that are
                bool inRange = b.synchronizeShapes();

                // Did the body's shapes leave the world?
                if (inRange == false && m_boundaryListener !is null) {
                    m_boundaryListener.violation(b);
                }

                // Invalidate all contact TOIs associated with this body. Some of these
                // may not be in the island because they were not touching.
                for (ContactEdge cn = b.contactList; cn; cn = cn.next) {
                    cn.contact.flags &= ~Contact.TOI;
                }
            }

            for (int i = 0; i < island.contactCount; ++i) {
                // Allow contacts to participate in future TOI islands.
                Contact c = island.contacts[i];
                c.flags &= ~(Contact.TOI | Contact.ISLAND);
            }

            for (int i = 0; i < island.jointCount; ++i) {
                // Allow joints to participate in future TOI islands.
                Joint j = island.joints[i];
                j.islandFlag = false;
            }

            // Commit shape proxy movements to the broad-phase so that new contacts are created.
            // Also, some contacts can be destroyed.
            broadPhase.search();
        }
    }

    bool m_lock;

    Island island;
    ContactManager m_contactManager;

    Body m_bodyList;
    Joint m_jointList;

    bVec2 m_raycastNormal;
    Object m_raycastUserData;
    Segment m_raycastSegment;
    bool m_raycastSolidShape;

    int m_bodyCount;
    int m_jointCount;

    bVec2 m_gravity;
    bool m_allowSleep;

    Body m_groundBody;

	ForceRegistry m_forceRegistry;

    DestructionListener m_destructionListener;
    BoundaryListener m_boundaryListener;
    ContactFilter m_contactFilter;
    ContactListener m_contactListener;

    // This is used to compute the time step ratio to
    // support a variable time step.
    float m_inv_dt0;

    // This is for debugging the solver.
    bool m_warmStarting;

    // This is for debugging the solver.
    bool m_continuousPhysics;
}
