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

module arc.x.light.penumbra; 

import 
	arc.math.point,
	arc.texture;

import derelict.opengl.gl;

import arc.x.light.routines;


/***
	Penumbrae are the regions of half-shadow generated by voluminous
	light sources.
	
	They are represented by a series of sections, each containing a line
	and an intensity. The intensity gives the strength of the shadow on
	that line between 0. (fully lit) and 1. (complete shadow).
*/
struct Penumbra
{
	/// line line between 'base' and 'base + direction' has the
	/// shadow intensity 'intensity'
	struct Section
	{
		Point base;
		Point direction;
		real intensity;
	}
	Section[] sections;
	
	///
	void draw()
	{
		assert(sections.length >= 2);
		
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, texture.getID());
		
		glBegin(GL_TRIANGLES);
		
		foreach(i, ref s; sections[0..$-1])
		{
			glTexCoord2d(0., 1.);
			makeVertex(s.base);
			
			glTexCoord2d(s.intensity, 0.);
			makeVertex(s.base + s.direction);
			
			glTexCoord2d(sections[i+1].intensity, 0.);
			makeVertex(sections[i+1].base + sections[i+1].direction);
		}
		
		glEnd();
		
		glDisable(GL_TEXTURE_2D);				
	}
	
	///
	static Texture texture;
}