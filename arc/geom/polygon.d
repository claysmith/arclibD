module arc.geom.polygon;

import arc.draw.all; 
import arc.math.point; 

/// Created for the purpose of SVG and Scenegraph
class Polygon
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
		drawPolygon(pos, points, attr);
	}
	
	/// SVG Style drawing
	void drawSVG()
	{
		attr.isFill = true; 
		// draw circle fill
		drawPolygon(pos, points, attr);
		
		attr.isFill = false; 
		// draw circle outline 
		drawPolygon(pos, points, attr);
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