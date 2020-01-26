module artifact; 

import 	
	arc.window, 
	arc.math.point,
	arc.math.size, 
	arc.input,
	arc.texture, 
	arc.draw.image,
	arc.draw.shape,
	arc.draw.color; 

import derelict.opengl.gl; 

// main is just here to handle states
int main()
{
	// open window with specific settings
	arc.window.open("Arc Artifact Unittest", 640, 480, false);

	Texture t1 = Texture("testbin/artifacttest.png"); 
	Texture t2 = Texture("testbin/artifacttest-poweroftwo.png"); 
	
	// main loop
	while (!arc.input.keyDown(ARC_QUIT))
	{ 
		// clear the screen before drawing
		arc.window.clear();
		arc.input.process();

		drawRectangle(Point(0,0), Size(640,480), Color.White, true);
		drawRectangle(Point(100,100), Size(300,5), Color.Red, true);
		
		
		glPushMatrix();
		glTranslatef(arc.input.mousePos.x, arc.input.mousePos.y,0.);
		glScalef(3,3,1.);		
		drawImageSubsection(t1, Point(0,0), Point(0,0) + t1.getSize);		
		glTranslatef(-16,-16,0.);
		drawImageSubsection(t2, Point(0,0), Point(0,0) + t2.getSize);		
		glPopMatrix();

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
