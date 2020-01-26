module math; 

import
	arc.math.angle,
	arc.math.collision,
	arc.math.matrix,
	arc.math.point,
	arc.math.rect,
	arc.math.routines; 
	
import 
	arc.window,
	arc.input,
	arc.draw.shape; 
	
import arc.time; 
	
import tango.io.Stdout; 

int main()
{
	/// MATH ANGLE UNIT TESTS //////////////////////////////////
	/// Test convert degrees to radians and back to degrees
	Degrees deg2;
	Degrees deg = 180; 
	Radians rad = degreesToRadians(deg); 
	deg2 = radiansToDegrees(rad); 
	
	Stdout("Degree ", deg).newline; 
	Stdout("Converted to radian ", rad).newline; 
	Stdout("Converted back to degrees ", deg2).newline; 
	
	assert(deg == deg2); 
	
	/// Test restrict degrees and radians
	Stdout("\n\n");
	
	Degrees deg3 = 180 + 360 + 360; 
	
	deg3 = restrictDeg(deg3);
	
	Stdout("Degree restricted is ", deg3).newline; 
	assert (deg3 == 180); 
	
	Radians rad3 = PI + TWOPI + TWOPI; 
	
	rad3 = restrictRad(rad3); 
	Stdout("Radian restricted is ", rad3).newline; 	
	//assert(rad3 == withinRange(rad3, PI, .1)); 
	
	// Arc Math routines unittest /////////////////////////////////////////////////////////
	
	// within range test 
	if (!withinRange(5, 7, 2))
		assert(0); 

	if (!withinRange(5, 5.05, .05))
		assert(0); 
	
	if (withinRange(5,7,1))
		assert(0); 

	assert(nextPowerOfTwo(3)==4); 
	assert(nextPowerOfTwo(57)==64);
	
	for(int i = 0; i < 10; i++)
	{
		Stdout(randomRange(20, 30)).newline; 
	}
	
	Stdout(max(3.7, 5.7)).newline;
	Stdout(max(79, 50)).newline; 
	
	
	/// MATH COLLISION UNIT TESTS /////////////////////////////

	// Set up two boxes 
	Point b1, b2; 
	Size s1, s2;
	b1 = Point(50,50); 
	b2 = Point(55,55); 
	s1 = Size(30,20); 
	s2 = Size(25,20); 
	
	// set up two circles
	Point c1, c2; 
	arcfl r1, r2; 

	c1 = Point(150,150);
	c2 = Point(155,155); 
	r1 = 30;
	r2 = 20;
	
	// set up two lines 
	Point l1, l2; 
	Point l3, l4; 
	Point nullp;
	
	// set up polygon
	Point[] poly; 
	poly.length=5; 
	poly[0] = Point(200,200);
	poly[1] = Point(300,220);
	poly[2] = Point(250,250);
	poly[3] = Point(100,300);
	poly[4] = Point(75,220);


	l1 = Point(100,100);
	l2 = Point(150,150);
	
	l3 = Point(100,90); 
	l4 = Point(90,150); 

	Point horizTrans = Point(0,0); 
	
	arc.window.open("Collision Tests", 800,600,false);
	arc.input.open(); 

	while (!(arc.input.keyDown(ARC_ESCAPE)||arc.input.keyDown(ARC_QUIT)))
	{
		arc.time.process();
		arc.time.limitFPS(30);
		arc.input.process();
		
		arc.window.clear(); 
		
		if (arc.input.keyDown(ARC_RIGHT))
		{
			/// shift right
			horizTrans.x++;
		}
		if (arc.input.keyDown(ARC_LEFT))
		{
			/// shift left
			horizTrans.x--;
		}
		
		/// Test both boxes against eachother 
		if (boxBoxCollision(b1 + horizTrans, s1, b2, s2) || boxCircleCollision(b1+horizTrans, s1, c2, r2) || boxXYCollision(Point(arc.input.mouseX, arc.input.mouseY), b1+horizTrans, s1))
		{
			/// draw box red
			drawRectangle(b1 + horizTrans, s1, Color.Red, true);
		}
		else
		{
			/// draw box white 
			drawRectangle(b1 + horizTrans, s1, Color.White, true);
		}
		
		drawRectangle(b2,s2,Color.White, true); 
		
		/// Test both circles against each other
		if (circleCircleCollision(c1+horizTrans, r1, c2, r2) || boxCircleCollision(b2, s2, c1+horizTrans, r1) || circleXYCollision(Point(arc.input.mouseX, arc.input.mouseY), c1+horizTrans, r1))
		{
			drawCircle(c1 + horizTrans, r1, 10, Color.Red, false);
		}
		else
			drawCircle(c1 + horizTrans, r1, 10, Color.White, false);			
		
		drawCircle(c2, r2, 10, Color.White, false);
		
		// swap circle1 and box1 positions
		if (arc.input.keyPressed('s'))
		{
			arc.math.routines.swap!(Point)(b1, c1); 
		}
		
		if (arc.input.keyDown(ARC_CAPSLOCK))
		{
			l4 = Point(arc.input.mouseX, arc.input.mouseY); 
		}
			
		if (lineLineCollision(l1, l2, l3, l4, nullp) || inSegment(Point(arc.input.mouseX, arc.input.mouseY), l1,l2 ) )
		{
			drawLine(l1, l2, Color.Red);
		}
		else
			drawLine(l1, l2, Color.White); 
		
		drawLine(l3, l4, Color.Blue); 
		
		if ( polygonXYCollision(Point(arc.input.mouseX, arc.input.mouseY), poly) )
			drawPolygon(poly, Color.Red, true); 
		else
			drawPolygon(poly, Color.Blue, false); 
		

		arc.window.swap();
	}
	
	arc.window.close();
	
	return 0;
}
