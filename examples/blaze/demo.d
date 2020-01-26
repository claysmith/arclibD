/*******************************************************************************

   	Authors: Blaze team, see AUTHORS file
   	Maintainers: Mason Green (zzzzrrr) and Clay Smith (clayasaurus)
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
module demo;

public import arc.x.blaze.all;
import tango.core.Array;
import tango.math.random.Kiss;


//The screen attributes
const SCREEN_WIDTH = 600;
const SCREEN_HEIGHT = 600;
const SCREEN_BPP = 32;

//Window Attributes
const WINDOW_X_LEFT = 0;
const WINDOW_X_RIGHT = 600;
const WINDOW_Y_BOTTOM = 0;
const WINDOW_Y_TOP = 600;


class Demo {

    World world;
    int key;
    Body bomb;

    this(bVec2 gravity) {
        // Do we want to let bodies sleep?
        bool doSleep = true;
        // Create world space
        world = new World(gravity, doSleep);
    }

    public static float randomRange(float a, float b) {
        return a + Kiss.instance.toInt() % (b + 1 - a);
    }

    static float deg2rad(float deg) {
        return deg * PI / 180.0f;
    }

    void launchBomb() {
        bVec2 p = bVec2(randomRange(-15.0f, 15.0f), 30.0f);
        bVec2 v = -5.0f * p;
        launchBomb(p, v);
    }

    void launchBomb(bVec2 position, bVec2 velocity) {
        if (bomb) {
            world.destroyBody(bomb);
            bomb = null;
        }

        float angle = 0.0f;
        auto bd = new BodyDef(position, angle);
        bd.allowSleep = true;
        bd.isBullet = true;
        bomb = world.createBody(bd);
        bomb.linearVelocity = velocity;

        float radius = 0.3f;
        float density = 20.0f;
        auto sd = new CircleDef(density, radius);
        sd.restitution = 0.1f;

        bVec2 minV = position - bVec2(0.3f,0.3f);
        bVec2 maxV = position + bVec2(0.3f,0.3f);

        bomb.createShape(sd);
        bomb.setMassFromShapes();
    }

    abstract void update();
}
