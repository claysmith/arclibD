import  	
	arc.all,
	arc.x.sprite.all;

import tango.io.Stdout;

// main is just here to handle states
int main()
{
	// open window with specific settings
	arc.window.open("Arc Sprite Unittest", 640, 480, false);
	arc.sound.open(); 

	Sprite s1 = new Sprite(COLLISION_TYPE.CIRCLE);
	Sprite s2 = new Sprite(COLLISION_TYPE.BOX);     

	Sprite circleOne = new Sprite(COLLISION_TYPE.CIRCLE);
	circleOne.addFrame("testbin/asteroid1.png", "static", -1, null); 
	circleOne.setPosition(arc.window.getWidth/2, arc.window.getHeight/2); 

	Sprite circleTwo = new Sprite(COLLISION_TYPE.CIRCLE); 
	circleTwo.addFrame("testbin/btn1.png", "one", 500, null); 
	circleTwo.addFrame("testbin/btn2.png", "one", 1000, null);
	circleTwo.setPosition(arc.window.getWidth/2, arc.window.getHeight/2+10); 
	circleTwo.setPivot(circleTwo.getWidth,circleTwo.getHeight); 
    
//////////////////////////////////////////////////////////////////////////////
	Sprite boxOne = new Sprite(COLLISION_TYPE.BOX);
	boxOne.addFrame("testbin/p1.png", "one", 1000, null); 
	boxOne.addFrame("testbin/p2.png", "one", 1000, null);
	boxOne.addFrame("testbin/p3.png", "one", 500, null);
	boxOne.addFrame("testbin/p4.png", "one", 500, new Sound(new SoundFile("testbin/laser.wav")));   
	boxOne.setPosition(arc.window.getWidth/2+200, arc.window.getHeight/2); 

	Sprite boxTwo = new Sprite(COLLISION_TYPE.BOX); 

	boxTwo.addFrame("testbin/c11.png", "one", 1000, null); 
	boxTwo.addFrame("testbin/c12.png", "one", 500, null);
	boxTwo.addFrame("testbin/c13.png", "one", 250, null);
	boxTwo.addFrame("testbin/c14.png", "one", 125, null);

	boxTwo.addFrame("testbin/c21.png", "two", 125, null); 
	boxTwo.addFrame("testbin/c22.png", "two", 250, null);
	boxTwo.addFrame("testbin/c23.png", "two", 500, null);
	boxTwo.addFrame("testbin/c24.png", "two", 1000, null);

	boxTwo.setPosition(arc.window.getWidth/2-200, arc.window.getHeight/2-10); 
	boxTwo.setPivot(circleTwo.getWidth,circleTwo.getHeight); 
    


	s1.addFrame("testbin/arrow.png", "static", -1, null); 

	s2.addFrame("testbin/king.jpg", "static", -1, null); 
	s2.setPosition(arc.window.getWidth/2, arc.window.getHeight/2); 
	s2.addRotationPoint(-s2.getWidth/2, -s2.getHeight/2);

	Point pivot = Point(0,0); 

	arcfl spriteAngle = 0; 
	arcfl spriteDist = 280; 

	bool circleOneDir = false;
	bool circleTwoDir = true;
	bool boxOneDir = false;
	bool boxTwoDir = false;

	arcfl zoomAmount = 1; 
	bool zIn = true; 

	// main loop
	while (!arc.input.keyPressed(ARC_QUIT))
	{ 
		arc.time.process(); 
        
		// clear the screen before drawing
		arc.input.process();

		spriteAngle += .002;
		Point p; 
		s1.setPosition(p.fromPolar(spriteDist, spriteAngle)+Point(arc.window.getWidth/2,arc.window.getHeight/2)); 
		s1.pointTo(arc.window.getWidth/2,arc.window.getHeight/2);        

		s1.process();
		s1.draw(); 

		if (boxTwo.getAnimNum == 3 && boxTwo.getAnim == "one")
		{
			boxTwo.setAnim("two"); 
		}
		else if (boxTwo.getAnimNum == 3 && boxTwo.getAnim == "two")
		{
			boxTwo.setAnim("one"); 
		}

		if (zIn)
		{
			zoomAmount+=.1; 

			if (zoomAmount > 3)
				zIn = false; 
		}
		else
		{
			zoomAmount -= .1; 
			if (zoomAmount < 1)
				zIn = true; 
		}

		circleOne.setZoom(zoomAmount); 
		boxOne.setZoom(1, zoomAmount);

		/// circle 1 processing
		if (circleOneDir == false)
		{
			circleOne.setPosition(circleOne.getX+1, circleOne.getY); 
			if (circleOne.getX > arc.window.getWidth)
				 circleOneDir = true; 
		}
		else if (circleOneDir == true)
		{
			circleOne.setPosition(circleOne.getX-1, circleOne.getY); 
			if (circleOne.getX < 0)
				 circleOneDir = false; 
		}


		/// circle two processing
		if (circleTwoDir == false)
		{
			circleTwo.setPosition(circleTwo.getX+1, circleTwo.getY); 
			if (circleTwo.getX > arc.window.getWidth)
				 circleTwoDir = true; 
		}
		else if (circleTwoDir == true)
		{
			circleTwo.setPosition(circleTwo.getX-1, circleTwo.getY); 
			if (circleTwo.getX < 0)
				 circleTwoDir = false; 
		}

		if (circleTwo.collide(arc.input.mouseX, arc.input.mouseY))
		{
			circleTwo.setColor(Color(255,0,0,255)); 
		}
		else
		{
			circleTwo.setColor(Color(255,255,255,255)); 
		}
        
		circleTwo.setAngleDeg(circleTwo.getAngleDeg+2); 
       
//////////////////////////////////////////////////////////////////////////////////////////////

		/// circle 1 processing
		if (boxOneDir == false)
		{
			boxOne.setPosition(boxOne.getX+1, boxOne.getY); 
			if (boxOne.getX > arc.window.getWidth)
				 boxOneDir = true; 
		}
		else if (boxOneDir == true)
		{
			boxOne.setPosition(boxOne.getX-1, boxOne.getY); 
			if (boxOne.getX < 0)
				 boxOneDir = false; 
		}

		/// circle two processing
		if (boxTwoDir == false)
		{
			boxTwo.setPosition(boxTwo.getX+1, boxTwo.getY); 
			if (boxTwo.getX > arc.window.getWidth)
				 boxTwoDir = true; 
		}
		else if (boxTwoDir == true)
		{
			boxTwo.setPosition(boxTwo.getX-1, boxTwo.getY); 
			if (boxTwo.getX < 0)
				 boxTwoDir = false; 
		}

		boxTwo.setAngleDeg(boxTwo.getAngleDeg+.5); 


/////////////////////////////////////////////////////////////////////////

		// COLLISIONS //
		if (circleOne.collide(circleTwo))
		{
			circleOneDir = !circleOneDir; 
		}

		if (circleOne.collide(boxTwo))
		{
		circleOneDir = !circleOneDir; 
		}

		if (circleTwo.collide(boxOne))
		{
			circleTwoDir = !circleTwoDir;  
		}

		if (circleTwo.collide(boxTwo))
		{
			circleTwoDir = !circleTwoDir;  
		}

		if (boxOne.collide(boxTwo))
		{
			boxOneDir = !boxOneDir; 
		}

		if (arc.input.keyDown(ARC_LEFT))
		{
			pivot.x--;
		}
		else if (arc.input.keyDown(ARC_RIGHT))
		{
			pivot.x++;
		}

		if (arc.input.keyDown(ARC_UP))
		{
			pivot.y--;
		}
		else if (arc.input.keyDown(ARC_DOWN))
		{
			pivot.y++;
		}

		s2.setPosition(Point(arc.input.mouseX, arc.input.mouseY)); 
		s2.setPivot(pivot); 
		s2.process();
		s2.draw(); 

		drawCircle(s2.getRotationPoint(0), 10, 8, Color(255,0,0,100), true);

		/// set box1 and circle1 positions
		//boxOne.setPosition(arc.window.getWidth/2, arc.window.getHeight/2); 
		//circleOne.setPosition(arc.input.mouseX, arc.input.mouseY); 

		circleOne.process();
		circleTwo.process();
		boxOne.process();
		boxTwo.process();

		circleOne.draw(); 
		circleOne.drawBounds();

		circleTwo.draw(); 
		circleTwo.drawBounds();

		boxOne.draw(); 
		boxOne.drawBounds();
				 
		boxTwo.draw(); 
		boxTwo.drawBounds();

		// strictly test circleOne against boxOne
		if (boxOne.collide(circleOne))
		{
			boxOneDir = !boxOneDir; 
		}

		if (s1.collide(s2))
		{
			s2.setColor(Color(255,0,0,255)); 
		}
		else
		{
			s2.setColor(Color(255,255,255,255)); 
		}

		if (arc.input.keyDown('r'))
		{
			arcfl angle = s2.getAngleDeg; 
			angle++; 
			s2.setAngleDeg(angle); 
		}

		if (arc.input.keyPressed('o'))
			arc.window.screenshot("artifact"); 

		// flip to next screen
		arc.window.swapClear();

		arc.time.limitFPS(60);

		if(arc.input.keyPressed('f'))
			Stdout(arc.time.fps);
	}

	// close window when done with it
	scope(exit)
	{
		arc.sound.close();
		arc.window.close();
	}
	
	return 0;
}
