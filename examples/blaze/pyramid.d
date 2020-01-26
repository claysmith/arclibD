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
module pyramid;

import demo;

class Pyramid : Demo {

    ShapeDef sd;
    BodyDef bd;
    Body rBody;

    this() {
        bVec2 gravity = bVec2(0.0f, -9.81f);
        super(gravity);
        init();
    }

    void init() {

        sd = new PolyDef();
        sd.setAsBox(50.0f, 10.0f);

        bVec2 position = bVec2(0.0f, -10.0f);
        float angle = 0.0f;
        auto bd = new BodyDef(position, angle);
        Body ground = world.createBody(bd);
        ground.createShape(sd);

        sd = new PolyDef();
        float a = 0.5f;
        sd.setAsBox(a, a);
        sd.density = 5.0f;

        bVec2 x = bVec2(-10.0f, 1.0f);
        bVec2 y;
        bVec2 deltaX = bVec2(0.5625f, 2.0f);
        bVec2 deltaY = bVec2(1.125f, 0.0f);

        for (int i = 0; i < 15; ++i) {
            y = x;

            for (int j = i; j < 15; ++j) {
                position = y;
                bd = new BodyDef(position, angle);
                sd = new PolyDef();
                a = 0.5f;
                sd.setAsBox(a, a);
                sd.density = 5.0f;
                rBody = world.createBody(bd);
                rBody.createShape(sd);
                rBody.setMassFromShapes();
                y += deltaY;
            }
            x += deltaX;
        }
    }
    void update() {}
}
