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
module blazeDemos;

import tango.io.Stdout;
import tango.stdc.stringz;
import tango.core.Array;
import Integer = tango.text.convert.Integer;

import derelict.opengl.gl;
import derelict.opengl.glu;
import derelict.sdl.sdl;

import demo;
import pyramid;
import dominos;
import fluiDemo;
import compoundShapes;
import pulleys;
import testSpring1;
import testSpring2;
import testAttractor;
import testRepulsor;
import testBungee1;
import testBungee2;
import testBuoyancy;
import testLineJoint;

/// Step size. Not tied to system timer in this demo
const char[] WINDOW_TITLE = "Blaze Demo - Press Keys 0-9, q-e To Switch Demos";

/// The main loop flag
bool running;
/// Display contacts and bounding boxes
bool drawDebugInfo;
/// Draw bounding box
bool boundingBox;
/// Body dragged by mouse
Body dragBody;
/// Mouse joint
MouseJoint mouse;
/// Demospace
Demo blazeDemo;
/// Mouse coordinates
bVec2 mousePos;
// Viewport boundaries
float left, top, right, bottom;

/** Sequential Impulse solver accuracy */
int velocityIterations;
int positionIterations;

// current time
uint startOfFrameTime = 0;
// previous time
uint prevStartOfFrameTime = 0;
// Frames per second
uint fps_ = 0;
// helpers for fps calculation
const uint FRAMERATE = 60;
uint frames = 0;
uint msPassed = 0;

/** Module constructor. */
static this() {

    // Load Derelict libraries
    DerelictGL.load();
    DerelictGLU.load();
    DerelictSDL.load();
    if (SDL_Init(SDL_INIT_VIDEO) < 0)
        throw new Exception("Failed to initialize SDL: " ~ getSDLError());
}

/// Module destructor
static ~this() {
    SDL_Quit();
}

int main(char[][] args) {

    createGLWindow(WINDOW_TITLE, SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_BPP, false);
    initGL(left, right, bottom, top);
    keyPressed('1');

    running = true;

    /** Physics steps per frame. */
    int steps = 5;
    /** Set the maximum frames per second */
    uint maxFps = 60;

    /**
     * Set solver accuracy. Fewer iterations are less accurate, but fast. You can get away with
     * fewer iterations by increasing the steps per frame... Experiment accordingly
     */
    velocityIterations = 3;
    positionIterations = 1;

    float timeStep = 1.0f / 60.0f;

    // Main Program Loop
    while (running) {

		// Clear The Screen And The Depth Buffer
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // Process time
		processTime();

        // Create fps caption
        char[] title = "Blaze Demo - Press Keys 0-9, q-e To Switch Demos - FPS: ";
        title  ~= Integer.format (new char[32], fps_);
        SDL_WM_SetCaption(toStringz(title), null);

        // Steps per frame
        for (int i = 0; i < steps; i++) {
            // Update world
            blazeDemo.world.step(timeStep, velocityIterations, positionIterations);
        }

		// Update demo
        blazeDemo.update();

        // Process user input
        processEvents();
        // Draw Scene
        drawScene();
        SDL_GL_SwapBuffers();

        // Limit the FPS
        limitFPS(maxFps);

        // Limit fps
        limitFPS(FRAMERATE);
    }

    return 0;
}

void processEvents() {
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        switch (event.type) {
        case SDL_KEYDOWN:
            keyPressed(event.key.keysym.sym);
            break;
        case SDL_KEYUP:
            keyReleased(event.key.keysym.sym);
            break;
        case SDL_QUIT:
            running = false;
            break;
        case SDL_MOUSEMOTION:
            screenToWorld(event.motion.x, event.motion.y);
            // Update mouse joint world position
            if (mouse) {
                mouse.setTarget(mousePos);
            }
            break;
        case SDL_MOUSEBUTTONDOWN:
            if (event.button.button == SDL_BUTTON_RIGHT) {
                blazeDemo.launchBomb();
            }
            if (event.button.button == SDL_BUTTON_LEFT) {
                mouseDown();
            }
            break;
        case SDL_MOUSEBUTTONUP:
            if (event.button.button == SDL_BUTTON_LEFT) {
                if (mouse) {
                    blazeDemo.world.destroyJoint(mouse);
                    mouse = null;
                    dragBody = null;
                }
            }
            break;
        default:
            break;
        }
    }
}

