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

module arc.x.light.routines;

import arc.math.point; 

import derelict.opengl.gl;

/// convenience function to convert points to OpenGL vertices
void makeVertex(ref Point p) 
{ 
	glVertex2f(p.x, p.y); 
}
