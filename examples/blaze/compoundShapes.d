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
module compoundShapes;

import demo;

// TODO_ERIN test joints on compounds.
class CompoundShapes : Demo
{

    BodyDef bd;
    Body rBody;
    ShapeDef sd;

	this() {
        bVec2 gravity = bVec2(0.0f, -9.81f);
        super(gravity);
        init();
    }

    void init() {
		{
		    bVec2 position = bVec2(0.0f, -10.0f);
		    float angle = 0.0f;
			bd = new BodyDef(position, angle);
			rBody = world.createBody(bd);

			sd = new PolyDef();
			sd.setAsBox(50.0f, 10.0f);
			rBody.createShape(sd);
		}

		{
		    float radius = 0.5f;
            float density = 2.0f;
			auto sd1 = new CircleDef(density, radius);
			sd1.localPosition.set(-0.5f, 0.5f);

            density = 0.0f;
			auto sd2 = new CircleDef(density, radius);
			sd2.localPosition.set(0.5f, 0.5f);

			for (int i = 0; i < 10; ++i)
			{
				float x = randomRange(-0.1f, 0.1f);
				bVec2 position = bVec2(x + 5.0f, 1.05f + 2.5f * i);
				float angle = randomRange(-PI, PI);
				bd = new BodyDef(position, angle);
				rBody = world.createBody(bd);
				rBody.createShape(sd1);
				rBody.createShape(sd2);
				rBody.setMassFromShapes();
			}
		}

		{
			auto sd1 = new PolyDef();
			sd1.setAsBox(0.25f, 0.5f);
			sd1.density = 2.0f;

			auto sd2 = new PolyDef();
			sd2.setAsBox(0.25f, 0.5f, bVec2(0.0f, -0.5f), 0.5f * PI);
			sd2.density = 2.0f;

			for (int i = 0; i < 10; ++i)
			{
				float x = randomRange(-0.1f, 0.1f);
				bVec2 position = bVec2(x - 5.0f, 1.05f + 2.5f * i);
				float angle = randomRange(-PI, PI);
				bd = new BodyDef(position, angle);
				rBody = world.createBody(bd);
				rBody.createShape(sd1);
				rBody.createShape(sd2);
				rBody.setMassFromShapes();
			}
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
			sd1.density = 2.0f;

			bXForm xf2;
			xf2.R.set(-0.3524f * PI);
			xf2.position = bMul(xf2.R, bVec2(-1.0f, 0.0f));

			auto sd2 = new PolyDef();
			sd2.vertices.length = 3;
			sd2.vertices[0] = bMul(xf2, bVec2(-1.0f, 0.0f));
			sd2.vertices[1] = bMul(xf2, bVec2(1.0f, 0.0f));
			sd2.vertices[2] = bMul(xf2, bVec2(0.0f, 0.5f));
			sd2.density = 2.0f;

			for (int i = 0; i < 10; ++i)
			{
				float x = randomRange(-0.1f, 0.1f);
				bVec2 position = bVec2(x, 5.05f + 2.5f * i);
				float angle = 0.0f;
				bd = new BodyDef(position, angle);
				rBody = world.createBody(bd);
				rBody.createShape(sd1);
				rBody.createShape(sd2);
				rBody.setMassFromShapes();
			}
		}

		{
			auto sd_bottom = new PolyDef();
			sd_bottom.setAsBox( 1.5f, 0.15f );
			sd_bottom.density = 4.0f;

			auto sd_left = new PolyDef();
			sd_left.setAsBox(0.15f, 2.7f, bVec2(-1.45f, 2.35f), 0.2f);
			sd_left.density = 4.0f;

			auto sd_right = new PolyDef();;
			sd_right.setAsBox(0.15f, 2.7f, bVec2(1.45f, 2.35f), -0.2f);
			sd_right.density = 4.0f;

            bVec2 position = bVec2( 0.0f, 2.0f );
            float angle = 0.0f;
			bd = new BodyDef(position, angle);
			rBody = world.createBody(bd);
			rBody.createShape(sd_bottom);
			rBody.createShape(sd_left);
			rBody.createShape(sd_right);
			rBody.setMassFromShapes();
		}
	}
	void update() {}
}
