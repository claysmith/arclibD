module draw; 

import 	
	arc.game, 
	arc.input,
	arc.texture, 
	arc.math.all,
	arc.draw.all;

class MyGame : Game
{
	// init code here
	this(char[] argT, Size argS, bool argFS)
	{
		super(argT, argS, argFS);
		
		t1 = Texture("testbin/penguin.png",true); 
		t2 = Texture("testbin/penguin.png",true); 
		
	    // do a test for re-binding penguin.png image
	    t2.setSDLSurface(t1.getSDLSurface); 
	}
	
	// loop code here
	void process()
	{
		drawPixel(arc.input.mousePos, Color.Red);

		drawCircle(arc.input.mousePos + Point(100, 10),
					25, 20, Color.Red, false);

		drawLine(Point(0,0), arc.input.mousePos, Color.Blue);

		drawRectangle(arc.input.mousePos + Point(0,100),
				Size(50, 100), Color.Blue,true);

		drawImage(t1, arc.input.mousePos + Point(100,200),
				Size(50, 100), Point(0,0), 0, Color.White);

		drawImageTopLeft(t2, arc.input.mousePos + Point(200,300));
	}
	
	// shutdown coder here
	void shutdown()
	{
	    t1.freeSDLSurface(); 
	    t2.freeSDLSurface(); 
	}
	
	// game vars, etc.
	Texture t1, t2; 
}

// main entry 
int main()
{
	// initialize game
	Game g = new MyGame("Arc Graphics Primitives", Size.d640x480, false); 
	
	// loop game
	g.loop(); 

	// shutdown() is called by loop() after loop exits 
	return 0;
}