void screenToWorld(float x, float y) {

    float width = right - left;
    float height = top - bottom;
    float scaleX = width / SCREEN_HEIGHT;
    float scaleY = height / SCREEN_WIDTH;
    mousePos.x = left + x * scaleX;
    mousePos.y = bottom + abs(y - WINDOW_Y_TOP) * scaleY;
}

void mouseDown() {

    bVec2 p = mousePos;

    if (mouse) {
        return;
    }

    // Make a small box.
    AABB aabb;
    bVec2 d;
    d.set(0.001f, 0.001f);
    aabb.lowerBound = p - d;
    aabb.upperBound = p + d;

    // Query the world for overlapping shapes.
    Shape[] shapes;
    blazeDemo.world.query(aabb, shapes);
    Body rBody;
    for (int i = 0; i < shapes.length; ++i) {
        Body shapeBody = shapes[i].rBody;
        if(shapeBody is null) continue;
        if (!shapeBody.isStatic && shapeBody.mass > 0.0f) {
            bool inside = shapes[i].testPoint(shapeBody.xf, p);
            if (inside) {
                rBody = shapes[i].rBody;
                break;
            }
        }
    }

    if (rBody) {
        Body body1 = blazeDemo.world.groundBody;
        Body body2 = rBody;
        auto md = new MouseJointDef(body1, body2);
        md.target = p;
        md.maxForce = 1000 * rBody.mass;
        mouse = cast(MouseJoint) blazeDemo.world.createJoint(md);
        rBody.wakeup();
        dragBody = rBody;
    }
}

void keyReleased(int key) {
    switch (key) {
    case SDLK_ESCAPE:
        running = false;
        break;
    case SDLK_SPACE:
        drawDebugInfo = !drawDebugInfo;
        break;
    case SDLK_LEFT:
        blazeDemo.key = 0;
        break;
    case SDLK_RIGHT:
        blazeDemo.key = 0;
        break;
    default:
        break;
    }
}

void keyPressed(int key) {
    switch (key) {
    case SDLK_LEFT:
        blazeDemo.key = 1;
        break;
    case SDLK_RIGHT:
        blazeDemo.key = 2;
        break;
    case '1':
        Stdout("Initializing Domino...").newline;
        blazeDemo = new Dominos();
        defaultView();
        velocityIterations = 3;
        positionIterations = 1;
        break;
    case '2':
        Stdout("Initializing CompundShapes...").newline;
        blazeDemo = new CompoundShapes();
        defaultView();
        velocityIterations = 3;
        positionIterations = 1;
        break;
    case '3':
        Stdout("Initializing Pyramid...").newline;
        blazeDemo = new Pyramid();
        defaultView();
        velocityIterations = 20;
        positionIterations = 5;
        break;
    case '4':
        Stdout("Initializing Pulleys...").newline;
        blazeDemo = new Pulleys();
        defaultView();
        velocityIterations = 3;
        positionIterations = 1;
        break;
    case '5':
        Stdout("Initializing FluiDemo...").newline;
        blazeDemo = new FluiDemo();
        // Setup ortho boundaries
        left = 0;
        right = 10;
        bottom = 0;
        top = 10;
        resizeScene(left, right, bottom, top);
        velocityIterations = 3;
        positionIterations = 1;
        break;
	case '6':
        Stdout("Initializing Spring1...").newline;
        blazeDemo = new TestSpring1();
        defaultView();
        velocityIterations = 3;
        positionIterations = 1;
        break;
	case '7':
        Stdout("Initializing Spring2...").newline;
        blazeDemo = new TestSpring2();
        defaultView();
        velocityIterations = 3;
        positionIterations = 1;
        break;
	case '8':
        Stdout("Initializing Attractor...").newline;
        blazeDemo = new TestAttractor();
        defaultView();
        velocityIterations = 3;
        positionIterations = 1;
        break;
	case '9':
        Stdout("Initializing Repulsor...").newline;
        blazeDemo = new TestRepulsor();
        left = -30;
		right = 30;
		bottom = -1;
		top = 55;
        resizeScene(left, right, bottom, top);
        velocityIterations = 3;
        positionIterations = 1;
        break;
	case '0':
        Stdout("Initializing Bungee1...").newline;
        blazeDemo = new TestBungee1();
        defaultView();
        velocityIterations = 3;
        positionIterations = 1;
        break;
	case 'q':
        Stdout("Initializing Bungee2...").newline;
        blazeDemo = new TestBungee2();
        defaultView();
        velocityIterations = 3;
        positionIterations = 1;
        break;
	case 'w':
        Stdout("Initializing Buoyancy...").newline;
        blazeDemo = new TestBuoyancy();
        defaultView();
        velocityIterations = 10;
        positionIterations = 1;
        break;
    case 'e':
        Stdout("Initializing Line Joint...").newline;
        blazeDemo = new TestLineJoint();
        defaultView();
        velocityIterations = 10;
        positionIterations = 1;
        break;
    case 'b':
        boundingBox = !boundingBox;
        break;
    default:
        break;
    }
}

