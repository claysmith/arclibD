/******************************************************************************* 

	Class that allows you to load up animations or frames
	from a sprite sheet or image sheet.	

	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:      ArcLib team 

	Description:    
		Class that allows you to load up animations or frames
	from a sprite sheet or image sheet.	

	Examples:      
	---------------------
		Please see sprite unittest in arcunittests. 
	---------------------

*******************************************************************************/

module arc.x.texturemaploader.texturemaploader;

private import arc.all; 

import 
	derelict.opengl.gl,
	derelict.sdl.sdl,
	derelict.sdl.image;

private import tango.util.log.Log; 

/// Load up a texture matrix based on texture map
class TextureMapLoader
{
	this(char[] argImg, Size argBox)
	{
		loadImage(argImg, argBox); 
	}
	
	private void loadImage(char[] argImg, Size argBox, int argPadding=0)
	{
		//log.info("load image begin");
		
		// load up texture with access to SDL surface
		Texture image = Texture(argImg,true); 
		SDL_Surface *surf = image.getSDLSurface(); 
		
		int i=0,j=0; 
		
		//log.info("image loaded");
		
		// init size
		map.length = 1; 
		
		for (int x = 0; x <= image.getSize.w-argBox.w; x+=argBox.w+argPadding)
		{
			for (int y = 0; y <= image.getSize.h-argBox.h; y+=argBox.h+argPadding)
			{
				//log.info("getting map for " ~ tango.text.convert.Integer.toString(x) ~ " - " ~ tango.text.convert.Integer.toString(y) ~ " " ~ tango.text.convert.Integer.toString(cast(int)argBox.w) ~ " " ~ tango.text.convert.Integer.toString(cast(int)argBox.h));
				// extract and create texture 
				Texture t = Texture(getSubSDLSurface(surf, x,y,cast(int)argBox.w, cast(int)argBox.h)); 
				
				// grow map as needed 
				map[i].length = map[i].length + 1; 
				
				// add it to list
				map[i][j] = t; 
				
				j++; 
			}
			
			// grow map as needed 
			map.length = map.length + 1; 
		}
	}
	
	/// get map that was loaded 
	public Texture[][] getTextureMap() { return map; }
	
	// texture map
	private Texture[][] map; 
}

// load up logger
static this()
{
	log = Log.getLogger("arc.x.texturemaploader.texturemaploader"); 
}

private static Logger log; 