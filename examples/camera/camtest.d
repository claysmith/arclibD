import 	
	arc.window, 
	arc.input,
	arc.texture, 
	arc.math.point,
	arc.math.size, 
	arc.draw.image,
	arc.draw.shape,
	arc.draw.color,
	arc.time, 
	arc.x.camera.camera; 

// main is just here to handle states
int main()
{
	// open window with specific settings
	arc.window.open("Arc Graphics Primitives", 640, 480, false);

	Texture t1 = Texture("testbin/penguin.png"); 
	Texture t2 = Texture("testbin/penguin.png"); 

	Camera cam = new Camera();
	Point pos = Point(100,100); 
	
	// set position of camera
	cam.setPosition(Point(200,200)); 
	cam.setProjection(0,480,640,0); 
	
	// main loop
	while (!arc.input.keyPressed(ARC_QUIT))
	{ 
		// clear the screen before drawing
		arc.window.clear();
		arc.input.process();
		arc.time.process(); 
		
		cam.process(); 
		cam.open(); 

		float val = 1;
		if (arc.input.keyDown(ARC_LEFT))
		{
			cam.moveLeft(val);
		}
		if (arc.input.keyDown(ARC_RIGHT))
		{
			cam.moveRight(val); 
		}
		if (arc.input.keyDown(ARC_UP))
		{
			// if we don't specify value, it will default to one
			cam.moveUp(); 
		}
		if (arc.input.keyDown(ARC_DOWN))
		{
			cam.moveDown(val); 
		}
		
		// we can set and get zoom
		//cam.setZoom(cam.getZoom); 
		
		// we can zoom in and out if we want to 
		if (arc.input.keyDown(ARC_a))
		{
			cam.zoomIn(.1); 
		}
		if (arc.input.keyDown(ARC_z))
		{
			// can insert value if you want to 
			cam.zoomOut(.1); 
		}

		drawPixel(pos, Color.Red);

		drawCircle(pos + Point(100, 10),
					25, 20, Color.Red, false);

		drawLine(Point(0,0), pos, Color.Blue);

		drawRectangle(pos + Point(0,100),
				Size(50, 100), Color.Blue,true);

		drawImage(t1, pos + Point(100,200),
				Size(50, 100), Point(0,0), 0, Color.White);

		drawImageTopLeft(t2, pos + Point(200,300));

		cam.close(); 

		// flip to next screen
		arc.window.swap();
		arc.time.limitFPS(60); 
	}

	t1.freeSDLSurface(); 
	t2.freeSDLSurface(); 
    
	// close window when done with it
	scope(exit)
	{
		arc.window.close();
	}
	
	return 0;
}
