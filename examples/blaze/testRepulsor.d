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
module testRepulsor;

import demo;

class TestRepulsor : Demo
{

    ShapeDef sd;
    BodyDef bd;

	this() {
        bVec2 gravity = bVec2(0.0f, -5.0f);
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
			// Create attractor force
			bVec2 center = bVec2(0, 13);
			float minRadius = 3;
			float maxRadius = 15;
			float strength = 500;
			ForceGenerator repulsor;

			// Create circle
			bVec2 position = center;
			float angle = 0.0f;
			bd = new BodyDef(position, angle);
			auto rBody = world.createBody(bd);
			float radius = 1.0f;
			float density = 7.5f;
			sd = new CircleDef(density, radius);
			float friction = 1.0f;
			float restitution = 0.1f;
			sd.friction = friction;
			sd.restitution = restitution;
			rBody.createShape(sd);

			// Create shapes
			for(int i = 0; i < 50; i++) {
				// Define shape
				float a = randomRange(0.075f, 0.5f);
				float b = randomRange(0.075f, 0.5f);
				float xPos = randomRange(-10, 10f);
				float yPos = randomRange(5.0f, 25.0f);

				sd = new PolyDef();
				sd.setAsBox(a, b);
				sd.density = 5.0f;

				// Create body1
				position = bVec2(xPos, yPos);
				bd = new BodyDef(position, angle);
				rBody = world.createBody(bd);
				rBody.createShape(sd);
				rBody.setMassFromShapes();

                repulsor = new Repulsor(rBody, center, strength, minRadius, maxRadius);
				world.addForce(repulsor);
			}

		}
	}

	void update() {}
}

