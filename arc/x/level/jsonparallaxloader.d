/*******************************************************************************

	TileMap draws a tile-based map to the screen.

	Authors:        ArcLib team, see AUTHORS file
	Maintainer:     Brian Schott (briancschott at gmail dot com)
	License:        zlib/libpng license: $(LICENSE)
	Copyright:      ArcLib team

	Description:
		Code for loading a tile map from a JSON description.
	Examples:
	--------------------
// Something like this on Linux/BSD
auto map = loadTileMap("maps/tilemap.json", "/usr/share/games/game_name/data");

// Something like this on Windows
auto map = loadTileMap("maps/tilemap.json", "C:\Program Files\game_name\data");
	--------------------

*******************************************************************************/

module arc.x.level.jsonparallaxloader;

private import tango.io.device.File,
               tango.io.FilePath,
               tango.text.json.Json,
               tango.util.log.Log,
               tango.util.log.AppendFile,
               tango.text.convert.Format,
               Integer = tango.text.convert.Integer;

private import arc.x.level.parallax,
               arc.x.level.common,
               arc.draw.color,
               arc.types;


static this()
{
	initializeLogging();
	log = Log.getLogger("arc.x.level.jsonmaploader");
}


/**
 * Loads a parallax background from a JSON file.
 * Params:
 *     filePath = the path to the file on disk
 *     dataDir = he directory to look for image files in. This is optional.
 *         If not specified, the files will be searched for in the current
 *         directory.
 * Throws: an exception if the file is not properly formatted
 * Returns: a new Parallax
 */
public Parallax loadParallax(char[] filePath, char[] dataDir = "")
{
	return null;
}


/**
 * Params:
 *     jsonString = the string to load the parallax background from
 *     dataDir = he directory to look for image files in. This is optional.
 *         If not specified, the files will be searched for in the current
 *         directory.
 * Throws: an exception if the file is not properly formatted
 * Returns: a new Parallax
 */
public Parallax parseParallax(char[] jsonString, char[] dataDir = "")
{
	return null;
}

/**
 * Loads a Parallax from a JSON object. This function is used internally here
 * and by the level module. Don't use it directly. Use loadParallax instead.
 * Params:
 *     parallaxObject = the JSON object representing the parallax background
 *     dataDir = he directory to look for image files in. This is optional.
 *         If not specified, the files will be searched for in the current
 *         directory.
 * Returns: a new Parallax
 */
public Parallax parseParallax(Composite parallaxObject, char[] dataDir = "")
{
	auto parallax = new Parallax;

	bool layersFound = false;
	bool bgColorFound = false;

	foreach(char[] attrName, Value attrValue; parallaxObject.attributes())
	{
		if(attrName == "bgColor")
		{
			if(attrValue.type == String)
			{
				Color c = parseColor(attrValue.toString());
				parallax.setBackgroundColor(c);
				bgColorFound = true;
			}
			else
			{
				parallax.setBackgroundColor(Color(255, 0, 255, 255));
				log.error("The \"bgColor\" attribute must be"
					~ "specified as a string in the format \"#rrggbbaa\"");
			}
			continue;
		}

		if(attrName == "parallaxes")
		{
			if(attrValue.type == Array)
			{
				auto layers = attrValue.toArray();
				layersFound = true;
				foreach(layer; layers)
					parseLayer(layer, parallax, dataDir);
			}
		}
	}

	if(!layersFound)
	{
		log.info("No \"layers\" attribute found in parallax background.");
	}
	if(!bgColorFound)
	{
		log.warn("No \"bgColor\" attribute found in parallax background. "
			~ "Defaulting to black.");
		parallax.setBackgroundColor(Color!(ubyte)(0, 0, 0, 255));
	}

	return parallax;
}


/*
 * Converts a string in the "HTML" format of "#rrggbbaa" to a Color
 */
private Color parseColor(char[] colorString)
{
	Color colorError()
	{
		log.error("Error parsing color string \"" ~ colorString ~"\". "
			~ "Defaulting to a hideous shade of magenta so that the file will"
			~ " be fixed.");
		return Color(255, 0, 255, 255);
	}

	try
	{
		if(colorString[0] == '#')
		{
			uint c = Integer.parse(colorString[1 .. $], 16);
			auto color = Color(0, 0, 0, 0);
			color.setU32(c);
			return color;
		}
		else
			return colorError();
	}
	catch(Exception)
		return colorError();
}


