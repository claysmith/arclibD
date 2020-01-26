/*******************************************************************************

	Window module allows access to the game window.

	Authors:       ArcLib team, see AUTHORS file
	Maintainer:    Clay Smith (clayasaurus at gmail dot com)
	License:       zlib/libpng license: $(LICENSE)
	Copyright:     ArcLib team

	Description:
		Window allows opening and closing of window with user given parameters.
	Window also contains code to take a screenshot of itself, retrieve its
	dimensions, resize itself and alter its coordinate system.

	Examples:
	--------------------
	import arc.window;

	int main()
	{
		// initialize SDL/OpenGL window
		// read window parameters from a lua configuration file
		arc.window.open("Title", width, height, bFullScreen);

		// take a screenshot of current window and save it as a bitmap
		arc.window.screenshot("screen1");

		// toggle between full screen and window mode (linux only)
		arc.window.toggleFullScreen();

		// resize window with given width and height (currently texture information is lost on Windows)
		arc.window.resize(width, height)

		// get window's height and width
		arc.window.getHeight/getWidth;

		while (gameloop)
		{
			// clear contents of window
			arc.window.clear();

			// draw stuff to the screen

			// switch to next window frame
			arc.window.swap();
		}

		// closes the window
		arc.window.close();

	   return 0;
	}
	--------------------

*******************************************************************************/

module arc.window;

// Std lib imports
import
	tango.text.convert.Integer,
	tango.stdc.stringz,
	tango.stdc.stdlib,
	tango.stdc.string,
	tango.util.log.Log,
	tango.util.log.AppendFile,
	tango.io.FilePath;

// Arc imports
import
	arc.math.point,
	arc.math.rect,
	arc.types,
	arc.memory.routines;

// Derelict imports
import
	derelict.opengl.gl,
	derelict.opengl.glu,
	derelict.sdl.sdl,
	derelict.sdl.image,
	derelict.util.exception;

///	Opens a window with the given size and initializes OpenGL
public void open(char[] title_="ArcLib Application", int width_=800, int height_=600, bool f_=false, bool resizable_=false)
{
	initializeLogging();

	// Initialize window variables
	title = title_;
	width = width_;
	height = height_;
	fullscreen = f_;
	resizable = resizable_;

	// Create the window logger
	log = Log.getLogger("arc.window");

	// Log window creation message
	log.info("window: open(" ~ title ~ ", " ~ toString(width) ~ ", " ~ toString(height) ~ ", " ~ toString(fullscreen) ~ ")");

	// Loads Derelict Libraries needed by Arc at runtime
	loadDerelict();

	// Create the SDL window
	initializeSDL();

	// reinitialize viewport, projection etc. to fit the window
	resizeGL();

	// Default: set coordinate system to window coordinate system
	coordinates.setSize(Size(width_, height_));

	// log the Video Card Info
	debug printVendor();
}

///	Close SDL window and delete the screen
public void close()
{
	SDL_Quit();
	unloadDerelict();
}

/// Returns window width
public int getWidth() { return width; }

/// Returns window height
public int getHeight() { return height; }

/// returns window size
public Size getSize() { return Size(width, height); }

/// Returns true if window is fullscreen
public bool isFullScreen() { return fullscreen; }

/// get the window screen
public SDL_Surface* getScreen() { return screen; }

///	Resize window to desired width and height
public void resize(int argWidth, int argHeight)
{
	width = argWidth;
	height = argHeight;

	if (fullscreen)
		screen = SDL_SetVideoMode(argWidth, argHeight, bpp, SDL_OPENGL|SDL_HWPALETTE|SDL_FULLSCREEN|SDL_RESIZABLE);
	else
		screen = SDL_SetVideoMode(argWidth, argHeight, bpp, SDL_OPENGL|SDL_HWPALETTE|SDL_RESIZABLE);

	resizeGL();
}


///	Toggle between fullscreen and windowed mode; linux only
public void toggleFullScreen()
{
	if(SDL_WM_ToggleFullScreen(screen) == 0)
	{
			log.error("Window: Failed to toggle fullscreen");
			return;
	}

	fullscreen = !fullscreen;
}

