/******************************************************************************* 

	Frame with box collision detection. 

	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:      ArcLib team 

	Description:    
		Frame with box collision detection. 

	Examples:      
	---------------------
		None provided.  
	---------------------

*******************************************************************************/
module arc.x.sprite.frame.boxframe; 

public import 
	arc.x.sprite.frame.frame;

import 
	tango.math.Math,
	tango.io.FilePath; 

import 
	arc.types,
	arc.draw.shape, 
	arc.texture,
	arc.window,
	arc.math.point,
    arc.sound;

import 
	derelict.opengl.gl,
	derelict.sdl.sdl,
	derelict.sdl.image;

/// Frame with box based collision detection
class BoxFrame : Frame
{
  public:

	this() {}

   
	this(char[] argFullFileName, int argTime, Sound argSnd, inout Size s)
	{
		s = init(argFullFileName, argTime, argSnd);
	}

	this(Texture tex, int argTime, Sound argSnd, inout Size s)
	{
		s = init(tex, argTime, argSnd);
	}

	Size init(char[] argFullFileName, int argTime, Sound argSnd)
	{
		// will crash if file doesn't exist
		auto filepath = new FilePath(argFullFileName);
		if (!filepath.exists())
			assert(0, "File " ~ argFullFileName ~ " does not exist!");
		
		// turn image into an OpenGL texture
		Texture tex = arc.texture.load(argFullFileName);
		texture = tex;
		
		ID = tex.getID;

		time = argTime;
		snd = argSnd;
        if (snd !is null) snd.setPaused(false);

		Size s = tex.getSize;
		return s;
	}

	Size init(Texture tex, int argTime, Sound argSnd)
	{
		ID = tex.getID;
		texture = tex;

		time = argTime;
		snd = argSnd;
        if (snd !is null) snd.setPaused(false);

		Size s = tex.getSize;
		return s;
	}

	int getID() { return ID; }

   ~this()  
   {
   }

  private:
   int ID;
}
