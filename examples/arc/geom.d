module draw; 

import 	
	arc.game, 
	arc.input,
	arc.texture, 
	arc.math.all,
	arc.draw.all,
	arc.geom.all; 

import derelict.opengl.gl; 

class MyGame : Game
{
	// init code here
	this(char[] argT, Size argS, bool argFS)
	{	
		super(argT, argS, argFS);
		
		Point[] polys;
		polys.length = 3;
		polys[0] = Point(0,0);
		polys[1] = Point(0,100);
		polys[2] = Point(100,0);
		
		circle = new Circle(Point(150,150),40);
		ellipse = new Ellipse(Point(100,100), Point(50,10)); 
		line = new Line(Point(0,0), Point(30,30));
		polygon = new Polygon(Point(200,10),polys);
		polyline = new Polyline(Point(10,200), polys); 
		rectangle = new arc.geom.rect.Rect(Point(400,40), Size(100,50)); 
		 
		attr.fill = Color.Red; 
		attr.stroke = Color.Blue;
		attr.detail = 20;
		attr.strokeWidth = 2; 
		
		circle.setAttributes(attr); 
		ellipse.setAttributes(attr);
		line.setAttributes(attr);
		polygon.setAttributes(attr);
		rectangle.setAttributes(attr);
	}
	
	// loop code here
	void process()
	{
		circle.drawSVG();
		ellipse.drawSVG(); 
		line.draw();
		polygon.drawSVG(); 
		rectangle.drawSVG(); 
		
		glClearColor(255,255,255,255); 
	}
	
	// shutdown coder here
	void shutdown()
	{

	}
	
	// game vars, etc.
	Circle circle; 
	Ellipse ellipse; 
	Line line; 
	Polygon polygon; 
	Polyline polyline; 
	arc.geom.rect.Rect rectangle; 
	
	DrawAttributes attr;
}

// main entry 
int main()
{
	// initialize game
	Game g = new MyGame("Arc Geometry Primitives", Size.d640x480, false); 
	
	// loop game
	g.loop(); 

	// shutdown() is called by loop() after loop exits 
	return 0;
}
