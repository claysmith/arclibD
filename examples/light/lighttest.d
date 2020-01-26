/*
	This code is released under the zlib/libpng license.

	Copyright (C) 2007 Christian Kamm (kamm incasoftware de)
    Additional modifications by Clay Smith and cyhawk
	
	This software is provided 'as-is', without any express or implied
	warranty.  In no event will the authors be held liable for any damages
	arising from the use of this software.
	
	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:
	
	1. The origin of this software must not be misrepresented; you must not
	   claim that you wrote the original software. If you use this software
	   in a product, an acknowledgment in the product documentation would be
	   appreciated but is not required.
	2. Altered source versions must be plainly marked as such, and must not be
	   misrepresented as being the original software.
	3. This notice may not be removed or altered from any source distribution.
*/
module shadow;

import tango.math.Math;

import arc.all; 
import arc.x.light.all;

import derelict.opengl.gl;

//
// global world data
//
LightBlocker[] lightBlockers;
Light[] lights;


void main()
{
	arc.window.open("2D Shadows", 1024, 512, false);
	arc.input.open();
	
	//
	// load textures
	//
	Penumbra.texture = Texture("testbin/penumbra.png");
	Light.texture = Texture("testbin/light.png");
	
	//
	// setup world data
	//
	setupWorld();
	
	//
	// initialize dynamic texture
	//
	GLuint rendertex;
	{
		ubyte[] texdata = new ubyte[arc.window.getWidth*arc.window.getHeight*4];		
		foreach(ref color; texdata) color = 255;
		glGenTextures(1, &rendertex);
		glBindTexture(GL_TEXTURE_2D, rendertex);
		glTexImage2D(GL_TEXTURE_2D, 0, 4, arc.window.getWidth, arc.window.getHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, texdata.ptr);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		delete texdata;	
	}
	// filter the penumbra nicely
	glBindTexture(GL_TEXTURE_2D, Penumbra.texture.getID());
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);

	//
	// main loop
	//
	while(!arc.input.keyDown(arc.input.ARC_QUIT))
	{
		arc.time.process();
		arc.input.process();
		
		// light 0 follows the mouse
		lights[0].position = arc.input.mousePos;
		
		//
		// accumulate lighting in a texture
		//
		glClearColor(0.,0.,0.,0.);
		glViewport(0,0,arc.window.getWidth, arc.window.getHeight);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		foreach(ref light; lights)
		{
			// clear alpha to full visibility
			glColorMask(false, false, false, true);
			glClear(GL_COLOR_BUFFER_BIT);
			
			// write shadow volumes to alpha
			glBlendFunc(GL_ONE, GL_ONE);
			glDisable(GL_TEXTURE_2D);
			glColor4f(0., 0., 0., 1.);
			foreach(ref blocker; lightBlockers)
			{
				renderShadow(light, blocker);
			}
						
			// draw light
			glColorMask(true, true, true, false);
			glBlendFunc(GL_ONE_MINUS_DST_ALPHA, GL_ONE);
			drawImage(light.texture, light.position, Size(2*light.outerradius, 2*light.outerradius), Point(0,0), 0, light.color);
		}
		
		//
		// copy lighting into texture
		//
		glBindTexture(GL_TEXTURE_2D, rendertex);
		glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, 0, 0, arc.window.getWidth, arc.window.getHeight, 0);
		
		//
		// render regular scene
		//
		glViewport(0,0,arc.window.getWidth,arc.window.getHeight);
		glClearColor(1.,1.,1.,0.);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		foreach(ref blocker; lightBlockers)
			blocker.draw();
		
		//
		// apply lighting by rending light texture on top
		//
		glBlendFunc(GL_DST_COLOR, GL_ZERO);
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, rendertex);  
		Color.White.setGLColor();
		glBegin(GL_QUADS);
		glTexCoord2d(0.,1.); glVertex2f(0,0); 
		glTexCoord2d(0.,0.); glVertex2f(0,arc.window.getHeight);
		glTexCoord2d(1.,0.); glVertex2f(arc.window.getWidth,arc.window.getHeight);
		glTexCoord2d(1.,1.); glVertex2f(arc.window.getWidth,0);     
		glEnd();
		
		//
		// render lights on top, so they're clearly visible
		//
		glBlendFunc(GL_ONE, GL_ZERO);
		foreach(ref light; lights)
			light.draw();
		
		//
		// swap and limit framerate
		//
		arc.window.swap();		
		arc.time.limitFPS(40);
	}
}


/**
	Setup some blockers and some lights
**/
void setupWorld()
{
	// small box
	lightBlockers ~= LightBlocker(Point(225,220), 
		ConvexPolygon.fromVertices([
			Point(-10,-10),
			Point( 10,-10),
			Point( 10, 10),
			Point(-10, 10)]));
	
	// some polygon
	lightBlockers ~= LightBlocker(Point(450,360), 
		ConvexPolygon.fromVertices([
			Point(-20,-20),
			Point(  0,-30),
			Point( 20,-20),
			Point( 20,  0),
			Point( 0,  20),
			Point(-15, 10)]));

	// rectangle that's much longer than wide
	lightBlockers ~= LightBlocker(Point(150,100), 
		ConvexPolygon.fromVertices([
			Point(-120,-10),
			Point( 300,-10),
			Point( 300, 10),
			Point(-120, 10)]));
		
	// diagonal line
	lightBlockers ~= LightBlocker(Point(300,300), 
		ConvexPolygon.fromVertices([
			Point( 80,-80),
			Point(100,-70),
			Point(-70,100),
			Point(-80,80)]));

	
	// this first light will move with the mouse cursor
	lights ~= Light(Point(0,0), Color.White, 1024, 10);
	
	// stationary lights
	lights ~= Light(Point(350,330), Color.Green, 512);
	lights ~= Light(Point(270,260), Color.Blue, 512);
	lights ~= Light(Point(200,400), Color.Yellow, 1024);
	lights ~= Light(Point(500,50), Color.Red, 512);
	lights ~= Light(Point(450,50), Color.Green, 512);
	lights ~= Light(Point(475,75), Color.Blue, 512);		
}
