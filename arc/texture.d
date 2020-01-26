/******************************************************************************* 

	Texture structure can be used for loading textures into memory. 

	Authors:			ArcLib team, see AUTHORS file 
	Maintainer:		Clay Smith (clayasaurus at gmail dot com) 
	License:			zlib/libpng license: $(LICENSE) 
	Copyright:		ArcLib team 

	Description:    
		A structure that can be used to load textures into memory. 

	Examples:
	--------------------
	import arc.gfx.texture; 

	int main() {
	   // use our texture loading function to load texture and grab ID
	   // which is used by OpenGL to identify the said texture
	   Texture tex = Texture("texture.png/jpg/tga/bmp/gif/pcx/lbm/xpm/pnm");

	   // bind texture to whatever polygons you want 
	   glBindTexture(GL_TEXTURE_2D, tex.getID);
		  
	   // draw said polygon
	   glBegin(GL_QUADS);
		  glTexCoord2f(in_left,  in_top);        glVertex2f(x,            		y);
		  glTexCoord2f(in_right, in_top);        glVertex2f(x + tex.getWidth, 	y);
		  glTexCoord2f(in_right, in_bottom);     glVertex2f(x + tex.getWidth, 	y + tex.getHeight);
		  glTexCoord2f(in_left,  in_bottom);     glVertex2f(x,					y + tex.getHeight);
	   glEnd(); 

	   return 0;
	}
	--------------------

*******************************************************************************/

module arc.texture;

import 	
	derelict.sdl.sdl,
	derelict.sdl.image,
	derelict.opengl.gl, 
	derelict.opengl.glu;

import  
	arc.types,
	arc.math.point,
	arc.math.size, 
	arc.math.routines,
	arc.memory.routines;
	
import
	tango.io.FilePath,
	tango.util.log.Log,
	tango.stdc.stringz,
	tango.text.convert.Integer,
	tango.text.convert.Utf,
	tango.math.Math;

/// logger for this module
public Logger logger;

static this()
{
	// setup logger
	logger = Log.getLogger("arc.texture");
}

// initialize module variables on module load up 
private 
{
	// keeps track of the texture number we are on
	uint gTextureCount = 0; 

	// store a single copy of each texture in memory, prevent multiple textures 
	// form being loaded more than once 
	Texture[char[]] textureList; 
}

public 
{
	/// jump texture count 
	void incrementTextureCount(uint argInc) { gTextureCount += argInc; }
	
	/// assign texture ID
	uint assignTextureID() { gTextureCount++; return gTextureCount; } 
}

/// Texture Data we hand back to the user
struct Texture
{
  public:
	/// texture 'constructor', load texture given full file name
	static Texture opCall(char[] texFileName, bool keepSDLSurface=false) 
	{
		// if texture hasn't been loaded before, load it 
		if (!(texFileName in textureList))
		{
			// load texture 
			Texture t;
			t.file_ = texFileName.dup;
			t.loadTexture(texFileName); 

			if (keepSDLSurface == false)
			{
				 t.freeSDLSurface(); 
			}

			textureList[texFileName] = t; 
			textureList.rehash; 
			return textureList[texFileName];
		}

		// otherwise just give the texture that was already loaded 
		return textureList[texFileName]; 
	}
	
	/// Load from SDL_Surface. Will not be added to texture list
	static Texture opCall(SDL_Surface *surf, bool keepSDLSurface=false)
	{
		// textures without filename will not be added to hash
		Texture  t;
		t.loadTexture(surf);
		
		if (keepSDLSurface == false)
		{
			t.freeSDLSurface(); 
		}
		
		return t; 
	}
	
	///
	static Texture opCall(Size size, Color defColor) 
	{
		Texture t; 
		t.createTexture(size, defColor); 
		return t; 
	}
    
	/// texture 'constructor', load texture with next texture ID
	static Texture opCall() 
	{
		gTextureCount++; 
		Texture t; 
		t.ID_ = gTextureCount;
		return t; 
	}
    
