/*
* Copyright (c) 2006-2008 Erin Catto http://www.gphysics.com
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
module dominos;

import demo;

class Dominos : Demo {
public:

    this() {
        bVec2 gravity = bVec2(0.0f, -9.81f);
        super(gravity);
        init();
    }

    void init() {

        Body b1;
        {
            auto sd = new PolyDef();
            sd.friction = 0.1f;
            sd.setAsBox(50.0f, 10.0f);

            bVec2 position = bVec2(0.0f, -10.0f);
            float angle = 0.0f;
            auto bd = new BodyDef(position, angle);

            b1 = world.createBody(bd);
            b1.createShape(sd);
        }

        {
            auto sd = new PolyDef();
            sd.friction = 0.1;
            sd.setAsBox(6.0f, 0.25f);

            bVec2 position = bVec2(-1.5f, 10.0f);
            float angle = 0.0f;
            auto bd = new BodyDef(position, angle);
            auto ground = world.createBody(bd);
            ground.createShape(sd);
        }

        {
            auto sd = new PolyDef();
            sd.setAsBox(0.1f, 1.0f);
            sd.density = 20.0f;
            sd.friction = 0.15f;

            for (int i = 0; i < 10; ++i) {
                bVec2 position = bVec2(-6.0f + 1.0f * i, 11.25f);
                float angle = 0.0f;
                auto bd = new BodyDef(position, angle);
                auto rBody = world.createBody(bd);
                rBody.createShape(sd);
                rBody.setMassFromShapes();
            }
        }

        {
            auto sd = new PolyDef();
            sd.friction = 0.1f;
            sd.setAsBox(7.0f, 0.25f, bVec2.zeroVect, 0.3f);

            bVec2 position = bVec2(1.0f, 6.0f);
            float angle = 0.0f;
            auto bd = new BodyDef(position, angle);
            auto ground = world.createBody(bd);
            ground.createShape(sd);
        }

        Body b2;
        {
            auto sd = new PolyDef();
            sd.friction = 0.1f;
            sd.setAsBox(0.25f, 1.5f);

            bVec2 position = bVec2(-7.0f, 4.0f);
            float angle = 0.0f;
            auto bd = new BodyDef(position, angle);
            b2 = world.createBody(bd);
            b2.createShape(sd);
        }

        Body b3;
        {
            auto sd = new PolyDef();
            sd.friction = 0.1f;
            sd.setAsBox(6.0f, 0.125f);
            sd.density = 10.0f;

            bVec2 position = bVec2(-0.9f, 1.0f);
            float angle = -0.15f;
            auto bd = new BodyDef(position, angle);

            b3 = world.createBody(bd);
            b3.createShape(sd);
            b3.setMassFromShapes();
        }

        bVec2 anchor = bVec2(-2.0f, 1.0f);
        auto jd = new RevoluteJointDef(b1, b3, anchor);
        jd.collideConnected = true;
        world.createJoint(jd);

        Body b4;
        {
            auto sd = new PolyDef();
            sd.setAsBox(0.25f, 0.25f);
            sd.density = 10.0f;
            sd.friction = 0.1f;

            bVec2 position = bVec2(-10.0f, 15.0f);
            float angle = 0.0f;
            auto bd = new BodyDef(position, angle);
            b4 = world.createBody(bd);
            b4.createShape(sd);
            b4.setMassFromShapes();
        }

        anchor.set(-7.0f, 15.0f);
        jd = new RevoluteJointDef(b2, b4, anchor);
        world.createJoint(jd);

        Body b5;
        {
            bVec2 position = bVec2(6.5f, 3.0f);
            float angle = 0.0f;
            auto bd = new BodyDef(position, angle);
            b5 = world.createBody(bd);

            auto sd = new PolyDef();
            sd.density = 10.0f;
            sd.friction = 0.1f;

            sd.setAsBox(1.0f, 0.1f, bVec2(0.0f, -0.9f), 0.0f);
            b5.createShape(sd);

            sd.setAsBox(0.1f, 1.0f, bVec2(-0.9f, 0.0f), 0.0f);
            b5.createShape(sd);

            sd.setAsBox(0.1f, 1.0f, bVec2(0.9f, 0.0f), 0.0f);
            b5.createShape(sd);

            b5.setMassFromShapes();
        }

        anchor.set(6.0f, 2.0f);
        jd = new RevoluteJointDef(b1, b5, anchor);
        world.createJoint(jd);

        Body b6;
        {
            auto sd = new PolyDef();
            sd.setAsBox(1.0f, 0.1f);
            sd.density = 30.0f;
            sd.friction = 0.2f;

            bVec2 position = bVec2(6.5f, 4.1f);
            float angle = 0.0f;
            auto bd = new BodyDef(position, angle);
            b6 = world.createBody(bd);
            b6.createShape(sd);
            b6.setMassFromShapes();
        }

        anchor.set(7.5f, 4.0f);
        jd = new RevoluteJointDef(b5, b6, anchor);
        world.createJoint(jd);

        Body b7;
        {
            auto sd = new PolyDef();
            sd.setAsBox(0.1f, 1.0f);
            sd.friction = 0.1f;
            sd.density = 10.0f;

            bVec2 position = bVec2(7.4f, 1.0f);
            float angle = 0.0f;
            auto bd = new BodyDef(position, angle);

            b7 = world.createBody(bd);
            b7.createShape(sd);
            b7.setMassFromShapes();
        }

        bVec2 anchor1 = bVec2(6.0f, 0.0f);
        bVec2 anchor2 = bVec2(0.0f, -1.0f);
        auto djd = new DistanceJointDef(b3, b7, anchor1, anchor2);
        bVec2 d = djd.body2.worldPoint(djd.localAnchor2) - djd.body1.worldPoint(djd.localAnchor1);
        djd.length = d.length;
        world.createJoint(djd);

        {
            float radius = 0.2f;
            float density = 10.0f;
            auto sd = new CircleDef(density, radius);

            for (int i = 0; i < 4; ++i) {
                bVec2 position = bVec2(5.9f + 2.0f * sd.radius * i, 2.4f);
                float angle = 0.0f;
                auto bd = new BodyDef(position, angle);
                auto rBody = world.createBody(bd);
                rBody.createShape(sd);
                rBody.setMassFromShapes();
            }
        }
    }
    void update() {}
}
