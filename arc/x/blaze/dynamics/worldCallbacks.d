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
module arc.x.blaze.dynamics.worldCallbacks;

import arc.x.blaze.dynamics.contact.contact;
import arc.x.blaze.dynamics.joints.joint;
import arc.x.blaze.collision.shapes.shape;
import arc.x.blaze.dynamics.Body;

/// The default contact filter.
extern ContactFilter _defaultFilter;

/// Implement this class to get collision results. You can use these results for
/// things like sounds and game logic. You can also get contact results by
/// traversing the contact lists after the time step. However, you might miss
/// some contacts because continuous physics leads to sub-stepping.
/// Additionally you may receive multiple callbacks for the same contact in a
/// single time step.
/// You should strive to make your callbacks efficient because there may be
/// many callbacks per time step.
/// @warning The contact separation is the last computed value.
/// @warning You cannot create/destroy Box2D entities inside these callbacks.
class ContactListener {
    /// Called when a contact point is added. This includes the geometry
    /// and the forces.
    abstract void add(ContactPoint point);

    /// Called when a contact point persists. This includes the geometry
    /// and the forces.
    abstract void persist(ContactPoint point);

    /// Called when a contact point is removed. This includes the last
    /// computed geometry and forces.
    abstract void remove(ContactPoint point);

    /// Called after a contact point is solved.
    abstract void result(ContactResult point);
}

/// Joints and shapes are destroyed when their associated
/// body is destroyed. Implement this listener so that you
/// may nullify references to these joints and shapes.
abstract class DestructionListener {
    /// Called when any joint is about to be destroyed due
    /// to the destruction of one of its attached bodies.
    abstract void sayGoodbye(Joint joint);

    /// Called when any shape is about to be destroyed due
    /// to the destruction of its parent body.
    abstract void sayGoodbye(Shape shape);
}

/// This is called when a body's shape passes outside of the world boundary.
abstract class BoundaryListener {
    /// This is called for each body that leaves the world boundary.
    /// @warning you can't modify the world inside this callback.
    abstract void violation(Body  rBody);
}

/// Implement this class to provide collision filtering. In other words, you can implement
/// this class if you want finer control over contact creation.
class ContactFilter {
    /// Return true if contact calculations should be performed between these two shapes.
    /// @warning for performance reasons this is only called when the AABBs begin to overlap.
    /// Return true if contact calculations should be performed between these two shapes.
    /// If you implement your own collision filter you may want to build from this implementation.
    bool shouldCollide(Shape shape1, Shape shape2) {

        FilterData filter1 = shape1.filter;
        FilterData filter2 = shape2.filter;

        if (filter1.groupIndex == filter2.groupIndex && filter1.groupIndex != 0) {
            return filter1.groupIndex > 0;
        }

        bool collide = (filter1.maskBits & filter2.categoryBits) != 0 && (filter1.categoryBits & filter2.maskBits) != 0;
        return collide;
    }

    /// Return true if the given shape should be considered for ray intersection
    bool rayCollide(Object userData, Shape shape) {
        //By default, cast userData as a shape, and then collide if the shapes would collide
        if (!userData)
            return true;
        return shouldCollide(cast(Shape) userData, shape);
    }
}

/// The default contact filter.
extern ContactFilter defaultFilter;