void defaultView() {
    // Setup ortho boundaries
    left = -15;
    right = 15;
    bottom = -1;
    top = 25;
    resizeScene(left, right, bottom, top);
}

// Resize And Initialize The GL Window
void resizeScene(float left, float right, float bottom, float top) {
    // Prevent A Divide By Zero By
    if (top == 0) {
        // Making Height Equal One
        top = 1;
    }

    glMatrixMode(GL_PROJECTION);
    // Reset The Projection Matrix
    glLoadIdentity();

    // Create Ortho View
    gluOrtho2D(left, right, bottom, top);

    // Select The Modelview Matrix
    glMatrixMode(GL_MODELVIEW);
    // Reset The Modelview Matrix
    glLoadIdentity();
}

void initGL(float left, float right, float bottom, float top) {
    glLoadIdentity();
    glMatrixMode(GL_PROJECTION);
    /// Use 2d Coordinate system
    gluOrtho2D(left, right, bottom, top);
    glMatrixMode(GL_MODELVIEW);
    glDisable(GL_DEPTH_TEST);
    glShadeModel(GL_SMOOTH);
    glEnable(GL_BLEND);
    glEnable(GL_POINT_SMOOTH);
    glEnable(GL_LINE_SMOOTH);
    glEnable(GL_POLYGON_SMOOTH);
    /// Black Background
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
    glLoadIdentity();
}

