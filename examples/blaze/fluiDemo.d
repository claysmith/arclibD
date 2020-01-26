/*******************************************************************************

   	Authors: Blaze team, see AUTHORS file
   	Maintainers: Mason Green (zzzzrrr)
   	License:
   		zlib/png license

   		This software is provided 'as-is', without any express or implied
   		warranty. In no event will the authors be held liable for any damages
   		arising from the use of this software.

   		Permission is granted to anyone to use this software for any purpose,
   		including commercial applications, and to alter it and redistribute it
   		freely, subject to the following restrictions:

   			1. The origin of this software must not be misrepresented; you must not
   			claim that you wrote the original software. If you use this software
   			in a product, an acknowledgment in the product documentation would be
   			appreciated but is not required.

   			2. Altered source versions must be plainly marked as such, and must not be
   			misrepresented as being the original software.

   			3. This notice may not be removed or altered from any source
   			distribution.

   	Copyright: 2008, Blaze Team

*******************************************************************************/
module fluiDemo;

import tango.time.StopWatch;

import demo;

/**
 * NOTE - It is highly suggested that you use Meters-Kilogram-Seconds
 * (MKS) units. Pay attention to your mass, friction, and restitution
 * values. SPH requires fine tuning.
 */
class FluiDemo : Demo {

    /** The particle field gravity */
    bVec2 gravityForce;
    /** Max number of particles */
    const MAX_PARTICLES = 500;
    /** Grid cell space */
    float cellSpace;
    /** Timer */
    StopWatch elapsed;
    /**  restitution */
    float restitution = 0.1f;
    /** Friction coefficient */
    float friction = 0.75f;
    /** Max particle flag */
    bool full;

    this() {
        bVec2 gravity = bVec2(0.0f, -9.81f);
        super(gravity);
        init();
        elapsed.start;
    }

    void init() {

        BodyDef bd;
        ShapeDef sd;
        Body rBody;
        bVec2 position;
        float angle;

        // Create house
        position = bVec2(5.50, 1.5);
        angle = 0.0f;
        bd = new BodyDef(position, angle);
        rBody = world.createBody(bd);
        sd = new PolyDef();
        sd.friction = friction;
        sd.restitution = restitution;
        sd.setAsBox(0.75, 1.0);
        sd.density = 10;
        rBody.createShape(sd);
        rBody.setMassFromShapes();

        // Create right roof
        position = bVec2(5.5, 4.1);
        bd = new BodyDef(position, angle);
        rBody = world.createBody(bd);
        float density = 20;
        bVec2[] bodyVertex;
        bodyVertex ~= bVec2(0.5f, -0.275);
        bodyVertex ~= bVec2(-0.25f, 0.25);
        bodyVertex ~= bVec2(-0.25f, -0.275);
        sd = new PolyDef(density, bodyVertex);
        sd.friction = friction;
        sd.restitution = restitution;
        rBody.createShape(sd);
        rBody.setMassFromShapes();

        // Create left roof
        position = bVec2(5.5, 4.1);
        bd = new BodyDef(position, angle);
        rBody = world.createBody(bd);
        bodyVertex = null;
        bodyVertex ~= bVec2(0.25f, -0.275f);
        bodyVertex ~= bVec2(0.25f, 0.25f);
        bodyVertex ~= bVec2(-0.5f, -0.275f);
        sd = new PolyDef(density, bodyVertex);
        sd.friction = friction;
        sd.restitution = restitution;
        rBody.createShape(sd);
        rBody.setMassFromShapes();

        // Create ball
        position = bVec2(3.0, 3.0);
        bd = new BodyDef(position, angle);
        rBody = world.createBody(bd);
        float radius = 0.3f;
        density = 7.5f;
        sd = new CircleDef(density, radius);
        sd.friction = friction;
        sd.restitution = restitution;
        rBody.createShape(sd);
        rBody.setMassFromShapes();

        // Create floor
        position = bVec2.zeroVect;
        bd = new BodyDef(position, angle);
        auto floor = world.createBody(bd);
        sd = new PolyDef();
        sd.setAsBox(30,0.5);
        sd.friction = friction;
        floor.createShape(sd);

        // Create left wall
        position = bVec2(0, 0.5f);
        bd = new BodyDef(position, angle);
        auto leftWall = world.createBody(bd);
        sd = new PolyDef();
        sd.setAsBox(0.5, 6);
        sd.friction = friction;
        leftWall.createShape(sd);

        // Create right wall
        position = bVec2(10.0f, 0.5f);
        bd = new BodyDef(position, angle);
        auto rightWall = world.createBody(bd);
        sd = new PolyDef();
        sd.setAsBox(0.5, 6);
        sd.friction = friction;
        rightWall.createShape(sd);
    }

    void update() {
        // Create a fluid particle shower
        if (elapsed.microsec > 8e4 && !full) {
            // Stop the timer
            elapsed.stop;
            // Create particle
            restitution = 0.01f;
            friction = 0.5f;
            float x = randomRange(4.0, 5.0);
            bVec2 position = bVec2(x, 6.0);
            auto particle = new FluidParticle(position, restitution, friction);
            float fx = randomRange(-300, 300);
            particle.force += bVec2(fx, 0.0f);
            world.addFluidParticle(particle);
            // Reset timer
            elapsed.start;
            if( world.sph.numParticles > MAX_PARTICLES) full = true;
        }
    }
}

