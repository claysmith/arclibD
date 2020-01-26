/*
* Copyright (c) 2007 Erin Catto http://www.gphysics.com
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
module pulleys;

import demo;

class Pulleys : Demo
{

    ShapeDef sd;
    BodyDef bd;
    PulleyJoint joint1;

	this() {
        bVec2 gravity = bVec2(0.0f, -9.81f);
        super(gravity);
        init();
    }

    void init() {

		Body ground;
		{
			sd = new PolyDef();
			sd.setAsBox(50.0f, 10.0f);

            bVec2 position = bVec2(0.0f, -10.0f);
            float angle = 0.0f;
            bd = new BodyDef(position, angle);
			ground = world.createBody(bd);
			ground.createShape(sd);
		}

		{
			float a = 1.0f;
			float b = 2.0f;
			float y = 10.0f;
			float L = 12.0f;

			sd = new PolyDef();
			sd.setAsBox(a, b);
			sd.density = 5.0f;

            bVec2 position = bVec2(-10.0f, y);
            float angle = 0.0f;
			bd = new BodyDef(position, angle);
			Body body1 = world.createBody(bd);
			body1.createShape(sd);
			body1.setMassFromShapes();

			bd.position.set(10.0f, y);
			Body body2 = world.createBody(bd);
			body2.createShape(sd);
			body2.setMassFromShapes();

			bVec2 anchor1 = bVec2(-10.0f, y + b);
			bVec2 anchor2 = bVec2(10.0f, y + b);
			bVec2 groundAnchor1 = bVec2(-10.0f, y + b + L);
			bVec2 groundAnchor2 = bVec2(10.0f, y + b + L);
			auto pulleyDef = new PulleyJointDef(body1, body2, groundAnchor1, groundAnchor2, anchor1, anchor2, 2.0f);
			joint1 = cast(PulleyJoint) world.createJoint(pulleyDef);
		}
	}

	void update() {}

}