	/// texture 'destructor', destroy image data being held
	void freeSDLSurface()
	{		
		// free image data
		SDL_FreeSurface(image); 
	}
    
	/// destroy the GL texture so it can be re-binded manually if need be 
	void destroy()
	{
		// Delete the texture first 
		glDeleteTextures(1, &ID_); 
	}
    
	/// set up new SDL pixel data for this image 
	void setSDLSurface(SDL_Surface *nimage)
	{
		if (nimage is null)
		{
			logger.error("New SDL_Surface* for texture is null!"); 
			assert(nimage !is null); 
		}

		// store the original width and height
		Uint32 orig_w = nimage.w;
		Uint32 orig_h = nimage.h;
				
		// calculate nearest power-of-two size
		Uint32 pot_w = nextPowerOfTwo(nimage.w);
		Uint32 pot_h = nextPowerOfTwo(nimage.h);	
		
		// convert image to 32 bit RGBA image of power of two size if needed 
		if ( ((nimage.format.BitsPerPixel != 32)) || nimage.w != pot_w || nimage.h != pot_h)
		{
			// create new surface of pot size with 32 bit RGBA ordering
			SDL_Surface* newsurf =	SDL_CreateRGBSurface (SDL_SWSURFACE, 
											pot_w, pot_h, 32, 0x000000ff,
											0x0000ff00, 0x00ff0000, 0xff000000);

			// copy old surface data onto the new surface
			SDL_SetAlpha(nimage, 0, 0); // set alpha to off, so we just copy all the information
			SDL_FillRect(newsurf, null, 0); // fill with transparencity
			SDL_BlitSurface (nimage, null, newsurf, null);

			// free old surface memory 
			SDL_FreeSurface(nimage);

			// point the old surface data to the new surface 
			nimage = newsurf; 
		}
        
		// Delete the texture first 
		glDeleteTextures(1, &ID_); 

		// Re-Bind the texture to the texture arrays index and init the texture
		glBindTexture(GL_TEXTURE_2D, ID_);
		glPixelStorei(GL_UNPACK_ALIGNMENT,1);
   
		// Build Mipmaps (builds different versions of the picture for distances - looks better)
		gluBuild2DMipmaps(	GL_TEXTURE_2D, 4, nimage.w, nimage.h, 
							GL_RGBA, GL_UNSIGNED_BYTE, nimage.pixels);
                     
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

		logger.info("Texture with ID " ~ tango.text.convert.Integer.toString(ID_) ~ " has been re-loaded.");
		
		// set texture size and ID attributes 
		textureSize_.w = pot_w;
		textureSize_.h = pot_h;
		
		imageSize_.w = orig_w;
		imageSize_.h = orig_h;
    }

