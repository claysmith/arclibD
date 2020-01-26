
/*******************************************************************************

   PerPixel map used for per pixel collision detection. Loads an image and 
   creates a collision map for it. Not recommended to use by itself, use 
   PixFrame instead.
     
   Date: (2005): initial version
         (2009): Updated version
   
   Authors: Clay Smith
   
   Liscense: 
      See <a href="http://www.opensource.org/licenses/zlib-license.php">zlib/libpng license</a>
      with exception of drawCircle (see source) taken from SDL_gfx which is 
      <a href="http://www.opensource.org/licenses/lgpl-license.php">lgpl</a>

Examples:
-------------------------------------------------------------------------------
import arc.phy.collision.perpixel;

int main() {
   
   PerPixel map = new CollisionMap("img.png"); 
   PerPixel map2 = new CollisionMap("img2.png");

   if (map.perPixelCollision(map2))
   {
      // we have per pixel collision between the two images
   }

   map2.setPosition(50,50);
   map.draw();

   return 0;
}
-------------------------------------------------------------------------------
*******************************************************************************/

module arc.x.perpixel.perpixel; 

private import 
	arc.draw.color,
	arc.draw.shape,
	arc.draw.image,
	arc.draw.attributes, 
	arc.math.point,
	arc.math.size,
	arc.math.collision, 
	arc.graphics.routines,
	arc.texture; 

private import tango.util.log.Log, tango.io.Console, tango.text.convert.Integer; 

/// logger for this module
private Logger logger;

static this()
{
	// setup logger
	logger = Log.getLogger("arc.perpixel.perpixel");
}

import derelict.opengl.gl,
	derelict.sdl.sdltypes,
	derelict.sdl.sdlfuncs;

/// maps everything except alpha transparent pixels as true into the collision map to perform per pixel collisions 
class PerPixel
{
	public:

	/// create collision from a given filename
	this(char[] fileName)
	{
		// load texture and save SDL surface
		tex = Texture(fileName, true); 

		assert(tex.getSDLSurface !is null); 

		setCollisionBools(tex.getSDLSurface); 

		tex.freeSDLSurface(); 
	}

	/// create a collision map based on the intersection of two boxes
	this(Point p1, Size s1, Point p2, Size s2, inout Point pos)
	{
		float width = 0, height = 0;
		float ex, why; 

		// do a swap, as this function will only work with the 
		// larger frame being s1 for both width and height
		if (s1.getWidth < s2.getWidth)
		{
			float tmp = s1.getWidth;
			s1.setWidth(s2.getWidth);
			s2.setWidth(tmp);

			tmp = p1.getX;
			p1.setX(p2.getX);
			p2.setX(tmp);
		}
		if (s1.getHeight < s2.getHeight)
		{
			float tmp = s1.getHeight;
			s1.setHeight(s2.getHeight);
			s2.setHeight(tmp);

			tmp = p1.getY;
			p1.setY(p2.getY);
			p2.setY(tmp);
		}

		// forumula found with lots of testing
		// right side
		if (p1.getX >= p2.getX && p1.getX <= (p2.getX+s2.getWidth))
		{
			ex = p1.getX;
			why = p1.getY;
			width = (p2.getX+s2.getWidth)-p1.getX;

			// below
			if (p1.getY >= p2.getY && p1.getY <= p2.getY+s2.getHeight)
			{
				height = (p2.getY+s2.getHeight) - p1.getY;
				//debug writefln("right bottom");
			}
			// above
			else if (p1.getY+s1.getHeight >= p2.getY && p1.getY+s1.getHeight <= p2.getY+s2.getHeight)
			{
				ex = p1.getX;
				why = p2.getY;
				height = p1.getY+s1.getHeight-p2.getY;

				//debug writefln("right top");

			}
			// middle
			else if (p1.getY <= p2.getY && p1.getY + s1.getHeight >= p2.getY + s2.getHeight)
			{
				ex = p1.getX;
				why = p2.getY;

				height = s2.getHeight;

				//debug writefln("right middle");
			}
		}
		// left side
		else if ( 	(p1.getX+s1.getWidth) >= p2.getX && (p1.getX+s1.getWidth) <= (p2.getX+s2.getWidth))
		{
			ex = p2.getX;
			why = p1.getY;
			width = (p1.getX+s1.getWidth)-p2.getX;

			// below
			if (p1.getY >= p2.getY && p1.getY <= p2.getY+s2.getHeight)
			{
				height = (p2.getY+s2.getHeight) - p1.getY;
			}
			// above
			else if (p1.getY+s1.getHeight >= p2.getY && p1.getY+s1.getHeight <= p2.getY+s2.getHeight)
			{
				ex = p2.getX;
				why = p2.getY;
				height = p1.getY+s1.getHeight-p2.getY;
			}
			// middle
			else if (p1.getY <= p2.getY && p1.getY + s1.getHeight >= p2.getY + s2.getHeight)
			{
				ex = p2.getX;
				why = p2.getY;

				height = s2.getHeight;
			}
		}
		// middle
		else if (p1.getX <= p2.getX && p1.getX + s1.getWidth >= p2.getX + s2.getWidth)
		{
			width = s2.getWidth;

			// below
			if (p1.getY >= p2.getY && p1.getY <= p2.getY+s2.getHeight)
			{
				ex = p2.getX;
				why = p1.getY;
				height = (p2.getY+s2.getHeight) - p1.getY;
			}
			// above
			else if (p1.getY+s1.getHeight >= p2.getY && p1.getY+s1.getHeight <= p2.getY+s2.getHeight)
			{
				ex = p2.getX;
				why = p2.getY;
				height = p1.getY+s1.getHeight-p2.getY;
			}
			// middle
			else if (p1.getY <= p2.getY && p1.getY + s1.getHeight >= p2.getY + s2.getHeight)
			{
				ex = p2.getX;
				why = p2.getY;
				height = s2.getHeight;
			}
		}

		// we have a valid collision map
		if (width != 0 && height != 0)
		{
			// setup collision bools based on found width and height
			setCollisionBools(cast(int)width, cast(int)height, true);

			// calculate position
			//setPosition(ex,why);
			pos = Point(ex,why);
		}

		//drawRect(ex, why, width, height, 0,0,255,255,true);

		// otherwise don't bother with a map
	}

