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
module arc.x.blaze.dynamics.contact.generator.circleFluidContact;

import arc.x.blaze.common.constants;
import arc.x.blaze.common.math;
import arc.x.blaze.collision.shapes.shape;
import arc.x.blaze.collision.shapes.shapeType;
import arc.x.blaze.collision.shapes.circle;
import arc.x.blaze.collision.shapes.fluidParticle;
import arc.x.blaze.collision.collision;
import arc.x.blaze.collision.pairwise.collideCircle;
import arc.x.blaze.dynamics.contact.contact;
import arc.x.blaze.dynamics.worldCallbacks;
import arc.x.blaze.dynamics.Body;

/** Generate contacts from the narrow phase colliion detection
 * for Circle-Circle contacts.
 */
class CircleFluidContact : Contact {

    /** Constructor */
    this(Shape s1, Shape s2) {
        assert(s1.type == ShapeType.CIRCLE);
        assert(s2.type == ShapeType.FLUID);
        super(s1, s2);
        manifolds.length = 1;
    }

    /** Create a new contact */
    static Contact create(Shape s1, Shape s2) {
        return new CircleFluidContact(s1, s2);
    }

    /** Narrow phase collision detection */
    void evaluate(ContactListener listener) {

        auto circle = cast(Circle) m_shape1;
        auto particle = cast(FluidParticle) m_shape2;

        float restitution = particle.restitution * circle.restitution;
        float friction = particle.friction * circle.friction;
        bVec2 penetration;
        bVec2 penetrationNormal;

        bool collide;
        collide = collideCircleFluid(circle, particle, penetration, penetrationNormal);
        if(!collide) return;

        particle.applyImpulse(penetration, penetrationNormal, restitution, friction);
        circle.rBody.applyBuoyancyForce(particle);
    }
}
