module arc.geom.polyline;

import arc.draw.shape; 
import arc.draw.attributes; 
import arc.math.point; 

class Polyline
{
	///
	this(Point argPos, Point[] argP)
	{
		pos = argPos; 
		points = argP; 
	}
	
	///
	void draw()
	{ 
		drawPolyLine(pos, points, attr);
	}
	
	///
	void setAttributes(DrawAttributes argAttr)
	{
		attr = argAttr;
	}
	
	Point pos; 
	Point[] points; 
	DrawAttributes attr; 
}