	///creates a collision map based on the radius of a circle
	this(float gx, float gy, float r, float width, float height)
	{
		// we start with creating the map and setting all bools to false
		debug assert(r != 0);

		setCollisionBools(cast(int)(r+r-1),cast(int)(r+r), false);

		// we then use a special algorithm to draw the circle on the collision map
		drawCircle(cast(Sint16)r, width, height);
		//setPosition(gx-r,gy-r);
	}

	/// return texture
	Texture getTexture() { return tex; }

	/// draw map with previous color
	void draw(Color col)
	{	   
		drawImageTopLeft(tex, pos, tex.getSize, col); 
	}

	/// test given collision map against this map for per pixel collision
	bool pixelCollision(PerPixel col)
	{
		// box col is a quick way to end test if they arn't close
		if (boxCol(col))
			// box1.getX -- box1.getX+box1.w
			for (float i =  pos.x; i <  pos.x + tex.getSize.getWidth; i++)
				// box1.getY -- box1.getY+box1.h
				for (float j =  pos.y; j <  pos.y + tex.getSize.getHeight; j++)  
					// if px is within range of box2
					if (i > col.getPosition.x && i < col.getPosition.x + col.getWidth) 
						// if py is within range of box2
						if (j > col.getPosition.y && j < col.getPosition.y + col.getHeight)
							// if it's a solid pixel on the first box
							if (( collision[cast(int)(i - pos.x)][cast(int)(j - pos.y)] ) &&
								// and a solid pixel on the second box, we have collision 
								col.collision[cast(int)(i - col.getPosition.x)][cast(int)(j - col.getPosition.y)]) 
								return true;

		return false;
	}

	/// check to see if point x,y collides with collision map
	bool xyCol(Point arg)
	{
		if (boxCol(arg))
		{
			if (collision[cast(int)(arg.x - pos.x)][cast(int)(arg.y - pos.y)])
			{
			return true; 
			}
		}

		return false; 
	}

	/// print collision bools
	void printCollision()
	in
	{
		assert(collision.length != 0);
		assert(collision[0].length != 0);
	}
	body
	{
		char[] outstr="\n"; 

		for (int width = 0; width < collision.length; width++)
		{
			for (int height = 0; height < collision[0].length; height++)
			{  
				if (collision[width][height] == true)
				{
					outstr ~= "1 ";
				}
				else
				{
					outstr ~= "0 ";
				}
			}
				outstr ~= "\n ";
		}

		logger.info(outstr); 
	}


	/// from x1 to x2 fill collision map
	void fillHoroz(int x1, int x2, int y1)
	{
		for (int m = x1; m < x2; m++)
		{
			collision[y1][m] = true;
		}
	}