/// Clear the screen
public void clear()
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

/// Swap the screen buffers and clear the screen
public void swap()
{
	SDL_GL_SwapBuffers();
}

/// Swap and clear the screen in one call, swap first, then clear
public void swapClear()
{
	SDL_GL_SwapBuffers();
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

///	Captures a screenshot and saves in BMP format to current directory
public void screenshot(char[] argName)
{
	SDL_Surface *image = null;
	SDL_Surface *temp = null;

	image = SDL_CreateRGBSurface(SDL_SWSURFACE, width, height, 24, 0x0000FF, 0x00FF00, 0xFF0000, 0);

	if(!(image is null))
	{
			temp  = SDL_CreateRGBSurface(SDL_SWSURFACE, width, height, 24, 0x0000FF, 0x00FF00, 0xFF0000, 0);

			if(!(temp is null))
			{
				glReadPixels(0, 0, width, height, GL_RGB, GL_UNSIGNED_BYTE, image.pixels);

				for (int idx = 0; idx < height; idx++)
				{
						char* dest = cast(char *)(temp.pixels+3*width*idx);
						memcpy(dest, cast(char *)(image.pixels+3*width*(height-1-idx)), 3*width);
						endianswap(dest, 3, width);
				}

				SDL_SaveBMP(temp, toStringz(argName ~ ".bmp"));
				SDL_FreeSurface(temp);
				log.info("screenshot " ~ argName ~ ".bmp taken");
			}

			SDL_FreeSurface(image);
	}
}


/***
	Offers functionality for dealing with the coordinate system.

	By default the origin (0,0) is in the top-left corner, x faces right, y down.
	By default, the bottom-right corner has the coordinates (800,600).

	This is mainly intended to allow the customization of the coordinate
	system at startup and on window resizes.

	It is not recommended to use this for scrolling: since these
	functions alter the global coordinate system, you will have no
	control over what scrolls and what doesn't. Use the scenegraph
	with a Transform node for selective scrolling.
**/
struct coordinates
{
	/// sets the virtual size of the screen
	static void setSize(Size argsize)
	{
		size = argsize;
		setupGLMatrices();
	}

	/// sets the coordinates for the top-left corner of the screen
	static void setOrigin(Point argorigin)
	{
		origin = argorigin;
		setupGLMatrices();
	}

	/// gets the virtual screen size
	static Size getSize() { return size; }
	/// gets the virtual screen width
	static arcfl getWidth() { return size.w; }
	/// gets the virtual screen height
	static arcfl getHeight() { return size.h; }
	/// gets the coordinates of the top-left corner of the screen
	static Point getOrigin() { return origin; }

private:
	static Size size;
	static Point origin;

	// setup the projection and modelview matrices
	static void setupGLMatrices()
	{
		// projection matrix
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(origin.x, origin.x + size.w, origin.y + size.h, origin.y, -1.0f, 1.0f);

		// modelview matrix
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
	}
}

/// Setup root logger to log to arc.log
void initializeLogging()
{
	// remove log file if it exists
	FilePath fp = new FilePath("arc.log");
	if (fp.exists())
		fp.remove();
	delete fp;

	// send new log to path
	Logger root = Log.root();
	root.add(new AppendFile("arc.log"));
}

///	Initialize SDL
private void initializeSDL()
{
	if(SDL_Init is null)
	{
		log.fatal("Window: SDL_Init is null");
		throw new Exception("Window: SDL_Init is null");
	}

	// initialize video
	if(SDL_Init(SDL_INIT_VIDEO) < 0)
	{
		log.fatal("Window: Failed to initialize SDL Video");
		throw new Exception("Window: Failed to initialize SDL Video");
	}

	// set pixel depth and format
	setupPixelDepth();
	setupPixelFormat();

	// open SDL window with given video flags
	screen = SDL_SetVideoMode(width, height, bpp,  buildVideoFlags());

	if (screen is null)
	{
		log.fatal("Window: screen is null after SDL_SetVideoMode called");
		throw new Exception("Window: screen is null after SDL_SetVideoMode called");
	}

	// set window caption, for some mysterious reason title info is lost if we don't do toUtfz
	SDL_WM_SetCaption(toStringz(title), null);
}

// Build video flags based on user configuration
Uint32 buildVideoFlags()
{
	// setup video flags
	Uint32 videoFlags = SDL_OPENGL|SDL_HWPALETTE;

	// if user wants screen resizable, set it
	if (resizable)
		videoFlags = videoFlags | SDL_RESIZABLE;

	// user wants fullscreen, set it
	if (fullscreen)
		videoFlags = videoFlags | SDL_FULLSCREEN;

	return videoFlags;
}

/***
	Query's SDL for the current video info (desktop), extracts bpp and sets
	bpp to what it found it was, this way the color depth is the color depth
	the user uses from the desktop, and it should not crash

*/
private void setupPixelDepth()
{
	SDL_VideoInfo *info = SDL_GetVideoInfo();

	if(info is null)
			throw new Exception("Window: SDL_GetVideoInfo() is null");

	bpp = info.vfmt.BitsPerPixel;
}

///	Prints a slew of graphics driver and extension debug info
debug private void printVendor()
{
	log.info("Render Type: OpenGL (Hardware)");
	log.info( "Vendor     : " ~ fromStringz(glGetString( GL_VENDOR )) ~ "\n");
	log.info( "Renderer   : " ~  fromStringz(glGetString( GL_RENDERER )) ~ "\n" );
	log.info( "Version    : " ~  fromStringz(glGetString( GL_VERSION )) ~ "\n" );
	log.info( "Extensions : " ~  fromStringz(glGetString( GL_EXTENSIONS )) ~ "\n" );
}

/***

	Derelict is a library that allows me to load all my library functions at
	run time, and displaying a proper message if any single library fails
	to load, a message like "Can't find library %s, go get it at %s"

**/
private void loadDerelict()
{
	try
	{
		Derelict_SetMissingProcCallback(&handleMissingOpenGL);
		DerelictGL.load();
		DerelictGLU.load();
		DerelictSDL.load();
		DerelictSDLImage.load();
		log.info("Derelict GL, GLU, SDL, and SDL_image successfully loaded");
	}
	catch (Exception e)
	{
		log.fatal("Failed to load Derelict GL, GLU, SDL, and SDL_image");
		log.fatal(e.toString());
		exit(1);
	}
}

// unload derelict
private void unloadDerelict()
{
	DerelictGL.unload();
	DerelictGLU.unload();
	DerelictSDL.unload();
	DerelictSDLImage.unload();
}

//	Sets up the pixel format the way we like it
private void setupPixelFormat()
{
   SDL_GL_SetAttribute( SDL_GL_RED_SIZE, 8 );
   SDL_GL_SetAttribute( SDL_GL_GREEN_SIZE, 8 );
   SDL_GL_SetAttribute( SDL_GL_BLUE_SIZE, 8 );
   SDL_GL_SetAttribute( SDL_GL_ALPHA_SIZE, 8 );
   SDL_GL_SetAttribute( SDL_GL_DEPTH_SIZE, 16 );
   SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );
}

/**
	Resizes the openGL viewport and reinitializes its matrices.
	Also resets GL states.
**/
private void resizeGL()
{
	// viewport
	glViewport(0,0, width, height);

	// reset the matrices
	coordinates.setupGLMatrices();

	// states
	setGLStates();
}

// initialize OpenGL parameters required to draw
private void setGLStates()
{
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glDisable(GL_DEPTH_TEST);
}

// skips trying to load glXGetProcAddress if it could not find it
private bool handleMissingOpenGL(char[] libName, char[] procName)
{
	/// Not used by ArcLib
	if(procName == "glXGetProcAddress")
		return true;

	return false;
}

///	Private vars we hide inside the module
private
{
	// window
	char[] title;
	int width, height, bpp=0;
	bool fullscreen = false;
	bool resizable = false;

	Logger log;

	// sdl
	SDL_Surface *screen = null;
}
