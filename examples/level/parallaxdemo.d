/*******************************************************************************
 *
 * Demonstration of the parallax module
 *
 ******************************************************************************/

module parallaxdemo;

import arc.game,
       arc.types,
	   arc.input;

import arc.x.level.parallax,
       arc.x.camera.camera;

class MyGame : Game
{
	this(char[] argT, Size argS, bool argFS)
	{
		super(argT, argS, argFS);

		// Create parallax
		parallax = new Parallax;

		// Create color that will act as the background
		// This is a light blue
		Color c = Color(0.0, 0.5, 1.0, 1.0);

		// Set background color
		parallax.setBackgroundColor(c);

		// Create a camera to keep track of the parallax offset
		cam = new Camera();

		// Note: This can throw an exception if the file is not found or could
		// not be loaded.
		// Store the index of the newly added later so that it can be accessed
		// later
		auto index = parallax.addLayer("testbin/parallax/forest.png");

		// Set the background to scroll at half the rate that the screen
		// coordinates change. Do not scroll vertically.
		parallax.setScrollOptions(index, true, 0.5, true, 0.2);

		// Tell the layer to repeat in the horizontal direction, but not in the
		// vertical.
		parallax.setRepeatOptions(index, true, false);

		// Add a second layer here.
		index = parallax.addLayer("testbin/parallax/forest.png");
		// Note that the scroll speed is 0.75 here. This means that this layer
		// will scroll more quickly than the one behind it. This is the key to
		// the parallax backgrounds' illusion of depth.
		parallax.setScrollOptions(index, true, 0.75, true, 0.2);
		parallax.setRepeatOptions(index, true, false);

	}

	void process()
	{
		// Adjust the camera coordinates based on user input.
		if(arc.input.keyDown(ARC_DOWN))
			yVel += 2;
		if(arc.input.keyDown(ARC_UP))
			yVel -= 2;
		if(arc.input.keyDown(ARC_RIGHT))
			xVel += 2;
		if(arc.input.keyDown(ARC_LEFT))
			xVel -= 2;

		// Constrain the speed of the camera
		xVel = max(min(maxVel, xVel), -maxVel);
		yVel = max(min(maxVel, yVel), -maxVel);

		// quick function for slowing the camera to a stop when no movement
		// keys are being pressed
		int dampenVelocity(int vel)
		{
			if(vel > 0)
				return vel - 1;
			else if(vel < 0)
				return vel + 1;
			else
				return vel;
		}

		xVel = dampenVelocity(xVel);
		yVel = dampenVelocity(yVel);

		// Apply camera motion here
		cam.moveRight(xVel);
		cam.moveDown(yVel);
		// Get the camera position
		Point p = cam.getPosition();


		// And draw the backgrounds to the screen using the camera position.
		parallax.drawAllLayers(cast(int)p.x, cast(int)p.y);

		/***********************************************************************
		 * IMPORTANT NOTE
		 *
		 * If you are using the parallax extension along with the camera
		 * extension, place the parallax drawing code OUTSIDE of the calls to
		 * cam.open and cam.close. Parallax has its own view transform logic
		 * that is by necessity incompatible with the camera.
		 *
		 * IMPORTANT NOTE
		 **********************************************************************/

		cam.process();
		cam.open();

		// Other drawing code goes here

		cam.close();
	}

	void shutdown()
	{
	}

	Parallax parallax;
	Camera cam;


	// Storage for camera velocity
	int xVel = 0;
	int yVel = 0;
	int maxVel = 10;
}

void main()
{
	Game g = new MyGame("Arclib Parallax Demo", Size.d1024x768, false);
	g.setFPS(60);
	g.loop();
}
