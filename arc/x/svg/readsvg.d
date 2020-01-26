module arc.x.svg.readsvg;

import
	tango.text.Util,
	tango.text.convert.Integer,
	tango.text.convert.Float,
	tango.text.xml.Document, 
	tango.io.Console,
	tango.io.FilePath,
	tango.io.File,
	tango.util.log.Log;

import
	arc.math.point, 
	arc.draw.color,
	arc.draw.shape,
	arc.draw.attributes;

import derelict.opengl.gl; 

// XMLNode structure
import arc.types; 

/// logger for this module
public Logger log;

static this()
{
	// setup logger
	log = Log.getLogger("arc.x.svg.readsvg");
}

struct SVGData
{
	char[] width, height; 
	char[] ver; 
	
	public void addCircle(Point argP, float argR, DrawAttributes argAttr)
	{	
		//elements.length = elements.length+1; 
		//int curr = elements.length -1; 
		
		//elements[curr] = new Circle(argP, argR, argAttr); 
	}
	
	void draw()
	{
		//foreach(e; elements)
		//{
		//	e.draw(); 
		//}
	}
	
	//public Element[] elements; 
}

// readSVG file 
SVGData readSVG(char[] argFile)
{
	SVGData svg; 
	
	// check exist 
	auto filepath = new FilePath(argFile);
	if (!filepath.exists())
	{
		log.fatal("SVG File " ~ argFile ~ " does not exist!"); 
		throw new Exception("File " ~ argFile ~ " does not exist!"); 
	} 
	
	// load up this XML file
	File file = new File(argFile); 
	
	auto doc = new XMLDoc;
	doc.parse(cast(char[])file.read());
	
	// get our 'root' 
	auto root = doc.elements; 
	
	foreach (attr; root.attributes())
	{
		if (attr.name == "width")
		{
			svg.width = attr.value; 
		}
		if (attr.name == "height")
		{
			svg.height = attr.value; 
		}
		if (attr.name == "version")
		{
			svg.ver = attr.value; 
		}
	}
	
	log.info("SVG Width: " ~ svg.width); 
	log.info("SVG Height: " ~ svg.height); 
	log.info("SVG Version: " ~ svg.ver); 
	
	recurseReadSVG(svg, root); 
	
	return svg; 
}

// Recursively print all Nodes in the xml tree
void recurseReadSVG(inout SVGData svg, XMLNode node)
{
	// For each xml node 
	foreach (XMLNode child; node.children())
	{
		char[] name = child.name(); 
		
		char[] cx, cy, r; 
		
		// Generic draw attributes 
		DrawAttributes drawAttr; 
		
		/*
		  <circle cx="100" cy="50" r="40" stroke="black"
		 	stroke-width="2" fill="red"/>
		*/
		
		// read attributes
		foreach(attr; child.attributes())
		{
			if (attr.name == "cx")
			{
				cx = attr.value; 
			}
			if (attr.name == "cy")
			{
				cy = attr.value; 
			}
			if (attr.name == "r")
			{
				r = attr.value; 
			}
			if (attr.name == "stroke")
			{
				drawAttr.stroke = svgColorMap(attr.value); 
			}
			if (attr.name == "strokeWidth")
			{
				drawAttr.strokeWidth = toFloat(attr.value); 
			}
			if (attr.name == "fill")
			{
				drawAttr.fill = svgColorMap(attr.value);
			}
		}
					
		if (name == "circle")
		{
			svg.addCircle(Point(toFloat(cx), toFloat(cy)), toFloat(r), drawAttr); 
			log.info("Add circle cx: " ~ cx ~ " cy: " ~ cy ~ " r: " ~ r ~ " stroke: " ~ drawAttr.stroke.toString() ~ "strokeWidth: " ~ tango.text.convert.Float.toString(drawAttr.strokeWidth) ~ " fill: " ~ drawAttr.fill.toString()); 
		}
		
		// recurse until we have read entire structure 
		recurseReadSVG(svg, child);
	}
	
}