	/// lgpl taken from SDL_gfx and modified filled in circle
	bool drawCircle(Sint16 r, float width, float height)
	{
		Sint16 x = r;
		Sint16 y = r-1; 

		// loads of vars
		Sint16 left, right, top, bottom;
		Sint16 x1, y1, x2, y2;
		Sint16 cx = 0;
		Sint16 cy = r;
		Sint16 ocx = cast(Sint16) 0xffff;
		Sint16 ocy = cast(Sint16) 0xffff;
		Sint16 df = 1 - r;
		Sint16 d_e = 3;
		Sint16 d_se = -2 * r + 5;
		Sint16 xpcx, xmcx, xpcy, xmcy;
		Sint16 ypcy, ymcy, ypcx, ymcx;

		/*
		* Sanity check radius 
		*/
		if (r <= 0) 
			return false;

		/*
		* Get clipping boundary 
		*/
		left =   cast(Sint16)x;
		right =  cast(Sint16)(x + width - 1);
		top =    cast(Sint16)y;
		bottom = cast(Sint16)(y + height - 1);

		/*
		* Test if bounding box of circle is visible 
		*/
		x1 = x - r;
		x2 = x + r;
		y1 = y - r;
		y2 = y + r;

		if ((x1<left) && (x2<left)) 
		{
			return false;
		} 
		if ((x1>right) && (x2>right)) 
		{
			return false;
		} 
		if ((y1<top) && (y2<top)) 
		{
			return false;
		} 
		if ((y1>bottom) && (y2>bottom)) 
		{
			return false;
		} 

		/*
		* Draw 
		*/
		do 
		{
			xpcx = x + cx;
			xmcx = x - cx;
			xpcy = x + cy;
			xmcy = x - cy;
			if (ocy != cy) 
			{
				if (cy > 0) 
				{
					ypcy = y + cy;
					ymcy = y - cy;
					fillHoroz(xmcx, xpcx, ypcy);
					fillHoroz(xmcx, xpcx, ymcy);
				} 
				else 
				{
					fillHoroz(xmcx, xpcx, y);
				}
				ocy = cy;
			}
			if (ocx != cx) 
			{
				if (cx != cy) 
				{
					if (cx > 0) 
					{
						ypcx = y + cx;
						ymcx = y - cx;
						fillHoroz(xmcy, xpcy, ymcx);
						fillHoroz(xmcy, xpcy, ypcx);
					} 
					else 
					{
						fillHoroz(xmcy, xpcy, y);
					}
				}
				ocx = cx;
			}
			/*
			* Update 
			*/
			if (df < 0) 
			{
			df += d_e;
			d_e += 2;
			d_se += 2;
			} else {
			df += d_se;
			d_e += 2;
			d_se += 4;
			cy--;
			}
			cx++;
		} while (cx <= cy);

		return true;
	}

	/// set the collision bools as appropriate for the surface
	void setCollisionBools(SDL_Surface *surf)
	{  
		collision.length = surf.w;

		for (int i = 0; i < collision.length; i++)
		collision[i].length = surf.h;

		for (int width = 0; width < surf.w; width++)
		{
			for (int height = 0; height < surf.h; height++)
			{     
				Uint32 color = getpixel(surf, width, height); 

				// these colors found by testing
				if (color >= 0 && color <= transparent)
				collision[width][height] = false;
				else
				collision[width][height] = true;
			}
		}
	}

	/// set collision bools as all true based on given width and height - used for box-pixel collision
	void setCollisionBools(int argWidth, int argHeight, bool setTo)
	{
		// grow dynamic array to given size
		collision.length = argWidth;
		for (int i = 0; i < collision.length; i++)
			collision[i].length = argHeight;

		// just set collision map to true 
		for (int width = 0; width < argWidth; width++)
			for (int height = 0; height < argHeight; height++)
				collision[width][height] = setTo;
	}

	/// test box against another collision map, used to speed up per pixel collision
	bool boxCol(PerPixel col)
	{
		return boxBoxCollision(pos, tex.getSize, col.getPosition, col.getSize); 
	}

	/// check point for collision against box, used to speed up per pixel collision tests
	bool boxCol(Point arg)
	{
		return boxXYCollision(arg, pos, tex.getSize); 
	}

	/// draw box around image
	void drawBox()
	{
		DrawAttributes attr; 
		attr.fill = Color.White; 
		attr.isFill = false; 
		
		drawRectangle(pos, tex.getSize, attr); 
	}

	///
	float getWidth() { return tex.getSize.getWidth; }
	///
	float getHeight() { return tex.getSize.getHeight; }
	/// 
	Size getSize() { return tex.getSize; }

	///
	float getX() { return pos.x; }
	///
	float getY() { return pos.y; }
	/// 
	Point getPosition() { return pos; }
	/// set position
	void setPosition(Point p) { pos = p; } 

  private:
	Texture tex;

	Point pos; 

	// collision map representing pixels
	bool[][] collision; 
}