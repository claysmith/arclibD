module perpixel; 

import 
	arc.types,
	arc.window, 
	arc.time,
	arc.input,
	arc.texture, 
	arc.x.perpixel.perpixel;
	 
import derelict.sdl.sdltypes,
        derelict.sdl.sdlfuncs; 
        
import  
    tango.io.Console,
    tango.text.convert.Float;

// main is just here to handle states
int main()
{
	// open window with specific settings
	arc.window.open("Per Pixel Test", 800, 600, false);
	
    // set up perpixel collision map
    PerPixel map = new PerPixel("testbin/pp1.png"); 
    PerPixel map2 = new PerPixel("testbin/pp2.png"); 
    
    map.setPosition(Point(200,200)); 
    
    //map.printCollision(); 
    //map2.printCollision(); 
    
    arc.input.showCursor(false); 
    
    Cout("Tex size is " ~ tango.text.convert.Float.toString(map.getSize.w) ~ " - " ~ tango.text.convert.Float.toString(map.getSize.h)); 
    
	// main loop
	while (!arc.input.keyDown(ARC_QUIT))
	{ 
		// clear the screen before drawing
		arc.window.clear();
		arc.input.process();
        
        //map.drawBox(pos1);
       // map2.drawBox(arc.input.mousePos); 
        
        map2.setPosition(arc.input.mousePos); 
		
        // if there is a collision
        if (map.pixelCollision(map2))
        {
            // draw red
            map.draw(Color.Red); 
        }
        else
        {
            // otherwise draw white
            map.draw(Color.White); 
        }
        
        map2.draw(Color.White); 
        
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
