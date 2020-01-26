/*
 * Copyright (c) 2007-2008, Michael Baczynski
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * * Neither the name of the polygonal nor the names of its contributors may be
 *   used to endorse or promote products derived from this software without specific
 *   prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
module arc.x.blaze.dynamics.contact.contactFactory;

import  arc.x.blaze.dynamics.Body,
        arc.x.blaze.dynamics.contact.generator.circleContact,
        arc.x.blaze.dynamics.contact.generator.circleFluidContact,
        arc.x.blaze.dynamics.contact.generator.polyCircleContact,
        arc.x.blaze.dynamics.contact.generator.polyContact,
        arc.x.blaze.dynamics.contact.generator.polyFluidContact,
        arc.x.blaze.collision.shapes.shapeType,
        arc.x.blaze.collision.shapes.shape,
        arc.x.blaze.collision.collision,
        arc.x.blaze.dynamics.contact.contact;

alias Contact function(Shape, Shape) ContactCreateFcn;

/** Contact register */
struct ContactRegister {
    ContactCreateFcn createFcn;
    bool primary;
}

class ContactFactory {

    this() {
        initializeRegisters();
    }

    ///
    void initializeRegisters() {
        addType(&CircleContact.create, ShapeType.CIRCLE, ShapeType.CIRCLE);
        addType(&CircleFluidContact.create, ShapeType.CIRCLE, ShapeType.FLUID);
        addType(&PolyCircleContact.create, ShapeType.POLYGON, ShapeType.CIRCLE);
        addType(&PolyContact.create, ShapeType.POLYGON, ShapeType.POLYGON);
        addType(&PolyFluidContact.create, ShapeType.POLYGON, ShapeType.FLUID);
        s_initialized = true;
    }

    ///
    void addType(ContactCreateFcn createFcn, int type1, int type2) {

        assert(ShapeType.UNKNOWN < type1 && type1 < ShapeType.SHAPE_COUNT);
        assert(ShapeType.UNKNOWN < type2 && type2 < ShapeType.SHAPE_COUNT);

        s_registers[type1][type2].createFcn = createFcn;
        s_registers[type1][type2].primary = true;

        if (type1 != type2) {
            s_registers[type2][type1].createFcn = createFcn;
            s_registers[type2][type1].primary = false;
        }
    }

    ///
    Contact create(Shape shape1, Shape shape2) {

        if (!s_initialized) {
            initializeRegisters();
            s_initialized = true;
        }

        ShapeType type1 = shape1.type;
        ShapeType type2 = shape2.type;

        assert(ShapeType.UNKNOWN < type1 && type1 < ShapeType.SHAPE_COUNT);
        assert(ShapeType.UNKNOWN < type2 && type2 < ShapeType.SHAPE_COUNT);

        ContactCreateFcn createFcn = s_registers[type1][type2].createFcn;
        if (createFcn) {
            if (s_registers[type1][type2].primary) {
                return createFcn(shape1, shape2);
            } else {
                Contact c = createFcn(shape2, shape1);
                for (int i = 0; i < c.manifoldCount; ++i) {
                    c.manifolds[i].normal *= -1;
                }
                return c;
            }
        } else {
            return null;
        }
    }

    void destroy(Contact contact) {
        assert(s_initialized);

        if (contact.manifoldCount > 0)
        {
            contact.shape1.rBody.wakeup();
            contact.shape2.rBody.wakeup();
        }

        ShapeType type1 = contact.shape1.type;
        ShapeType type2 = contact.shape2.type;

        assert(ShapeType.UNKNOWN < type1 && type1 < ShapeType.SHAPE_COUNT);
        assert(ShapeType.UNKNOWN < type2 && type2 < ShapeType.SHAPE_COUNT);

        delete contact;
    }

private:

    ContactRegister s_registers[ShapeType.SHAPE_COUNT][ShapeType.SHAPE_COUNT];
    bool s_initialized;

}
