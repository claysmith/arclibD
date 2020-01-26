module arc.geom.circle;

import arc.draw.all; 
import arc.math.point;

import derelict.opengl.gl; 

/// Created for the purpose of SVG and Scenegraph
class Circle
{
  public:
	///
	this(Point argP, float argR)
	{
		pos = argP; 
		radius = argR; 
	}
	
	///
	void draw()
	{ 
		drawCircle(pos, radius, attr);
	}
	
	/// SVG Style drawing
	void drawSVG()
	{
		attr.isFill = true; 
		// draw circle fill
		drawCircle(pos, radius, attr);
		 
		attr.isFill = false; 
		// draw circle outline 
		drawCircle(pos, radius, attr);
	}
	
	///
	void setAttributes(DrawAttributes argAttr)
	{
		attr = argAttr;
	}

  private: 
	Point pos; 
	float radius;
	DrawAttributes attr; 
}