// map SVG color to right one 
Color svgColorMap(char[] argV)
{
	switch(argV)
	{
		case "red": 
			return Color.Red; 
		break; 
		
		case "black":
			return Color.Black; 
		break; 
		
		case "aliceblue":
			return Color.AliceBlue; 
		break; 
		
		case "antiquewhite":
			return Color.AntiqueWhite; 
		break; 
		
		case "green":
			return Color.Green;
		break;
		
		case "blue":
			return Color.Blue;
		break;
		
		case "aqua":
			return Color.Aqua;
		break;
		
		
		case "aquamarine":
			return Color.Aquamarine;
		break;
		
		case "azure":
			return Color.Azure;
		break;
		
		case "beige":
			return Color.Beige;
		break;
		
		case "bisque":
			return Color.Bisque;
		break;
		
		
		case "blanchedalmond":
			return Color.Blanchedalmond;
		break;
		
		
		case "blueviolet":
			return Color.Blueviolet;
		break;
		
		
		case "brown":
			return Color.Brown;
		break;
		
		case "burlywood":
			return Color.Burlywood;
		break;
		
		case "cadetblue":
			return Color.Cadetblue;
		break;
		
		case "chartreuse":
			return Color.Chartreuse;
		break;
		
		
		case "chocolate":
			return Color.Chocolate;
		break;
		
		
		case "coral":
			return Color.Coral;
		break;
		
		
		case "cornflowerblue":
			return Color.Cornflowerblue;
		break;
		
		case "cornsilk":
			return Color.Cornsilk;
		break;
		
		case "crimson":
			return Color.Crimson;
		break;
		
		case "cyan":
			return Color.Cyan;
		break;
		
		
		case "darkblue":
			return Color.Darkblue;
		break;
		
		
		case "darkcyan":
			return Color.Darkcyan;
		break;
		
		
		case "darkgoldenrod":
			return Color.Darkgoldenrod;
		break;
		
		case "darkgray":
			return Color.Darkgray;
		break;
		
		case "darkgrey":
			return Color.Darkgray;
		break;
		
		case "darkgreen":
			return Color.Darkgreen;
		break;
		
		
		case "darkkhaki":
			return Color.Darkkhaki;
		break;
		
		
		case "darkmagenta":
			return Color.Darkmagenta;
		break;
		
		
		case "darkolivegreen":
			return Color.Darkolivegreen;
		break;
		
		case "darkorange":
			return Color.Darkorange;
		break;
		
		case "Darkorchid":
			return Color.Darkorchid;
		break;
		
		case "darkred":
			return Color.Darkred;
		break;
		
		
		case "darksalmon":
			return Color.Darksalmon;
		break;
		
		
		case "darkseagreen":
			return Color.Darkseagreen;
		break;
		
		
		case "darkslateblue":
			return Color.Darkslateblue;
		break;
		
		case "darkslategrey":
			return Color.Darkslategray;
		break;
		
		case "darkslategray":
			return Color.Darkslategray;
		break;
		
		case "darktorquoise":
			return Color.Darkturquoise;
		break;
		
		case "darkviolet":
			return Color.Darkviolet;
		break;
		
		
		case "deepppink":
			return Color.Deeppink;
		break;
		
		
		case "deepskyblue":
			return Color.Deepskyblue;
		break;
		
		
		case "dimgray":
			return Color.Dimgray;
		break;
		
		case "dimgrey":
			return Color.Dimgray;
		break;
		
		case "dodgerblue":
			return Color.Dodgerblue;
		break;
		
		case "firebrick":
			return Color.Firebrick;
		break;
		
		
		case "floralwhite":
			return Color.Floralwhite;
		break;
		
		
		case "forestgreen":
			return Color.Forestgreen;
		break;
		
		
		case "fuchsia":
			return Color.Fuchsia;
		break;
		
		case "gainsboro":
			return Color.Gainsboro;
		break;
		
		case "ghostwhite":
			return Color.Ghostwhite;
		break;
		
		case "gold":
			return Color.Gold;
		break;
		
		
		case "goldenrod":
			return Color.Goldenrod;
		break;
		
		
		case "gray":
			return Color.Gray;
		break;
		
		
		case "grey":
			return Color.Gray;
		break;
		
		case "greenyellow":
			return Color.Greenyellow;
		break;
		
		case "honeydew":
			return Color.Honeydew;
		break;
		
		
		case "hotpink":
			return Color.Hotpink;
		break;
		
		
		case "indianred":
			return Color.Indianred;
		break;
		
		
		case "indigo":
			return Color.Indigo;
		break;
		
		case "ivory":
			return Color.Ivory;
		break;
		
		case "khaki":
			return Color.Khaki;
		break;
		
		case "lavender":
			return Color.Lavender;
		break;
		
		
		case "lavenderblush":
			return Color.Lavenderblush;
		break;
		
		
		case "lawngreen":
			return Color.Lawngreen;
		break;
		
		
		case "lemonchiffon":
			return Color.Lemonchiffon;
		break;
		
		case "lightblue":
			return Color.Lightblue;
		break;
		
		case "lightcoral":
			return Color.Lightcoral;
		break;
		
		case "lightcyan":
			return Color.Lightcyan;
		break;
		
		
		case "lightgoldenrodyellow":
			return Color.Lightgoldenrodyellow;
		break;
		
		
		case "lightgray":
			return Color.Lightgray;
		break;
		
		
		case "lightgrey":
			return Color.Lightgray;
		break;
		
		case "lightgreen":
			return Color.Lightgreen;
		break;
		
		
		case "lightpink":
			return Color.Lightpink;
		break;
		
		case "lightsalmon":
			return Color.Lightsalmon;
		break;
		
		
		case "lightseagreen":
			return Color.Lightseagreen;
		break;
		
		case "lightskyblue":
			return Color.Lightskyblue;
		break;
		
		
		case "lightslategrey":
			return Color.Lightslategray;
		break;
		
		case "lightslategray":
			return Color.Lightslategray;
		break;
		
		
		case "lightsteelblue":
			return Color.Lightsteelblue;
		break;
		
		case "lightyellow":
			return Color.Lightyellow;
		break;
		
		case "lime":
			return Color.Lime;
		break;
		
		case "limegreen":
			return Color.Limegreen;
		break;
		
		case "linen":
			return Color.Linen;
		break;
		
		case "magenta":
			return Color.Magenta;
		break;
		
		
		case "maroon":
			return Color.Maroon;
		break;
		
		case "mediumaquamarine":
			return Color.Mediumaquamarine;
		break;
		
		case "mediumblue":
			return Color.Mediumblue;
		break;
		
		case "mediumorchid":
			return Color.Mediumorchid;
		break;
		
		
		case "mediumpurple":
			return Color.Mediumpurple;
		break;
		
		case "mediumseagreen":
			return Color.Mediumseagreen;
		break;
		
		
		case "mediumslateblue":
			return Color.Mediumslateblue;
		break;
		
		case "mediumspringgreen":
			return Color.Mediumspringgreen;
		break;
		
		
		case "mediumturquoise":
			return Color.Mediumturquoise;
		break;
		
		case "mediumvioletred":
			return Color.Mediumvioletred;
		break;
		
		
		case "midnightblue":
			return Color.Midnightblue;
		break;
		
		case "mintcream":
			return Color.Mintcream;
		break;
		
		case "mistyrose":
			return Color.Mistyrose;
		break;
		
		case "moccasin":
			return Color.Moccasin;
		break;
		
		case "navajowhite":
			return Color.Navajowhite;
		break;
		
		case "navy":
			return Color.Navy;
		break;
		
		case "oldlace":
			return Color.Oldlace;
		break;
		
		case "olive":
			return Color.Olive;
		break;
		
		
		case "olivedrab":
			return Color.Olivedrab;
		break;
		
		case "orange":
			return Color.Orange;
		break;
		
		
		case "orangered":
			return Color.Orangered;
		break;
		
		case "orchid":
			return Color.Orchid;
		break;
		
		
		case "palegoldenrod":
			return Color.Palegoldenrod;
		break;
		
		case "palegreen":
			return Color.Palegreen;
		break;
		
		
		case "paleturquoise":
			return Color.Paleturquoise;
		break;
		
		case "palevioletred":
			return Color.Palevioletred;
		break;
		
		
		case "papayawhip":
			return Color.Papayawhip;
		break;
		
		case "peachpuff":
			return Color.Peachpuff;
		break;
		
		
		case "peru":
			return Color.Peru;
		break;
		
		case "pink":
			return Color.Pink;
		break;
		
		
		case "plum":
			return Color.Plum;
		break;
		
		case "powderblue":
			return Color.Powderblue;
		break;
		
		
		case "purple":
			return Color.Purple;
		break;
		
		case "rosybrown":
			return Color.Rosybrown;
		break;
		
		case "royalblue":
			return Color.Royalblue;
		break;
		
		case "saddlebrown":
			return Color.Saddlebrown;
		break;
		
		case "salmon":
			return Color.Salmon;
		break;
		
		case "sandybrown":
			return Color.Sandybrown;
		break;
		
		case "seagreen":
			return Color.Seagreen;
		break;
		
		
		case "seashell":
			return Color.Seashell;
		break;
		
		case "sienna":
			return Color.Sienna;
		break;
		
		
		case "silver":
			return Color.Silver;
		break;
		
		case "skyblue":
			return Color.Skyblue;
		break;
		
		
		case "slateblue":
			return Color.Slateblue;
		break;
		
		case "slategrey":
			return Color.Slategray;
		break;
		
		case "slategray":
			return Color.Slategray;
		break;
		
		case "snow":
			return Color.Snow;
		break;
		
		
		case "springgreen":
			return Color.Springgreen;
		break;
		
		case "steelblue":
			return Color.Steelblue;
		break;
		
		case "tan":
			return Color.Tan;
		break;
		
		case "teal":
			return Color.Teal;
		break;
		
		
		case "thistle":
			return Color.Thistle;
		break;
		
		case "tomato":
			return Color.Tomato;
		break;
		
		
		case "turquoise":
			return Color.Turquoise;
		break;
		
		case "violet":
			return Color.Violet;
		break;
		
		
		case "wheat":
			return Color.Wheat;
		break;
		
		case "white":
			return Color.White;
		break;
		
		
		case "whitesmoke":
			return Color.Whitesmoke;
		break;
		
		case "yellow":
			return Color.Yellow;
		break;
		
		
		case "yellowgreen":
			return Color.Yellowgreen;
		break;

		default: break; 
	}
	
	// default
	return Color.White; 
}