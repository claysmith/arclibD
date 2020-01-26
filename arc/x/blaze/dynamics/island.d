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
module arc.x.blaze.dynamics.island;

import arc.x.blaze.world;
import arc.x.blaze.common.math;
import arc.x.blaze.common.constants;
import arc.x.blaze.dynamics.Body;
import arc.x.blaze.dynamics.joints.joint;
import arc.x.blaze.dynamics.contact.contact;
import arc.x.blaze.dynamics.contact.contactSolver;
import arc.x.blaze.dynamics.worldCallbacks;
import arc.x.blaze.collision.collision;

/**
Position Correction Notes
=========================
I tried the several algorithms for position correction of the 2D revolute joint.
I looked at these systems:
- simple pendulum (1m diameter sphere on massless 5m stick) with initial angular velocity of 100 rad/s.
- suspension bridge with 30 1m long planks of length 1m.
- multi-link chain with 30 1m long links.

Here are the algorithms:

Baumgarte - A fraction of the position error is added to the velocity error. There is no
separate position solver.

Pseudo Velocities - After the velocity solver and position integration,
the position error, Jacobian, and effective mass are recomputed. Then
the velocity constraints are solved with pseudo velocities and a fraction
of the position error is added to the pseudo velocity error. The pseudo
velocities are initialized to zero and there is no warm-starting. After
the position solver, the pseudo velocities are added to the positions.
This is also called the First Order World method or the Position LCP method.

Modified Nonlinear Gauss-Seidel (NGS) - Like Pseudo Velocities except the
position error is re-computed for each constraint and the positions are updated
after the constraint is solved. The radius vectors (aka Jacobians) are
re-computed too (otherwise the algorithm has horrible instability). The pseudo
velocity states are not needed because they are effectively zero at the beginning
of each iteration. Since we have the current position error, we allow the
iterations to terminate early if the error becomes smaller than k_linearSlop.

Full NGS or just NGS - Like Modified NGS except the effective mass are re-computed
each time a constraint is solved.

Here are the results:
Baumgarte - this is the cheapest algorithm but it has some stability problems,
especially with the bridge. The chain links separate easily close to the root
and they jitter as they struggle to pull together. This is one of the most common
methods in the field. The big drawback is that the position correction artificially
affects the momentum, thus leading to instabilities and false bounce. I used a
bias factor of 0.2. A larger bias factor makes the bridge less stable, a smaller
factor makes joints and contacts more spongy.

Pseudo Velocities - the is more stable than the Baumgarte method. The bridge is
stable. However, joints still separate with large angular velocities. Drag the
simple pendulum in a circle quickly and the joint will separate. The chain separates
easily and does not recover. I used a bias factor of 0.2. A larger value lead to
the bridge collapsing when a heavy cube drops on it.

Modified NGS - this algorithm is better in some ways than Baumgarte and Pseudo
Velocities, but in other ways it is worse. The bridge and chain are much more
stable, but the simple pendulum goes unstable at high angular velocities.

Full NGS - stable in all tests. The joints display good stiffness. The bridge
still sags, but this is better than infinite forces.

Recommendations
Pseudo Velocities are not really worthwhile because the bridge and chain cannot
recover from joint separation. In other cases the benefit over Baumgarte is small.

Modified NGS is not a robust method for the revolute joint due to the violent
instability seen in the simple pendulum. Perhaps it is viable with other constraint
types, especially scalar constraints where the effective mass is a scalar.

This leaves Baumgarte and Full NGS. Baumgarte has small, but manageable instabilities
and is very fast. I don't think we can escape Baumgarte, especially in highly
demanding cases where high constraint fidelity is not needed.

Full NGS is robust and easy on the eyes. I recommend this as an option for
higher fidelity simulation and certainly for suspension bridges and long chains.
Full NGS might be a good choice for ragdolls, especially motorized ragdolls where
joint separation can be problematic. The number of NGS iterations can be reduced
for better performance without harming robustness much.

Each joint in a can be handled differently in the position solver. So I recommend
a system where the user can select the algorithm on a per joint basis. I would
probably default to the slower Full NGS and let the user select the faster
Baumgarte method in performance critical scenarios.
*/

/**
Cache Performance

The Box2D solvers are dominated by cache misses. Data structures are designed
to increase the number of cache hits. Much of misses are due to random access
to body data. The constraint structures are iterated over linearly, which leads
to few cache misses.

The bodies are not accessed during iteration. Instead read only data, such as
the mass values are stored with the constraints. The mutable data are the constraint
impulses and the bodies velocities/positions. The impulses are held inside the
constraint structures. The body velocities/positions are held in compact, temporary
arrays to increase the number of cache hits. Linear and angular velocity are
stored in a single array since multiple arrays lead to multiple misses.
*/

