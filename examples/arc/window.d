module window;

import arc.window, 
		arc.math.point,
		arc.math.size, 
		arc.input,
		arc.texture, 
		arc.draw.image,
		arc.draw.shape,
		arc.draw.color; 

// main is just here to handle states
int main()
{
	// open window with specific settings
	arc.window.open("Arc Graphics Primitives", 640, 480, false);
	

	Texture t1 = Texture("testbin/penguin.png"); 
	Texture t2 = Texture("testbin/king.jpg"); 

	// main loop
	while (!arc.input.keyPressed(ARC_QUIT))
	{ 
		// clear the screen before drawing
		arc.window.clear();
		arc.input.process();

		drawPixel(arc.input.mousePos, Color.Red);

		drawCircle(arc.input.mousePos + Point(100,10),
					25, 20, Color.Red, false);

		drawLine(Point(0,0),arc.input.mousePos, Color.Blue);

		drawRectangle(arc.input.mousePos + Point(0,100),
				Size(50, 100), Color.Blue,true);

		drawImage(t1, arc.input.mousePos + Point(100,200),
				Size(50, 100), Point(0,0), 0, Color.White);

		drawImageTopLeft(t2, arc.input.mousePos + Point(200,300),
				Size(50, 100), Color.White);

		// flip to next screen
		arc.window.swap();

		if (arc.input.keyPressed('s'))
		{
			arc.window.screenshot("screen"); 
		}

        
        
		if (arc.input.keyPressed('t'))
		{
			arc.window.toggleFullScreen(); 
		}

		if (arc.input.keyPressed('a'))
		{
			arc.window.resize(200,200); 
		}

		if (arc.input.keyPressed('b'))
		{
			arc.window.resize(640,480); 
		}
		
	}

	// close window when done with it
	scope(exit)
	{
		arc.window.close();
	}
	
	return 0;
}