  // hide loadTexture because using it by itself is not 'resource safe' 
  // you may end up with the same resource loaded twice 
private: 
	/// load texture based on texture's file name 
	void loadTexture(char[] texFileName)
	{
		// If our resource doesn't exist, report it and stop
		auto filepath = new FilePath(texFileName);
		if (!filepath.exists())
		{
			logger.error("Texture " ~ texFileName ~ " does not exist!"); 
		}
		delete filepath;

		// read SDL image 
		image = IMG_Load(toStringz(texFileName));

		if (image is null)
		{
			logger.error("Failed to load image for texture " ~ texFileName ~ ": " ~ fromStringz(IMG_GetError())); 
    	    throw new Exception("Failed to load image for texture " ~ texFileName);
        }

		// store the original width and height
		Uint32 orig_w = image.w;
		Uint32 orig_h = image.h;
				
		// calculate nearest power-of-two size
		Uint32 pot_w = nextPowerOfTwo(image.w);
		Uint32 pot_h = nextPowerOfTwo(image.h);	
		
		// convert image to 32 bit RGBA image of power of two size if needed 
		if ( ((image.format.BitsPerPixel != 32)) || image.w != pot_w || image.h != pot_h)
		{
			// create new surface of pot size with 32 bit RGBA ordering
			SDL_Surface* newsurf =	SDL_CreateRGBSurface (SDL_SWSURFACE, 
											pot_w, pot_h, 32, 0x000000ff,
											0x0000ff00, 0x00ff0000, 0xff000000);

			// copy old surface data onto the new surface
			SDL_SetAlpha(image, 0, 0); // set alpha to off, so we just copy all the information
			SDL_FillRect(newsurf, null, 0); // fill with transparencity
			SDL_BlitSurface (image, null, newsurf, null);

			// free old surface memory 
			SDL_FreeSurface(image);

			// point the old surface data to the new surface 
			image = newsurf; 
		}

		// increase our texture count
		gTextureCount++; 

		// Bind the texture to the texture arrays index and init the texture
		glBindTexture(GL_TEXTURE_2D, gTextureCount);
		glPixelStorei(GL_UNPACK_ALIGNMENT,1);
   
		// Build Mipmaps (builds different versions of the picture for distances - looks better)
		gluBuild2DMipmaps(	GL_TEXTURE_2D, 4, image.w, image.h, 
							GL_RGBA, GL_UNSIGNED_BYTE, image.pixels);
                     
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

		logger.info("Texture " ~ texFileName ~ " with ID " ~ tango.text.convert.Integer.toString(gTextureCount) ~ " has been loaded.");
		
		// set texture size and ID attributes 
		textureSize_.w = pot_w;
		textureSize_.h = pot_h;
		
		imageSize_.w = orig_w;
		imageSize_.h = orig_h;
		
		ID_ = gTextureCount; 
	}
	
	/// load texture based on SDL_Surface
	void loadTexture(SDL_Surface *surf)
	{
		image = surf; 
		
		if (image is null)
		{
			logger.error("Failed to load image for SDL_Surface* texture " ~ fromStringz(IMG_GetError())); 
    	    throw new Exception("Failed to load image for SDL_Surface* texture");
        }

		// store the original width and height
		Uint32 orig_w = image.w;
		Uint32 orig_h = image.h;
				
		// calculate nearest power-of-two size
		Uint32 pot_w = nextPowerOfTwo(image.w);
		Uint32 pot_h = nextPowerOfTwo(image.h);	
		
		// convert image to 32 bit RGBA image of power of two size if needed 
		if ( ((image.format.BitsPerPixel != 32)) || image.w != pot_w || image.h != pot_h)
		{
			// create new surface of pot size with 32 bit RGBA ordering
			SDL_Surface* newsurf =	SDL_CreateRGBSurface (SDL_SWSURFACE, 
											pot_w, pot_h, 32, 0x000000ff,
											0x0000ff00, 0x00ff0000, 0xff000000);

			// copy old surface data onto the new surface
			SDL_SetAlpha(image, 0, 0); // set alpha to off, so we just copy all the information
			SDL_FillRect(newsurf, null, 0); // fill with transparencity
			SDL_BlitSurface (image, null, newsurf, null);

			// free old surface memory 
			SDL_FreeSurface(image);

			// point the old surface data to the new surface 
			image = newsurf; 
		}

		// increase our texture count
		gTextureCount++; 

		// Bind the texture to the texture arrays index and init the texture
		glBindTexture(GL_TEXTURE_2D, gTextureCount);
		glPixelStorei(GL_UNPACK_ALIGNMENT,1);
   
		// Build Mipmaps (builds different versions of the picture for distances - looks better)
		gluBuild2DMipmaps(	GL_TEXTURE_2D, 4, image.w, image.h, 
							GL_RGBA, GL_UNSIGNED_BYTE, image.pixels);
                     
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

		logger.info("Texture from SDL_Surface with ID " ~ tango.text.convert.Integer.toString(gTextureCount) ~ " has been loaded.");
		
		// set texture size and ID attributes 
		textureSize_.w = pot_w;
		textureSize_.h = pot_h;
		
		imageSize_.w = orig_w;
		imageSize_.h = orig_h;
		
		ID_ = gTextureCount; 
	}
    
	
	void createTexture(Size size, Color defColor)
	{
		gTextureCount++; 
		ID_ = gTextureCount; 
		textureSize_ = size; 
		
		ubyte[] data;
		data.alloc(size.w * size.h * 4);

		uint bitspp = 32;
		uint bytespp = bitspp / 8;
		
		ubyte f2ub(float f) {
			if (f < 0) return 0;
			if (f > 1) return 255;
			return cast(ubyte)rndint(f * 255);
		}

		for (uint i = 0; i < size.w; ++i) {
			for (uint j = 0; j < size.h; ++j) {			
				for (uint c = 0; c < bytespp; ++c) {
					data[cast(uint)((size.w * j + i) * bytespp + c)] = f2ub(defColor.cell(c));
				}
			}
		}
		
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, ID_);
				
