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
module testLineJoint;

import demo;

class TestLineJoint : Demo
{

    ShapeDef sd;
    BodyDef bd;
    PulleyJoint joint1;
	BodyDef rBody;

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
			sd = new PolyDef();
			sd.setAsBox(0.5f, 2.0f);
			sd.density = 1.0f;

            bVec2 position = bVec2(0.0f, 7.0f);
            float angle = 0.0f;
			bd = new BodyDef(position, angle);
			auto rBody = world.createBody(bd);
			rBody.createShape(sd);
			rBody.setMassFromShapes();

            bVec2 axis = bVec2(2.0f, 1.0f);
			axis.normalize();
			LineJointDef jd = new LineJointDef(ground, rBody, bVec2(0.0f, 8.5f), axis);
			jd.motorSpeed = 0.0f;
			jd.maxMotorForce = 100.0f;
			jd.enableMotor = true;
			jd.lowerTranslation = -4.0f;
			jd.upperTranslation = 4.0f;
			jd.enableLimit = true;
			world.createJoint(jd);
		}
	}

	void update() {}

}
