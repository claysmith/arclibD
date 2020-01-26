/*******************************************************************************

	Color type

	Authors:       ArcLib team, see AUTHORS file
	Maintainer:    Clay Smith (clayasaurus at gmail dot com)
	License:       zlib/libpng license: $(LICENSE)
	Copyright:     ArcLib team

    Description:
		Color type, simplifies color for parameter passing. Note that
		the color values are stored as floats in the 0.0 .. 1.0 range.


	Examples:
	--------------------
	import arc.types;

	int main()
	{
		Color c = Color(255,255,255);
		Color c = Color(255,255,255,255);
		Color c = Color(1.0, 0.5, 0.1);
		Color c = Color.Yellow;

		c.setGlColor(); // equivalent to glColor4f(c.r,c.g,c.b,c.a);

		return 0;
	}
	--------------------

*******************************************************************************/

module arc.draw.color;

import arc.types;
import derelict.opengl.gl;

import
	tango.text.convert.Integer;

/// holds red, green, blue and alpha values in floating point representation
struct Color
{
	/**
		Constructs a color.

		If the type of the arguments is implicitly convertible to ubyte,
		the arguments should be in the 0..255 range and the alpha value
		defaults to 255.
		If it is implicitly convertible to float, the colors range from
		0.0 to 1.0 and the default alpha value is 1.0.
	**/
	static Color opCall(T)(T r, T g, T b, T a = DefaultColorValue!(T))
	{
		Color c;

		static if(is(T : ubyte))
		{
			c.r = r;
			c.g = g;
			c.b = b;
			c.a = a;
		}
		else static if(is(T : float))
		{
			c.r = cast(ubyte)(r*255);
			c.g = cast(ubyte)(g*255);
			c.b = cast(ubyte)(b*255);
			c.a = cast(ubyte)(a*255);
		}
		else
			static assert(false, "Colors can only be constructed from values implicitly convertible to ubyte or float.");

		return c;
	}