		const uint level = 0;
		const uint border = 0;
		GLenum format	= GL_RGBA;
		
		glTexImage2D(GL_TEXTURE_2D, level, bytespp, cast(int)size.w, cast(int)size.h, border, format, GL_UNSIGNED_BYTE, data.ptr);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,	GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,	GL_LINEAR);

		glDisable(GL_TEXTURE_2D);
		data.free();
		
//		debug writefln("Texture font with ID ", ID_, " has been loaded");
	}

public: 
	/// get size of image stored
	Size getSize() { return imageSize_; }

	/// get size of the actual texture surface, mostly used for calculating texture coordinates
	Size getTextureSize() { return textureSize_; }
	
	/// texture ID
	uint getID() { return ID_; }
	
	/// texture file name
	char[] getFile() { return file_.dup; }
    
	/// SDL_Surface that holds the pixel and image data 
	SDL_Surface* getSDLSurface() { return image; } 
    
private:
	uint ID_;
	SDL_Surface *image=null; 
	Size textureSize_;
	Size imageSize_;
	char[] file_;
}

/// Texture based on filename alone and return texture 
Texture load(char[] argFileName) 
{
	return Texture(argFileName); 
}

/// Enable texturing
void enableTexturing(Texture tex) 
{
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, tex.getID);
}

///
void updateTexture(inout Texture tex, Point origin, Size size, ubyte[] data) 
{
	glPushAttrib(GL_TEXTURE_2D); 
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, tex.getID);
	
	const int level = 0;
	glTexSubImage2D(GL_TEXTURE_2D, level, cast(int)origin.x, cast(int)origin.y, cast(int)size.w, cast(int)size.h, GL_RGBA, GL_UNSIGNED_BYTE, data.ptr);
	
	glPopAttrib(); 
}

/// Will create new SDL surface based on sub-image coords 
SDL_Surface *getSubSDLSurface(SDL_Surface *orig, int x, int y, int w, int h)
{
	// create new surface of pot size with 32 bit RGBA ordering
	SDL_Surface* newsurf =	
		SDL_CreateRGBSurface (SDL_SWSURFACE, w, h, 32, 
				0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);
	
	// build our rect 
	SDL_Rect *rect = new SDL_Rect; 
	rect.x = x;
	rect.y = y;
	rect.w = w; 
	rect.h = h; 
	
	SDL_Rect *dst = new SDL_Rect;
	dst.x=dst.y=0;
	dst.w = w;
	dst.h = h; 
	
	// copy old surface data onto the new surface
	SDL_SetAlpha(orig, 0, 0); // set alpha to off, so we just copy all the information
	SDL_FillRect(newsurf, null, 0); // fill with transparencity
	
	SDL_BlitSurface (orig, rect, newsurf, dst);
	
	//SDL_SaveBMP(newsurf, ("bitmap" ~ tango.text.convert.Integer.toString(gTextureCount) ~ ".bmp").ptr); 

	return newsurf; 
}