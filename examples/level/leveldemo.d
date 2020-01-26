/*******************************************************************************
 *
 * Demonstration of the level module
 *
 ******************************************************************************/

module leveldemo;

import tango.io.Stdout;

import arc.game,
       arc.types,
	   arc.input;

import arc.x.camera.camera,
       arc.x.level.tilemap,
       arc.x.level.parallax,
	   arc.x.level.level;


class MyGame: Game
{
	this(char[] argT, Size argS, bool argFS)
	{
		super(argT, argS, argFS);

		// Setup the camera
		cam = new Camera();
		cam.setPosition(Point(0, 0));

		auto level = loadFromJSON("level.json", "testbin");

		parallax = level.parallax;
		tilemap = level.map;
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
				return 0;
		}

		xVel = dampenVelocity(xVel);
		yVel = dampenVelocity(yVel);

		// Apply camera motion here
		cam.moveRight(xVel);
		cam.moveDown(yVel);

		// Get the camera position
		Point p = cam.getPosition();

		// Draw the Parallax
		if(parallax !is null)
			parallax.drawAllLayers(cast(int)p.x, cast(int)p.y);

		cam.process();
		cam.open();

		// Tell the map what the coordinates of the top-left of the visible
		// screen area are. This way it can only draw tiles that are visible.
		if(tilemap !is null)
			tilemap.drawAllLayers(cast(int)p.x, cast(int)p.y);
		else
			Stderr.formatln("Tilemap is null");

		cam.close();
	}

	void shutdown()
	{
	}

	TileMap tilemap;
	Parallax parallax;
	Camera cam;

	// Storage for camera velocity
	int xVel = 0;
	int yVel = 0;
	int maxVel = 10;
}

void main()
{
	Game g = new MyGame("Arclib Level Demo", Size.d640x480, false);
	g.setFPS(60);
	g.loop();
}
