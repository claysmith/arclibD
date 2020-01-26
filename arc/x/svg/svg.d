module arc.x.svg.svg; 

import
	tango.text.Util,
	tango.text.convert.Integer,
	tango.text.convert.Float,
	tango.text.xml.Document, 
	tango.io.Console,
	tango.io.FilePath,
	tango.io.File,
	tango.util.log.Log;

import arc.x.svg.readsvg; 

/// logger for this module
public Logger logger;

static this()
{
	// setup logger
	log = Log.getLogger("arc.x.svg.svg");
}

class SVG
{
	this(char[] argFile)
	{
		svg = readSVG(argFile); 
	}
	
	void draw()
	{
		// draw the svg 
		svg.draw(); 
	}
	
	SVGData svg; 
}
