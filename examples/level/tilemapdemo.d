/*******************************************************************************
 *
 * Demonstration of the tilemap module
 *
 ******************************************************************************/

module tilemapdemo;

import arc.game,
       arc.types,
	   arc.input;

import arc.x.level.tilemap;
import arc.x.camera.camera;


class MyGame: Game
{
	this(char[] argT, Size argS, bool argFS)
	{
		super(argT, argS, argFS);


		// Setup the camera
		cam = new Camera();

		// create a new TileMap with width 20, height 25, 1 layer, and a
		// tile size of 32 pixels
		tilemap = new TileMap(20, 25, 1, 32);

		// Add a tile image to the map. This function returns the index of the
		// added image for later use. (You can also specify an index if you
		// wish)
		auto tilesetIndex = tilemap.addTileSet(
			"testbin/tiles/free_tileset_version_10.png");

		// Add some tiles. This is a basic loop that keeps the map in the same
		// arrangement that they're in on the tile sheet itself.
		for(int x = 0; x != 10; ++x)
		{
			for(int y = 0; y != 10; ++y)
			{
				tilemap.addTile(x, y, 0, x, y, tilesetIndex);
			}
		}
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

		// Test out the tile delete function. This can't be undone.
		if (arc.input.keyPressed(ARC_DELETE))
			tilemap.removeTile(1, 0, 0);

		// Toggle the visibility of a tile
		if(arc.input.keyPressed(ARC_HOME))
			tilemap.toggleTileVisibility(2, 0, 0);

		// Set the tile visible
		if(arc.input.keyPressed(ARC_PAGEUP))
			tilemap.setTileVisibility(2, 0, 0, true);

		// Set the tile invisible
		if(arc.input.keyPressed(ARC_PAGEDOWN))
			tilemap.setTileVisibility(2, 0, 0, false);

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

		cam.process();
		cam.open();

		// Tell the map what the coordinates of the top-left of the visible
		// screen area are. This way it can only draw tiles that are visible.
		tilemap.drawAllLayers(cast(int)p.x, cast(int)p.y);

		cam.close();
	}

	void shutdown()
	{
	}

	// the tile map
	TileMap tilemap;
	// the camera
	Camera cam;

	// Storage for camera velocity
	int xVel = 0;
	int yVel = 0;
	int maxVel = 10;
}

void main()
{
	Game g = new MyGame("Arclib Tilemap Demo", Size.d640x480, false);
	g.setFPS(60);
	g.loop();
}