	/// predefined white color
	const static Color White = {255,255,255};
	/// predefined black color
	const static Color Black = {0,0,0};
	/// predefined red color
	const static Color Red = {255,0,0};
	/// predefined green color
	const static Color Green = {0,255,0};
	/// predefined blue color
	const static Color Blue = {0,0,255};
	/// predefined yellow color
	const static Color Yellow = {255,255,0};
	///
	const static Color AliceBlue = {240, 248, 255};
	///
	const static Color AntiqueWhite= {250, 235, 215};
	///
	const static Color Aqua = {0, 255, 255};
	///
	const static Color Aquamarine= {127, 255, 212 };
	///
	const static Color Azure= {240, 255, 255};
	///
	const static Color Beige = {245, 245, 220};
	///
	const static Color Blanchedalmond = {255, 235, 205};
	///
	const static Color Blueviolet = {138, 43, 226};
	///
	const static Color Brown = {165, 42, 42};
	///
	const static Color Burlywood = {222, 184, 135};
	///
	const static Color Bisque = {255, 228, 196};
	///
	const static Color Cadetblue = {95, 158, 160};
	///
	const static Color Chartreuse = {127, 255, 0};
	///
	const static Color Chocolate = {210, 105, 30};
	///
	const static Color Coral = {255, 127, 80};
	///
	const static Color Cornflowerblue = {100, 149, 237};
	///
	const static Color Cornsilk = {255, 248, 220};
	///
	const static Color Crimson = {220, 20, 60};
	///
	const static Color Cyan = { 0, 255, 255 };
	///
	const static Color Darkblue = {0, 0, 139};
	///
	const static Color Darkgreen = {0, 100, 0};
	///
	const static Color Darkcyan = {0, 139, 139};
	///
	const static Color Darkgoldenrod = {184, 134, 11};
	///
	const static Color Darkgray = {169, 169, 169};
	///
	const static Color Darkkhaki = {189, 183, 107};
	///
	const static Color Darkmagenta = {139, 0, 139};
	///
	const static Color Darkolivegreen = {85, 107, 47};
	///
	const static Color Darkorange = {255, 140, 0};
	///
	const static Color Darkorchid = {153, 50, 204};
	///
	const static Color Darkred = {139, 0, 0};
	///
	const static Color Darksalmon = {233, 150, 122};
	///
	const static Color Darkseagreen = {143, 188, 143};
	///
	const static Color Darkslateblue = {72, 61, 139};
	///
	const static Color Darkslategray = {47, 79, 79};
	///
	const static Color Darkturquoise = {0, 206, 209};
	///
	const static Color Darkviolet = {148, 0, 211};
	///
	const static Color Deeppink = {255, 20, 147};
	///
	const static Color Deepskyblue = {0, 191, 255};
	///
	const static Color Dimgray = {105, 105, 105};
	///
	const static Color Dodgerblue = {30, 144, 255};
	///
	const static Color Firebrick = {178, 34, 34};
	///
	const static Color Floralwhite = {255, 250, 240};
	///
	const static Color Forestgreen = {34, 139, 34};
	///
	const static Color Fuchsia = {255, 0, 255};
	///
	const static Color Gainsboro = {220, 220, 220};
	///
	const static Color Ghostwhite = {248, 248, 255};
	///
	const static Color Gold = {255, 215, 0};
	///
	const static Color Goldenrod = {218, 165, 32};
	///
	const static Color Gray = {128, 128, 128};
	///
	const static Color Greenyellow = {173, 255, 47};
	///
	const static Color Honeydew = {240, 255, 240};
	///
	const static Color Hotpink = {255, 105, 180};
	///
	const static Color Indianred = {205, 92, 92};
	///
	const static Color Indigo = {75, 0, 130};
	///
	const static Color Ivory = {255, 255, 240};
	///
	const static Color Khaki = {240, 230, 140};
	///
	const static Color Lavender = {230, 230, 250};
	///
	const static Color Lavenderblush = {255, 240, 245};
	///
	const static Color Lawngreen = {124, 252, 0};
	///
	const static Color Lemonchiffon = {255, 250, 205};
	///
	const static Color Lightblue = {173, 216, 230};
	///
	const static Color Lightcoral = {240, 128, 128};
	///
	const static Color Lightcyan = {224, 255, 255};
	///
	const static Color Lightgoldenrodyellow = {250, 250, 210};
	///
	const static Color Lightgray = {211, 211, 211};
	///
	const static Color Lightgreen = {144, 238, 144};
	///
	const static Color Lightpink = {255, 182, 193};
	///
	const static Color Lightsalmon = {255, 160, 122};
	///
	const static Color Lightseagreen = {32, 178, 170};
	///
	const static Color Lightskyblue = {135, 206, 250};
	///
	const static Color Lightslategray = {119, 136, 153};
	///
	const static Color Lightsteelblue = {176, 196, 222};
	///
	const static Color Lightyellow = {255, 255, 224};
	///
	const static Color Lime = {0, 255, 0};
	///
	const static Color Limegreen = { 50, 205, 50};
	///
	const static Color Linen = {250, 240, 230};
	///
	const static Color Magenta = {255, 0, 255};
	///
	const static Color Maroon = {128, 0, 0};
	///
	const static Color Mediumaquamarine = {102, 205, 170};
	///
	const static Color Mediumblue = {0, 0, 205};
	///
	const static Color Mediumorchid = {186, 85, 211};
	///
	const static Color Mediumpurple = {147, 112, 219};
	///
	const static Color Mediumseagreen = {60, 179, 113};
	///
	const static Color Mediumslateblue = {123, 104, 238};
	///
	const static Color Mediumspringgreen = {0, 250, 154};
	///
	const static Color Mediumturquoise = {72, 209, 204};
	///
	const static Color Mediumvioletred = {199, 21, 133};
	///
	const static Color Midnightblue = {25, 25, 112};
	///
	const static Color Mintcream = {245, 255, 250};
	///
	const static Color Mistyrose = {255, 228, 225};
	///
	const static Color Moccasin = {255, 228, 181};
	///
	const static Color Navajowhite = {255, 222, 173};
	///
	const static Color Navy = {0, 0, 128};
	///
	const static Color Oldlace = {253, 245, 230};
	///
	const static Color Olive = {128, 128, 0};
	///
	const static Color Olivedrab = {107, 142, 35};
	///
	const static Color Orange = {255, 165, 0};
	///
	const static Color Orangered = {255, 69, 0};
	///
	const static Color Orchid = {218, 112, 214};
	///
	const static Color Palegoldenrod = {238, 232, 170};
	///
	const static Color Palegreen = {152, 251, 152};
	///
	const static Color Paleturquoise = {175, 238, 238};
	///
	const static Color Palevioletred = {219, 112, 147};
	///
	const static Color Papayawhip = {255, 239, 213};
	///
	const static Color Peachpuff = {255, 218, 185};
	///
	const static Color Peru = {205, 133, 63};
	///
	const static Color Pink = {255, 192, 203};
	///
	const static Color Plum = {221, 160, 221};
	///
	const static Color Powderblue = {176, 224, 230};
	///
	const static Color Purple = {128, 0, 128};
	///
	const static Color Rosybrown  = {188, 143, 143};
	///
	const static Color Royalblue = {65, 105, 225};
	///
	const static Color Saddlebrown = {139, 69, 19};
	///
	const static Color Salmon = {250, 128, 114};
	///
	const static Color Sandybrown = {244, 164, 96};
	///
	const static Color Seagreen = {46, 139, 87};
	///
	const static Color Seashell = {255, 245, 238};
	///
	const static Color Sienna = {160, 82, 45};
	///
	const static Color Silver = {192, 192, 192};
	///
	const static Color Skyblue = {135, 206, 235};
	///
	const static Color Slateblue = {106, 90, 205};
	///
	const static Color Slategray = {112, 128, 144};
	///
	const static Color Snow = {255, 250, 250};
	///
	const static Color Springgreen = {0, 255, 127};
	///
	const static Color Steelblue = { 70, 130, 180};
	///
	const static Color Tan = {210, 180, 140};
	///
	const static Color Teal = {0, 128, 128};
	///
	const static Color Thistle = {216, 191, 216};
	///
	const static Color Tomato = {255, 99, 71};
	///
	const static Color Turquoise = {64, 224, 208};
	///
	const static Color Violet = {238, 130, 238};
	///
	const static Color Wheat = {245, 222, 179};
	///
	const static Color Whitesmoke = {245, 245, 245};
	///
	const static Color Yellowgreen = {154, 205, 50};

