module arc.geom.rect;

import arc.draw.attributes; 
import arc.draw.shape; 
import arc.math.point; 
import arc.math.size; 

/// Created for the purpose of SVG and Scenegraph
class Rect
{
	///
	this(Point argP, Size argS)
	{
		pos = argP; 
		size = argS; 
	}
	
	///
	void draw()
	{ 
		drawRectangle(pos, size, attr);
	}
	
	/// SVG Style drawing
	void drawSVG()
	{
		attr.isFill = true; 
		// draw circle fill
		drawRectangle(pos, size, attr);
		
		attr.isFill = false; 
		// draw circle outline 
		drawRectangle(pos, size, attr);
	}
	
	///
	void setAttributes(DrawAttributes argAttr)
	{
		attr = argAttr;
	}
	
	Point pos; 
	Size size; 
	Point rounded; 
	DrawAttributes attr; 
}