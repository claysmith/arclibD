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

module arc.x.light.umbra; 

import arc.math.point;

import derelict.opengl.gl;

import arc.x.light.routines;


/**
	Umbrae are the regions of full shadow behind light blockers.
	
	Represented by a series of lines.
**/
struct Umbra 
{ 
	struct Section
	{
		Point base; 
		Point direction;
	}
	Section[] sections;
	
	void draw()
	{
		assert(sections.length >= 2);
		
		auto style = GL_TRIANGLE_STRIP;
		// auto style = GL_LINES;
		
		// the umbra draw regions (if considered quads) can sometimes 
		// be concave, so use triangles and start once from left and 
		// once from right to minimize problems
		
		glBegin(style);		
		foreach(ref s; sections[0..$/2+1])
		{
			makeVertex(s.base);
			makeVertex(s.base + s.direction);
		}		
		glEnd();
	
		glBegin(style);		
		foreach_reverse(ref s; sections[$/2..$])
		{
			makeVertex(s.base);
			makeVertex(s.base + s.direction);
		}		
		glEnd();		
	}
}