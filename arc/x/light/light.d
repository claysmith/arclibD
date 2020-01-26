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

module arc.x.light.light;

import 
	arc.math.point,
	arc.draw.color,
	arc.texture; 

import derelict.opengl.gl; 

import arc.x.light.routines;

import tango.math.Math;

/// a light source
struct Light
{
	///
	Point position;
	///
	Color color = Color.White;
	
	/// the light does not provide any illumination further away than that
	real outerradius = 128;
	
	/** 
		Controls the size of the lightsource and thereby the softness of shadows.
		If lightblockers are smaller than this, there'll be artifacts.
	**/
	real sourceradius = 5;
	
	///
	void draw()
	{
		glDisable(GL_TEXTURE_2D);
		Color.Yellow.setGLColor();
		
		glBegin(GL_TRIANGLE_FAN);
		
		makeVertex(position);
		
		int segments = 20;
		for(int i = 0; i < segments + 1; ++i)
		{
			makeVertex(position + Point.fromPolar(sourceradius, 2*PI*i / segments));
		}
		
		glEnd();
	}
    
	///
	void draw(Point offset)
	{
		glDisable(GL_TEXTURE_2D);
		Color.Yellow.setGLColor();
		
		glBegin(GL_TRIANGLE_FAN);
		
		makeVertex(offset + position);
		
		int segments = 20;
		for(int i = 0; i < segments + 1; ++i)
		{
			makeVertex(offset + position + Point.fromPolar(sourceradius, 2*PI*i / segments));
		}
		
		glEnd();
	}
	
	static Texture texture;
}

