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
module testBuoyancy;

import derelict.opengl.gl;

import demo;

class TestBuoyancy : Demo
{

    ShapeDef sd;
    BodyDef bd;
	float planeOffset;

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

            // Turn off sleeping when using the buoyancy solver.
            // Otherwise you will get innacurate results.
            world.allowSleep = false;
		}

            // Water line
			planeOffset = 8;
            // Buoyancy force normal
			bVec2 upVector = bVec2(0, -1);
			// Water @ 20.6 celcius (kg/m^3)
			float waterDensity = 998.09;
			// Linear drag
			float linDrag = 5.0f;
			// Angular drag
			float angDrag = 0.5f;

            ForceGenerator buoyancy;

			// Define shape
			float a = 1.0f;
			float b = 2.0f;
			float y = 20.0f;
			float L = 12.0f;

			sd = new PolyDef();
			sd.setAsBox(a, b);
            sd.friction = 0.25f;
			// Redwood (American) - (kg/m^3)
			sd.density = 450.0f;

        {
			// Create body1
            bVec2 position = bVec2(0, 8.0);
            float angle = 1.5f;
			bd = new BodyDef(position, angle);
			auto body1 = world.createBody(bd);
			body1.createShape(sd);
			body1.setMassFromShapes();

			// Create body2
            position = bVec2(10.0f, y);
            angle = 0.25f;
			bd = new BodyDef(position, angle);
			auto body2 = world.createBody(bd);
			body2.createShape(sd);
			body2.setMassFromShapes();

           // Add buoyancy to boxes
            buoyancy = new Buoyancy(body1, planeOffset, upVector, waterDensity, linDrag, angDrag);
			world.addForce(buoyancy);
			buoyancy = new Buoyancy(body2, planeOffset, upVector, waterDensity, linDrag, angDrag);
			world.addForce(buoyancy);

        }

        {
			// Create circle

			bVec2 position = bVec2(0.0f, y+2);
			float angle = 0.0f;
			bd = new BodyDef(position, angle);
			auto rBody = world.createBody(bd);
			float radius = 1.1f;
            float density = 650.0f;
			sd = new CircleDef(density, radius);
			sd.friction = 0.75f;
			rBody.createShape(sd);
			rBody.setMassFromShapes();

            // Add buoyancy to circle
            buoyancy = new Buoyancy(rBody, planeOffset, upVector, waterDensity, linDrag, angDrag);
			world.addForce(buoyancy);
        }

        {
			bXForm xf1;
			xf1.R.set(0.3524f * PI);
			xf1.position = bMul(xf1.R, bVec2(1.0f, 0.0f));

			auto sd1 = new PolyDef();
			sd1.vertices.length = 3;
			sd1.vertices[0] = bMul(xf1, bVec2(-1.0f, 0.0f));
			sd1.vertices[1] = bMul(xf1, bVec2(1.0f, 0.0f));
			sd1.vertices[2] = bMul(xf1, bVec2(0.0f, 0.5f));
			sd1.density = 750.0f;

			bXForm xf2;
			xf2.R.set(-0.3524f * PI);
			xf2.position = bMul(xf2.R, bVec2(-1.0f, 0.0f));

			auto sd2 = new PolyDef();
			sd2.vertices.length = 3;
			sd2.vertices[0] = bMul(xf2, bVec2(-1.0f, 0.0f));
			sd2.vertices[1] = bMul(xf2, bVec2(1.0f, 0.0f));
			sd2.vertices[2] = bMul(xf2, bVec2(0.0f, 0.5f));
			sd2.density = 750.0f;

			for (int i = 0; i < 5; ++i)
			{
				float x = randomRange(-0.1f, 0.1f);
				bVec2 position = bVec2(x, 5.05f + 2.5f * i);
				float angle = 0.0f;
				bd = new BodyDef(position, angle);
				auto rBody = world.createBody(bd);
				rBody.createShape(sd1);
				rBody.createShape(sd2);
				rBody.setMassFromShapes();
				buoyancy = new Buoyancy(rBody, planeOffset, upVector, waterDensity, linDrag, angDrag);
                world.addForce(buoyancy);
			}
		}

	}

	void update() {

        // Green
        glColor3f(0f, 1f, 0f);

		glBegin(GL_LINES);
            glVertex2f(-15, planeOffset);
            glVertex2f(15, planeOffset);
        glEnd();

		/*
        for (Shape shape = body1.shapeList; shape; shape = shape.next) {
			glBegin(GL_LINE_LOOP);
				bTri2[] triList = shape.triangleList;
				foreach (t; triList) {
					glVertex2d(t.a.x, t.a.y);
					glVertex2d(t.b.x, t.b.y);
					glVertex2d(t.c.x, t.c.y);
				}
			glEnd();
		}
		*/

	}

}