/**
2D Rotation

R = [cos(theta) -sin(theta)]
    [sin(theta) cos(theta) ]

thetaDot = omega

Let q1 = cos(theta), q2 = sin(theta).
R = [q1 -q2]
    [q2  q1]

q1Dot = -thetaDot * q2
q2Dot = thetaDot * q1

q1_new = q1_old - dt * w * q2
q2_new = q2_old + dt * w * q1
then normalize.

This might be faster than computing sin+cos.
However, we can compute sin+cos of the same angle fast.
*/

struct Position {
    bVec2 x;
    float a;
}

struct Velocity {
    bVec2 v;
    float w;
}

class Island {

    this (ContactListener listener) {
        m_listener = listener;
    }

    void clear() {
        delete bodies;
        delete contacts;
        delete joints;
    }

    int contactCount() {
        return contacts.length;
    }

    int jointCount() {
        return joints.length;
    }

    int bodyCount() {
        return bodies.length;
    }

    void solve(TimeStep step, bVec2 gravity, bool allowSleep) {
        // Integrate velocities and apply damping.
        for (int i = 0; i < bodies.length; ++i) {
            Body b = bodies[i];

            if (b.isStatic) continue;

            // Integrate velocities.
            b.linearVelocity = b.linearVelocity + step.dt * (gravity + b.invMass * b.force);
            b.angularVelocity = b.angularVelocity + step.dt * b.invI * b.torque;

            // Reset forces.
            b.force = bVec2.zeroVect;
            b.torque = 0.0f;

            // Apply damping.
            // ODE: dv/dt + c * v = 0
            // Solution: v(t) = v0 * exp(-c * t)
            // Time step: v(t + dt) = v0 * exp(-c * (t + dt)) = v0 * exp(-c * t) * exp(-c * dt) = v * exp(-c * dt)
            // v2 = exp(-c * dt) * v1
            // Taylor expansion:
            // v2 = (1.0f - c * dt) * v1
            b.linearVelocity = b.linearVelocity * bClamp(1.0f - step.dt * b.linearDamping, 0.0f, 1.0f);
            b.angularVelocity = b.angularVelocity * bClamp(1.0f - step.dt * b.angularDamping, 0.0f, 1.0f);

            // Check for large velocities.
            if (bDot(b.linearVelocity, b.linearVelocity) > k_maxLinearVelocitySquared) {
                b.linearVelocity.normalize();
                b.linearVelocity *= k_maxLinearVelocity;
            }
            if (b.angularVelocity * b.angularVelocity > k_maxAngularVelocitySquared) {
                if (b.angularVelocity < 0.0f) {
                    b.angularVelocity = -k_maxAngularVelocity;
                } else {
                    b.angularVelocity = k_maxAngularVelocity;
                }
            }
        }

        contactSolver = new ContactSolver(step, contacts);
        // Initialize velocity constraints.

        contactSolver.initVelocityConstraints(step);

        for (int i = 0; i < joints.length; ++i) {
            joints[i].initVelocityConstraints(step);
        }

        // Solve velocity constraints.
        for (int i = 0; i < step.velocityIterations; ++i) {
            for (int j = 0; j < joints.length; ++j) {
                joints[j].solveVelocityConstraints(step);
            }

            contactSolver.solveVelocityConstraints();
        }

        // Post-solve (store impulses for warm starting).
        contactSolver.finalizeVelocityConstraints();


        // Integrate positions.
        for (int i = 0; i < bodies.length; ++i) {
            Body b = bodies[i];

            if (b.isStatic) continue;

            // Store positions for continuous collision.
            b.sweep.c0 = b.sweep.c;
            b.sweep.a0 = b.sweep.a;

            // Integrate
            b.sweep.c = b.sweep.c + step.dt * b.linearVelocity;
            b.sweep.a = b.sweep.a + step.dt * b.angularVelocity;

            // Compute new transform
            b.synchronizeTransform();
            // Note: shapes are synchronized later.
        }

        // Iterate over constraints.
        for (int i = 0; i < step.positionIterations; ++i) {
            bool contactsOkay = contactSolver.solvePositionConstraints(k_contactBaumgarte);
            bool jointsOkay = true;
            for (int j = 0; j < joints.length; ++j) {
                bool jointOkay = joints[j].solvePositionConstraints(k_contactBaumgarte);
                jointsOkay = jointsOkay && jointOkay;
            }
            if (contactsOkay && jointsOkay) {
                // Exit early if the position errors are small.
                break;
            }
        }

        report(contactSolver.constraints);

        if (allowSleep) {

            float minSleepTime = float.max;
            float linTolSqr = k_linearSleepTolerance * k_linearSleepTolerance;
            float angTolSqr = k_angularSleepTolerance * k_angularSleepTolerance;

            for (int i = 0; i < bodies.length; ++i) {
                Body b = bodies[i];
                if (b.invMass == 0.0f) {
                    continue;
                }

                if ((b.flags & Body.ALLOW_SLEEP) == 0) {
                    b.sleepTime = 0.0f;
                    minSleepTime = 0.0f;
                }

                if ((b.flags & Body.ALLOW_SLEEP) == 0 ||
                        b.angularVelocity * b.angularVelocity > angTolSqr ||
                        bDot(b.linearVelocity, b.linearVelocity) > linTolSqr) {
                    b.sleepTime = 0.0f;
                    minSleepTime = 0.0f;
                } else {
                    b.sleepTime = b.sleepTime + step.dt;
                    minSleepTime = min(minSleepTime, b.sleepTime);
                }
            }

            if (minSleepTime >= k_timeToSleep) {
                for (int i = 0; i < bodies.length; ++i) {
                    Body b = bodies[i];
                    b.flags |= Body.SLEEP;
                    b.linearVelocity = bVec2.zeroVect;
                    b.angularVelocity = 0.0f;
                }
            }
        }
    }

