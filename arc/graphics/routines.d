/*******************************************************************************

Description: Utilities useful for 2D graphics programming

Authors: Clay Smith

Liscense: See <a href="http://www.opensource.org/licenses/zlib-license.php">zlib/libpng license</a>

Examples:
--------------------
import arc.gfx.gfxutil; 

int main() {

	SDL_Surface *img = IMG_Load("fontmap.png");

	short[4][] font_coords;

	// extract font coordinates from filename image using color red as the cell line color
	font_coords = arc.gfx.gfxutil.mapCoords("fontmap.png", 255, 0, 0);

	// extract font coordinates from SDL surface using color red as the cell line color
	font_coords = arc.gfx.gfxutil.mapCoords(surface, 255, 0, 0);

	// get pixel int SDL surface
	Uint32 pixel = getpixel(surface, 0, 0);

	return 0;
}
--------------------

*******************************************************************************/

module arc.graphics.routines; 

private import 
	arc.texture;

private import 
	derelict.sdl.sdltypes,
	derelict.sdl.sdlfuncs; 

private import tango.util.log.Log; 

/// logger for this module
public Logger logger;

static this()
{
	// setup logger
	logger = Log.getLogger("arc.graphics.routines");
}

/// transparent pixel 
const Uint32 transparent = 16777215;

/// function will return the pixel color of SDL surface at x,y
Uint32 getpixel(SDL_Surface *surface, int x, int y)
{
	int bpp = surface.format.BytesPerPixel;
	/* Here p is the address to the pixel we want to retrieve */
	Uint8 *p = cast(Uint8 *)surface.pixels + y * surface.pitch + x * bpp;

	switch(bpp) 
	{
		case 1:
			return *p;
		break;      

		case 2:
			return *cast(Uint16 *)p;
		break;   

		case 3:
			if(SDL_BYTEORDER == SDL_BIG_ENDIAN)
				return p[0] << 16 | p[1] << 8 | p[2];
			else
				return p[0] | p[1] << 8 | p[2] << 16;
		break;      

		case 4:
			return *cast(Uint32 *)p;
		break;       
	}

	logger.fatal("getpixel failed."); 
	assert(0); 
}

/// returns array of coordinates from a prison cell image given SDL image 
short[4][] mapCoords(SDL_Surface *img, Uint8 r, Uint8 g, Uint8 b)
{
	return mapCoordsCore(img,r,g,b, false);
}

/// returns array of coordinates from a prison cell image given filename
short[4][] mapCoords(char[] fullFileName, Uint8 r, Uint8 g, Uint8 b)
{
	Texture tex = Texture(fullFileName,true);
	return mapCoordsCore(tex.getSDLSurface,r,g,b, true);
}

/// returns array of coordinates from a prison cell image 
short[4][] mapCoordsCore(SDL_Surface *img, Uint8 r, Uint8 g, Uint8 b, bool free)
in
{
	assert(img !is null);
}
body
{
	logger.info("mapCoordsCore ");
	
	// the end array we will give back
	short[4][] arr;
	arr.length = 0;

	// all the height numbers
	short[] height;   

	// number of cells
	int numCell = 0;

	// coordinate will will be filling for each cell   
	short[4] coord;

	// translate r, g, b into pixel number
	Uint32 pixel = SDL_MapRGB(img.format, r, g, b);

	// zero is given as the top of the grid
	height ~= 0;

	// every line in between
	for (int i = 0; i < img.h; i++)
		if (getpixel(img, 0, i) == pixel)
			height ~= i+1;

	// -1 to get the edge, +2 for offset purposes
	height ~= img.h-1+2;

	int prevWidth;

	// for every vertical cell
	for (int i = 0; i < height.length-1; i++)
	{
		// determine # in width
		int numWidth = 0;

		// for every horoz cell
		for (int w = 0; w < img.w; w++)  
		{
			  
			if (getpixel(img, w, height[i]) == pixel)
			{
				// increase array length
				arr.length = arr.length + 1;
				
				if (numWidth == 0)
					coord[0] = 0;
				else
					coord[0] = prevWidth+1;

				coord[1] = height[i];

				coord[2] = w-1;
				coord[3] = height[i+1]-2;

				assignArr(arr[arr.length-1], coord);

	//            logger.info(coord[0] ~ " " ~ coord[1] ~ " " ~ coord[2] ~ " " ~ coord[3]);
				numWidth++;
				prevWidth = w;
			}

		}

		// get the last cell on the line

		// given edge
		arr.length = arr.length + 1;
		
		short[4] coordArr;

		if (numWidth == 0)
			coordArr[0] = 0;
		else 
			coordArr[0] = prevWidth+1;

		coordArr[1] = height[i];

		coordArr[2] = img.w;//-1;

		coordArr[3] = height[i+1]-1;//-2;

		assignArr(arr[arr.length-1], coordArr);

		//writefln("last ", coordArr[0], " ", coordArr[1], " ", coordArr[2], " ", coordArr[3]);

	} // for height

	// only free surface if we allocated the image in the first place
	if (free)
	{
		SDL_FreeSurface(img);
		delete img;
		img = null;  
	}

	logger.info("util: map coords end");

	 return arr;
}

/// returns an array of SDL surfaces extracted with given coords
Texture[] getSurfaces(SDL_Surface *surf, inout short[4][] coords)
{
	logger.info("util: getSurfaces");
	
	// create image data
	Texture[] dat; 
	dat.length = coords.length;

	// get SDL surface for each
	for (int i = 0; i < coords.length; i++)
	{
		//1) Define coordinates into SDL rects
		// src
		SDL_Rect sr;
		sr.x = coords[i][0];
		sr.y = coords[i][1];
		sr.w = coords[i][2];
		sr.h = coords[i][3];

		if (i+33 == 'j')
			logger.info(" coord x y w h ", sr.x, " ", sr.y, " ", sr.w, " ", sr.h);

		// dst
		SDL_Rect dr;

		dr.x = dr.y = 0;
		dr.w = sr.w - sr.x;
		dr.h = sr.h - sr.y;

		if (i+33 == 'j')
			logger.info(" dr x y w h ", dr.x, " ", dr.y, " ", dr.w, " ", dr.h);

		// create new SDL surface
		dat[i].setSDLSurface( SDL_CreateRGBSurface(SDL_SWSURFACE|SDL_SRCALPHA, 
		sr.w - sr.x, sr.h - sr.y, 32, 
		0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000) );

		//if (i+33 == 'j')
		//	logger.info("new surf w h ", dat[i].surf.w, ", ", dat[i].surf.h);

		// blit into new SDL surface
		SDL_BlitSurface  (surf, &sr, dat[i].getSDLSurface, &dr);
	}

	return dat;
}

/// make array assigning easy
void assignArr(short[4] src, short[4] dst)
{
	for (int i = 0; i < 4; i++)
		src[i] = dst[i];
}