// This has to be the most monotonous function in the entire module...
private void parseLayer(Value layer, Parallax parallax, char[] dataDir = "")
{
	if(layer.type == JsonObject)
	{
		bool indexFound = false;
		bool hTileFound = false;
		bool vTileFound = false;
		bool fileNameFound = false;
		bool visibleFound = false;
		bool hScrollFound = false;
		bool vScrollFound = false;
		bool hScrollSpeedFound = false;
		bool vScrollSpeedFound = false;

		int index;
		char[] fileName;
		bool visible;
		bool hTile;
		bool vTile;
		bool hScroll;
		bool vScroll;
		arcfl hScrollSpeed;
		arcfl vScrollSpeed;


		foreach(attrName, attrValue; layer.toObject().attributes())
		{
			if(attrName == "index")
			{
				if(attrValue.type == Number && attrValue.toNumber() >= 0)
				{
					indexFound = true;
					index = cast(uint)attrValue.toNumber();
					continue;
				}
				else
					throw new Exception("Error parsing parallax layer: layer"
						~ "index must be a non-negative integer");

			}
			if(attrName == "fileName")
			{
				if(attrValue.type == String)
				{
					fileNameFound = true;
					fileName = attrValue.toString();
					continue;
				}
				else
					throw new Exception("Error parsing parallax layer: fileName"
						~ " must be specified as a file path");
			}
			if(attrName == "visible")
			{
				if(attrValue.type == JsonTrue || attrValue.type == JsonFalse)
				{
					visibleFound = true;
					visible = attrValue.toBool();
					continue;
				}
				else
					throw new Exception("Error parsing parallax layer: "
						~ "\"visible\" attribute must be true or false");
			}
			if(attrName == "hTile")
			{
				if(attrValue.type == JsonTrue || attrValue.type == JsonFalse)
				{
					hTileFound = true;
					hTile = attrValue.toBool();
					continue;
				}
				else
					throw new Exception("Error parsing parallax layer: "
						~ "\"hTile\" attribute must be true or false");
			}
			if(attrName == "vTile")
			{
				if(attrValue.type == JsonTrue || attrValue.type == JsonFalse)
				{
					vTileFound = true;
					vTile = attrValue.toBool();
					continue;
				}
				else
					throw new Exception("Error parsing parallax layer: "
						~ "\"vTile\" attribute must be true or false");
			}
			if(attrName == "vScroll")
			{
				if(attrValue.type == JsonTrue || attrValue.type == JsonFalse)
				{
					vScrollFound = true;
					vScroll = attrValue.toBool();
					continue;
				}
				else
					throw new Exception("Error parsing parallax layer: "
						~ "\"vScroll\" attribute must be true or false");
			}
			if(attrName == "hScroll")
			{
				if(attrValue.type == JsonTrue || attrValue.type == JsonFalse)
				{
					hScrollFound = true;
					hScroll = attrValue.toBool();
					continue;
				}
				else
					throw new Exception("Error parsing parallax layer: "
						~ "\"hScroll\" attribute must be true or false");
			}
			if(attrName == "vScrollSpeed")
			{
				if(attrValue.type == Number)
				{
					vScrollSpeedFound = true;
					vScrollSpeed = cast(arcfl)attrValue.toNumber();
					continue;
				}
				else
					throw new Exception("Error parsing parallax layer: "
						~ "\"vScrollSpeed\" attribute must be a number");
			}
			if(attrName == "hScrollSpeed")
			{
				if(attrValue.type == Number)
				{
					hScrollSpeedFound = true;
					hScrollSpeed = cast(arcfl)attrValue.toNumber();
					continue;
				}
				else
					throw new Exception("Error parsing parallax layer: "
						~ "\"vScrollSpeed\" attribute must be a number");
			}
		}

		// More error handling...
		if(!fileNameFound)
		{
			throw new Exception("Error parsing parallax layer: no image file"
				~ "specified");
		}
		else
		{
			// This can throw an exception
			fileName = getFilePath(fileName, dataDir);
		}
		if(!hTileFound)
		{
			log.error("\"hTile\" attribute of parallax layer not found."
				~ " Defaulting to false");
			hTile = false;
		}
		if(!vTileFound)
		{
			log.error("\"vTile\" attribute of parallax layer not found."
				~ " Defaulting to false");
			vTile = false;
		}
		if(!hScrollFound)
		{
			log.error("\"hScroll\" attribute of parallax layer not found."
				~ " Defaulting to false");
			hScroll = false;
		}
		if(!vScrollFound)
		{
			log.warn("\"vScroll\" attribute of parallax layer not found."
				~ " Defaulting to false");
			vScroll = false;
		}
		if(!visibleFound)
		{
			log.warn("\"visible\" attribute of parallax layer not found."
				~ " defaulting to true");
			visible = true;
		}
		if(!hScrollSpeedFound)
		{
			log.warn("\"hScrollSpeed\" attribute of parallax layer not found."
				~ "Defaulting to 1.0");
			hScrollSpeed = 1.0;
		}
		if(!vScrollSpeedFound)
		{
			log.warn("\"vScrollSpeed\" attribute of parallax layer not found."
				~ "Defaulting to 1.0");
			vScrollSpeed = 1.0;
		}
		if(!indexFound) // This is optional
		{
			log.warn("\"index\" attribute of parallax layer not found."
				~ " Appending parallax to the top.");
			index = -1;
		}

		// we don't need the old index anymore, so just re-use it
		index = parallax.addLayer(getFilePath(fileName, dataDir), index);
		parallax.setScrollOptions(index, hScroll, hScrollSpeed, vScroll,
			vScrollSpeed);
		parallax.setRepeatOptions(index, hTile, vTile);
	}
	else
	{
		throw new Exception("Error parsing background: parallax layer is "
			~ "invalid");
	}
}


private
{
	Logger log;

	/// Setup root logger to log to arc.log
	void initializeLogging()
	{
		// remove log file if it exists
		FilePath fp = new FilePath("arc.log");
		if (fp.exists())
			fp.remove();
		delete fp;

		// send new log to path
		Logger root = Log.root();
		root.add(new AppendFile("arc.log"));
	}
}