    void solveTOI(TimeStep subStep) {

        contactSolver = new ContactSolver(subStep, contacts);

        // No warm starting needed for TOI contact events.

        // For joints, initialize with the last full step warm starting values
        subStep.warmStarting = true;

        for (int i = 0; i < joints.length; ++i) {
            joints[i].initVelocityConstraints(subStep);
        }

        // ...but don't update the warm starting during TOI solve!
        //subStep.warmStarting = false;

        // Solve velocity constraints.
        for (int i = 0; i < subStep.velocityIterations; ++i) {
            contactSolver.solveVelocityConstraints();
            for (int j = 0; j < joints.length; ++j) {
                joints[j].solveVelocityConstraints(subStep);
            }
        }

        // Don't store the TOI contact forces for warm starting
        // because they can be quite large.

        // Integrate positions.
        for (int i = 0; i < bodies.length; ++i) {
            Body b = bodies[i];

            if (b.isStatic)
                continue;

            // Store positions for continuous collision.
            b.sweep.c0 = b.sweep.c;
            b.sweep.a0 = b.sweep.a;

            // Integrate
            b.sweep.c = b.sweep.c + subStep.dt * b.linearVelocity;
            b.sweep.a = b.sweep.a + subStep.dt * b.angularVelocity;

            // Compute new transform
            b.synchronizeTransform();

            // Note: shapes are synchronized later.
        }

        // Solve position constraints.
        const float k_toiBaumgarte = 0.75f;
        for (int i = 0; i < subStep.positionIterations; ++i) {
            bool contactsOkay = contactSolver.solvePositionConstraints(k_toiBaumgarte);
            bool jointsOkay = true;
            for (int j = 0; j < joints.length; ++j) {
                bool jointOkay = joints[j].solvePositionConstraints(0.0f);
                jointsOkay = jointsOkay && jointOkay;
            }
            if (contactsOkay && jointsOkay) {
                break;
            }
            if (contactsOkay)
            {
                break;
            }
        }

        ContactConstraint[] constrains = contactSolver.constraints;
        report(constrains);
    }

    void add(Body rBody) {
        rBody.islandIndex = bodies.length;
        bodies ~= rBody;
    }

    void add(Contact contact) {
        contacts ~= contact;
    }

    void add(Joint joint) {
        joints ~= joint;
    }

    void report(ContactConstraint[] constraints) {

        if (m_listener is null) {
            return;
        }

        for (int i = 0; i < contacts.length; ++i) {
            Contact c = contacts[i];
            ContactConstraint cc = constraints[i];
            ContactResult cr;
            cr.shape1 = c.shape1;
            cr.shape2 = c.shape2;
            Body b1 = cr.shape1.rBody;
            int manifoldCount = c.manifoldCount;
            Manifold[] manifolds = c.manifolds;
            for (int j = 0; j < manifoldCount; ++j) {
                Manifold manifold = manifolds[j];
                cr.normal = manifold.normal;
                for (int k = 0; k < manifold.pointCount; ++k) {
                    ManifoldPoint point = manifold.points[k];
                    ContactConstraintPoint ccp = cc.points[k];
                    cr.position = b1.worldPoint(point.localPoint1);
                    // TOI constraint results are not stored, so get
                    // the result from the constraint.
                    cr.normalImpulse = ccp.normalImpulse;
                    cr.tangentImpulse = ccp.tangentImpulse;
                    cr.id = point.id;
                    m_listener.result(cr);
                }
            }
        }
    }

    ContactSolver contactSolver;
    ContactListener m_listener;

    Body[] bodies;
    Contact[] contacts;
    Joint[] joints;

    Position[] positions;
    Velocity[] velocities;

    int positionIterationCount;
}
