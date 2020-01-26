module texture;

import 	
	arc.window, 
	arc.math.point,
	arc.math.size, 
	arc.input,
	arc.texture, 
	arc.draw.image,
	arc.draw.color; 

// main is just here to handle states
int main()
{
	// open window with specific settings
	arc.window.open("Arc Texture Unittest", 640, 480, false);

	Texture t1 = Texture("testbin/penguin.png"); 
	Texture t2 = Texture("testbin/king.jpg"); 
	
	// this should load up as 'old' 
	Texture t3 = Texture("testbin/penguin.png"); 

	Color c1; 

	// main loop
	while (!arc.input.keyDown(ARC_QUIT))
	{ 
		// clear the screen before drawing
		arc.window.clear();
		arc.input.process();

		drawImage(t1, arc.input.mousePos + Point(100,0),
				Size(50, 100), Point(0,0), 0, c1);

		drawImageTopLeft(t2, arc.input.mousePos,
				Size(50, 100), c1);

		// flip to next screen
		arc.window.swap();
	}

	// close window when done with it
	scope(exit)
	{
		arc.window.close();
	}
	
	return 0;
}
