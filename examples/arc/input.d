module input;

import 	
	arc.window, 
	arc.input;

import tango.io.Stdout; 

// main is just here to handle states
int main()
{
	// open window with specific settings
	arc.window.open("Arc Input Unittest", 640, 480, false);
	arc.input.open(); 
	
	Stdout("joysticks available: ", arc.input.numJoysticks).newline;
	Stdout("joysticks opened: ", arc.input.openJoysticks()).newline;
	foreach(stick; joysticksIter)
	{
		Stdout("joystick ", stick, " named ", joystickName(stick), " has: ").newline;
		Stdout("    ", numJoystickButtons(stick), " buttons").newline;
		Stdout("    ", numJoystickAxes(stick), " axes").newline;
	}	
	
	arc.input.setAxisThreshold(0.02);
	
	char[] text = ""; 

	// while the user hasn't closed the window
	while (!arc.input.keyDown(ARC_QUIT))
	{
			// get current input from user
			arc.input.process();
			arc.window.clear();

			// user lightly taps 't' key
			if (arc.input.keyPressed('t'))
				Stdout("T Key pressed").newline;
			
			// user holds down 't' key
			if (arc.input.keyDown('s'))
				Stdout("S Key down").newline;
	
			// user lightly clicks right mouse button
			if (arc.input.mouseButtonPressed(RIGHT))
				Stdout("Mouse button RIGHT pressed").newline; 

			// user holds down left mouse button
			if (arc.input.mouseButtonDown(LEFT)) // RIGHT and MIDDLE work as well
				Stdout("Mouse button LEFT pressed").newline; 

			// returns true if user hits a character
			if (arc.input.charHit) {
				// returns the last characters the user hit
				Stdout(arc.input.lastChars).newline; 
			}

			// returns true if mouse is in motion
			if (arc.input.mouseMotion)
			{
				Stdout("X: ", arc.input.mouseX, " Y: ", arc.input.mouseY).newline;
			}
	
			// returns true if mouse is wheeling up
			if (arc.input.wheelUp) // wheelDown - returns true on mouse Wheelup and Wheeldown
				Stdout("Mouse wheel is up").newline;

			// return true if current modifier is down
			if (arc.input.keyPressed(ARC_LSHIFT)) // RSHIFT, LCTRL, RCTRL, LALT, RALT, LMETA, RMETA, NUM, CAPS
			{
				Stdout("LSHIFT mod is hit").newline;
			}
			
			if (arc.input.keyDown(ARC_RSHIFT))
			{
				Stdout("RSHIFT mod is down").newline; 
			}
			
			foreach(stick; joysticksIter)
			{
				foreach(button; arc.input.joyButtonsDown(stick))
					Stdout("button ", button, " pressed on joystick ", stick ).newline;
				foreach(button; arc.input.joyButtonsUp(stick))
					Stdout("button ", button, " released on joystick ", stick ).newline;
				foreach(axis, pos; joyAxesMoved(stick))
					Stdout("axis ", axis, " moved to ", pos, " on joystick ", stick ).newline;
			}
            
			arc.window.swap(); 
	}



	// close window when done with it
	scope(exit)
	{
		arc.window.close();
	}
	
	return 0;
}
