module arc.geom.line;

import arc.draw.all; 
import arc.math.point; 

/// Created for the purpose of SVG and Scenegraph
class Line
{
	///
	this(Point argS, Point argE)
	{
		start = argS; 
		end = argE; 
	}
	
	///
	void draw()
	{
		drawLine(start,end,attr); 
	}
	
	void setAttributes(DrawAttributes argAttr)
	{
		attr = argAttr;
	}
	
	Point start, end;
	DrawAttributes attr;
}