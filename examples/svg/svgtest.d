module svgtest; 

import 	
	arc.game, 
	arc.input,
	arc.texture, 
	arc.math.all,
	arc.draw.all;

import arc.x.svg.svg; 

import derelict.opengl.gl; 

class MyGame : Game
{
	// init code here
	this(char[] argT, Size argS, bool argFS)
	{
		super(argT, argS, argFS);
		
	    // load up SVG 
		ex1 = new SVG("testbin/svg/circle.svg"); 
	}
	
	// loop code here
	void process()
	{
		glClearColor(255,255,255,0);
		
		// draw the svg 
		ex1.draw(); 
		
		drawCircle(arc.input.mousePos + Point(100, 10),
				25, 20, Color.Red, false);
	}
	
	// shutdown coder here
	void shutdown()
	{

	}
	
	SVG ex1; 
}

// main entry 
int main()
{
	// initialize game
	Game g = new MyGame("SVG Test", Size.d640x480, false); 
	
	// loop game
	g.loop(); 

	// shutdown() is called by loop() after loop exits 
	return 0;
}