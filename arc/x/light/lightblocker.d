/******************************************************************************* 

	Lighting code

	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Christian Kamm (kamm incasoftware de)
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:     ArcLib team 
	
	Description:
	Lighting code
	
	Examples:
	--------------------
	--------------------

*******************************************************************************/

module arc.x.light.lightblocker; 

import 
	arc.math.point,
	arc.draw.color;
	
import arc.x.light.convexpolygon;

import derelict.opengl.gl;


/// defines an area that blocks light by a convex polygon
struct LightBlocker
{
	///
	Point position;
	///
	ConvexPolygon shape;
	
	/// returns a sequence of vertices that form a line, indicating
	/// where light is blocked
	Point[] getBlockedLine(ref Point from)
	{
		size_t[] edgeIndices = shape.getBackfacingEdgeIndices(from - position);
		
		Point[] ret;
		ret ~= position + shape.edges[edgeIndices[0]].from;
		foreach(ind; edgeIndices)
			ret ~= position + shape.edges[ind].to;
		
		return ret;
	}
	
	///
	void draw(Point offset = Point(0,0))
	{
		glDisable(GL_TEXTURE_2D);
		Color.Red.setGLColor();
		
		glBegin(GL_TRIANGLE_FAN);
		foreach(ref edge; shape.edges)
		{
			glVertex2f(position.x + offset.x + edge.from.x, position.y + offset.y + edge.from.y); 
			glVertex2f(position.x + offset.x + edge.to.x, position.y + offset.y + edge.to.y); 
		}
		glEnd();
	}
}