void drawScene() {

    //glLineWidth(2);

    // Draw dynamic Rigid Bodies
    for (Body rBody = blazeDemo.world.bodyList; rBody; rBody = rBody.next) {
        for (Shape shape = rBody.shapeList; shape; shape = shape.next) {
            // Red if dragging
            if (dragBody !is null && dragBody is rBody) glColor3f(1, 0, 0);
            // Green
            else glColor3f(0f, 1f, 0f);

            switch (shape.type) {
            case ShapeType.CIRCLE: // Circle
                auto circle = cast(Circle) shape;
                // Circle's world coordinates
                bVec2 c = circle.worldCenter;
                float r = circle.radius;
                int segs = 15;
                float coef = 2.0 * PI / segs;
				glBegin(GL_LINE_STRIP); {
					for (int n = 0; n <= segs; n++) {
						float rads = n * coef;
						glVertex2f(r * cos(rads + rBody.angle) + c.x, r * sin(rads + rBody.angle) + c.y);
					}
					glVertex2f(c.x, c.y);
				} glEnd();
				break;
            case ShapeType.POLYGON: // Polygon
                auto poly = cast(Polygon) shape;
                bVec2[] worldVertices = poly.worldVertices;
                glBegin(GL_LINE_LOOP);
                {
                    foreach (v; worldVertices) {
						glVertex2d(v.x, v.y);
					}
                }
                glEnd();
                break;
            default:
                break;
            }


            glLoadIdentity();
            glFlush();

            // Draw Bounding Box
            if (boundingBox) {
                glColor3f(255f, 255f, 255f);
                glBegin(GL_LINE_LOOP);
                {
                    glVertex2d(shape.aabb.upperBound.x, shape.aabb.upperBound.y);
                    glVertex2d(shape.aabb.upperBound.x, shape.aabb.lowerBound.y);
                    glVertex2d(shape.aabb.lowerBound.x, shape.aabb.lowerBound.y);
                    glVertex2d(shape.aabb.lowerBound.x, shape.aabb.upperBound.y);
                }
                glEnd();
                glLoadIdentity();
                glFlush();
            }
        }
    }

    // Draw Fluid Particles
    FluidParticle[] particles = blazeDemo.world.particles;
    foreach (particle; particles) {
        // Light blue
        glColor4f(0.5f, 0.5f, 1.0f, 0.2f);

        glEnable(GL_POINT_SMOOTH);
        glPointSize(6.0f);

        bVec2 pos = particle.position;
        glBegin(GL_POINTS);
        {
            glVertex2d(pos.x, pos.y);
        }
        glEnd();

        // Draw Bounding Box
        if (boundingBox) {
            glColor3f(255f, 255f, 255f);
            glBegin(GL_LINE_LOOP);
            {
                glVertex2d(particle.aabb.upperBound.x, particle.aabb.upperBound.y);
                glVertex2d(particle.aabb.upperBound.x, particle.aabb.lowerBound.y);
                glVertex2d(particle.aabb.lowerBound.x, particle.aabb.lowerBound.y);
                glVertex2d(particle.aabb.lowerBound.x, particle.aabb.upperBound.y);
            }
            glEnd();
            glLoadIdentity();
            glFlush();
        }
    }

    // Draw contact points for debugging purposes
    if (drawDebugInfo) {
        // Red
        glColor3f(1f, 0f, 0f);
        glPointSize(5f);
        glBegin(GL_POINTS);
        {
            foreach(a; blazeDemo.world.broadPhase.contactPool) {
                foreach(m; a.manifolds) {
                    for (int i = 0; i < m.pointCount; i++) {
                        bVec2 point1 = bMul(a.shape1.rBody.xf, m.points[i].localPoint1);
                        bVec2 point2 = bMul(a.shape2.rBody.xf, m.points[i].localPoint2);
                        glVertex2d(point1.x, point1.y);
                        glVertex2d(point2.x, point2.y);
                    }
                }
            }
        }
        glEnd();
    }
}

void createGLWindow(char[] title, int width, int height, int bits, bool fullScreen) {
    SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 5);
    SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 6);
    SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 5);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

    SDL_WM_SetCaption(toStringz(title), null);

    int mode = SDL_OPENGL;
    if (fullScreen) mode |= SDL_FULLSCREEN;

    if (SDL_SetVideoMode(width, height, bits, mode) is null)
        throw new Exception("Failed to open OpenGL window: " ~ getSDLError());
}

char[] getSDLError() {
    return fromStringz(SDL_GetError());
}

// Code to keep frame rate constant
/**
   	Calculates fps and captures start of frame time.
   	Call at the start of the frame loop.
 **/
void processTime()
{
	if (startOfFrameTime == 0) {
		startOfFrameTime = SDL_GetTicks();
		prevStartOfFrameTime = startOfFrameTime - 1;
	}

	prevStartOfFrameTime = startOfFrameTime;
	startOfFrameTime = SDL_GetTicks();

	frames++;

	msPassed += (startOfFrameTime - prevStartOfFrameTime);

	if (msPassed > 1000) {
		fps_ = frames;
		frames = 0;
		msPassed = 0;
	}
}

/**
   	Call at the end of the frame loop in order to limit the
   	fps to a certain amount.
 **/
void limitFPS(uint maxFps)
{
	int targetMsPerFrame = 1000 / maxFps;
	uint cTime = SDL_GetTicks();

	int sleepAmount = targetMsPerFrame - (cTime - startOfFrameTime);

	if (sleepAmount <= 0)
		return;

	SDL_Delay(sleepAmount);
}
