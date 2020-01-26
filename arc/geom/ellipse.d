module arc.geom.ellipse;

import arc.draw.all; 
import arc.math.point; 

/// Created for the purpose of SVG and Scenegraph
class Ellipse
{
	///
	this(Point argP, Point argR)
	{
		pos = argP; 
		radius = argR; 
	}
	
	///
	void draw()
	{ 
		drawEllipse(pos, radius, attr);
	}
	
	/// SVG Style drawing
	void drawSVG()
	{
		attr.isFill = true; 
		// draw circle fill
		drawEllipse(pos, radius, attr);
		
		attr.isFill = false; 
		// draw circle outline 
		drawEllipse(pos, radius, attr);
	}
	
	///
	void setAttributes(DrawAttributes argAttr)
	{
		attr = argAttr;
	}
	
	Point pos; 
	Point radius; 
	DrawAttributes attr; 
}