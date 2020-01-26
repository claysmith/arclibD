/******************************************************************************* 

	Create a simple game. 

	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:     ArcLib team 

	Description:    
	  Gives the user everything they need to create a basic game. 

	Examples:
	-------------------------------------------------------------------------------
import arc.all;

class MyGame : Game
{
    this(char[] argT, Size argS, bool argFS)
    {
        super(argT, argS, argFS);
        font = new Font("font.ttf", 16); 
    }

    void process()
    {
        font.draw("Hello Arc World", arc.input.mousePos, Color.White);
    }

    // shutdown coder here
    void shutdown()
    {
    }

    // game vars, etc.
    Font font;  
}


// main entry 
int main()
{
    // initialize game
    Game g = new MyGame("Hello Arc World", Size.d640x480, false); 

    // loop game
    g.loop(); 

    // shutdown() is called by loop() after loop exits 
    return 0;
}
    -------------------------------------------------------------------------------


*******************************************************************************/

module arc.game;

import arc.window, arc.input, arc.time, arc.font, arc.math.all; 

/// Capsulation of the basics required to make a game with Arc
class Game
{
	/// user can overload and put there init code here
	this(char[] argT, Size argS, bool argFS)
	{
		arc.window.open(argT, cast(int)argS.w, cast(int)argS.h, argFS);
		arc.input.open(); 
		arc.input.openJoysticks();
		arc.font.open(); 
	}
	
	/// user can put there rendering and processing code here
	public void process()
	{
		
	}
	
	/// user puts there shutdown code here
	public void shutdown()
	{
		
	}
	
	
	
	/// run the game loop, shutdown when user quits
	public void loop()
	{
		while (!arc.input.isQuit())
		{
			arc.window.clear(); 
			arc.input.process(); 
			arc.time.process(); 
			arc.time.limitFPS(targetFPS); 
			process(); 
			arc.window.swap(); 
		}
		
		scope(exit)
		{
			shutdown();
			arc.window.close(); 
		}
	}
	
	///
	public void setFPS(int argT)
	{
		targetFPS = argT; 
	}
	
	private int targetFPS = -1; 
}