	/// get Red value
	ubyte getR() {return r;}

	/// get Green value
	ubyte getG() {return g;}

	/// get Blue value
	ubyte getB() {return b;}

	/// set Alpha value
	ubyte getA() {return a;}


	/**
	 * Set color values from a 32-bit unsigned integer
	 * Params:
	 *     c32 = a color in the format 0xrrggbbaa
	 */
	void setU32(uint c32)
	{
		r = cast(ubyte)((0xFF000000 & c32) >> 24);
		g = cast(ubyte)((0x00FF0000 & c32) >> 16);
		b = cast(ubyte)((0x0000FF00 & c32) >> 8);
		a = cast(ubyte)(0x000000FF & c32);
	}

	/// set Red value
	void setR(ubyte argV) {r = argV;}

	/// set Green value
	void setG(ubyte argV) {g = argV;}

	/// set Blue value
	void setB(ubyte argV) {b = argV;}

	/// set Alpha value
	void setA(ubyte argV) {a = argV;}

	/// Get color as unsigned 32-bit integer in the format 0xrrggbbaa
	uint getU32()
	{
		return (r << 24) | (g << 16) | (b << 8) | a;
	}

	/// performs the OpenGL call required to set a color
	void setGLColor()
	{
		glColor4ub(r, g, b, a);
	}

	///
	ubyte cell(int index)
	{
		switch(index)
		{
			case 0:
				return r;
				break;
			case 1:
				return g;
				break;
			case 2:
				return b;
				break;
			case 3:
				return a;
				break;
			default:
				assert(false, "Error: parameter of Color.cell must be in 0..3, but was " ~ .toString(index));
		}
	}

	///
	void brighten()
	{
		r ++; // 1/255
		g ++;
		b ++;
	}

	///
	void darken()
	{
		r--; // 1/255
		g--;
		b--;
	}

	/// returns "r - 255 g - 255 b - 255" or similar
	char[] toString()
	{
		return ( "r - " ~ .toString(cast(int)r) ~ " g - " ~  .toString(cast(int)g) ~ " b - " ~ .toString(cast(int)b)  ~ " a - " ~ .toString(cast(int)a) );
	}

	ubyte r=255, g=255, b=255, a=255;

private:
	// see the constructor for details
	template DefaultColorValue(T)
	{
		static if(is(T : ubyte))
			const T DefaultColorValue = 255;
		else static if(is(T : float))
			const T DefaultColorValue = 1.;
		else
			const T DefaultColorValue = T.init;
	}
}


unittest // For the setU32 and getU32 code
{
	Color c = Color(0xaa, 0xbb, 0xcc, 0xdd);
	assert(c.getU32() == 0xaabbccdd);
	c.setU32(0x11223344);
	assert(c.r == 0x11);
	assert(c.g == 0x22);
	assert(c.b == 0x33);
	assert(c.a == 0x44);
}
