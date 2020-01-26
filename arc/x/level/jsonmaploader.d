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

module arc.x.level.jsonmaploader;

private import tango.io.device.File,
               tango.io.FilePath,
               tango.text.json.Json,
			   tango.util.log.Log,
			   tango.util.log.AppendFile,
			   tango.text.convert.Format;

private import arc.x.level.tilemap,
			   arc.x.level.common;

static this()
{
	initializeLogging();
	log = Log.getLogger("arc.x.level.jsonmaploader");
}


/**
 * Loads a TileMap from a JSON file.
 * Params:
 *     filePath = the path to the file on disk
 *     dataDir = the directory to look for image files in. This is optional.
 *         If not specified, the files will be searched for in the current
 *         directory. This will effect the path that the map file is looked for
 *         and the path that any data files referenced are look for in.
 * Throws: an exception if the file is not properly formatted
 */
public TileMap loadTileMap(char[] filePath, char[] dataDir = "")
{
	auto jsonText = loadJsonText(filePath, dataDir);

	return parseTileMap(jsonText, dataDir);
}


/**
 * Loads a TileMap from a JSON text description.
 * Params:
 *     jsonString = the JSON document in string form
 *     dataDir = the directory to look for image files in. This is optional.
 *         If not specified, the files will be searched for in the current
 *         directory.
 * Throws: an exception if the file is not properly formatted
 * Returns: a new TileMap
 */
public TileMap parseTileMap(char[] jsonString, char[] dataDir = "")
{
	// This line will throw on a parse error
	auto json = new Json!(char);

	auto mapObject = json.value().toObject();

	return parseTileMap(mapObject, dataDir);
}


/**
 * Loads a TileMap from a JSON object. This function is primarily used by the
 * level module. Don't use it directly. Use loadTileMap instead.
 * Params:
 *     jsonString = the JSON object representing the map
 *     dataDir = the directory to look for image files in. This is optional.
 *         If not specified, the files will be searched for in the current
 *         directory.
 * Throws: an exception if the file is not properly formatted
 * Returns: a new TileMap
 */
public TileMap parseTileMap(in Composite mapObject, char[] dataDir = "")
{
	Value[] layers;
	Value[] images;
	uint tileSize = 0;
	uint width = 0;
	uint height = 0;
	uint layerCount = 0;

	foreach(char[] attrName, Value attrValue;
		mapObject.attributes())
	{
		if(attrName == "layers")
		{
			if(attrValue.type == Array)
			{
				layers = attrValue.toArray();
				continue;
			}
			else
				throw new Exception("Error parsing map: \"layers\" must be "
					~ "an array of layers.");
		}
		if(attrName == "images")
		{
			if(attrValue.type == Array)
			{
				images = attrValue.toArray();
				continue;
			}
			else
				throw new Exception("Error parsing map: \"images\" must be "
					~ "an array");
		}
		if(attrName == "tileSize")
		{
			if(attrValue.type == Number && attrValue.toNumber() > 0)
			{
				tileSize = cast(uint)attrValue.toNumber();
				continue;
			}
			else
				throw new Exception("Error parsing map: The tile size must be "
					~ "a positive number.");
		}
		if(attrName == "width")
		{
			if(attrValue.type == Number && attrValue.toNumber() > 0)
			{
				width = cast(uint)attrValue.toNumber();
				continue;
			}
			else
				throw new Exception("Error parsing map: the width must be a "
					~ "non-negative number");
		}
		if(attrName == "height")
		{
			if(attrValue.type == Number && attrValue.toNumber() > 0)
			{
				height = cast(uint)attrValue.toNumber();
				continue;
			}
			else
				throw new Exception("Error parsing map: the height must be a "
					~ "positive number");
		}
	}

	if(tileSize == 0 || width == 0 || height == 0)
	{
		throw new Exception("Error parsing map: The width, height, and tilesize"
			~ " must be specified and they must be positive numbers");
	}

	if(layers == null)
		throw new Exception("Error parsing map: No tile layers were specified");
	else
		layerCount = layers.length;

	if(images == null)
		throw new Exception("Error parsing map: No images specified");

	auto map = new TileMap(width, height, layerCount, tileSize);

	parseImages(images, map, dataDir);
	parseLayers(layers, map);

	return map;
}


private void parseLayers(in Value[] layers, inout TileMap map)
{
	foreach(layer; layers)
	{
		if(layer.type == JsonObject)
		{
			bool visible = true;
			Value[] tiles;
			bool tilesSet = false;
			size_t index;
			bool indexSet = false;
			foreach(char[] attrName, Value attrValue;
				layer.toObject().attributes())
			{
				if(attrName == "index")
				{
					if(attrValue.type == Number && attrValue.toNumber() >= 0
						&& attrValue.toNumber() < map.getLayerCount())
					{
						index = cast(size_t)attrValue.toNumber();
						indexSet = true;
						continue;
					}
					else
					{
						throw new Exception("Error parsing map: The layer "
							~ "index must be a non-negative integer and must "
							~ "be less than the number of layers in the map");
					}
				}

				if(attrName == "tiles")
				{
					if(attrValue.type == Array)
					{
						tiles = attrValue.toArray();
						tilesSet = true;
						continue;
					}
					else
					{
						throw new Exception("Error parsing map: The \"tiles\" "
							~ "attribute must be an array of tile objects");
					}
				}
			}

			if(!indexSet)
				throw new Exception("Error parsing map: Layer specified with "
					~ "no index.");

			if(!tilesSet)
				throw new Exception("Error parsing map: Layer specified with "
					~ "no tiles.");

			foreach(tile; tiles)
			{
				if(tile.type == JsonObject)
					parseTile(index, tile.toObject(), map);
				else
					throw new Exception("Error parsing map: Invalid tile "
						~ "format used");
			}
		}
		else
		{
			throw new Exception("Error parsing map: Each element of the "
				~ "\"layers\" array must be a valid layer");
		}
	}
}


/*
 * Add a tile to the map
 * Params:
 *
 */
private void parseTile(size_t layerIndex, Composite tile, ref TileMap map)
{
	bool xSet = false;
	bool ySet = false;
	bool indexSet = false;
	bool ixSet = false;
	bool iySet = false;
	uint x;
	uint y;
	uint index;
	uint ix;
	uint iy;

	foreach(char[] attrName, Value attrValue; tile.attributes())
	{
		if(attrName == "x")
		{
			if(attrValue.type == Number && attrValue.toNumber() >= 0)
			{
				xSet = true;
				x = cast(uint)attrValue.toNumber();
			}
			else
				throw new Exception("x-coordinate of tile must be specified as "
					~ "a non-negative number.");
		}
		if(attrName == "y")
		{
			if(attrValue.type == Number && attrValue.toNumber() >= 0)
			{
				ySet = true;
				y = cast(uint)attrValue.toNumber();
			}
			else
				throw new Exception("y-coordinate of tile must be specified as "
					~ "a non-negative number.");
		}
		if(attrName == "ii")
		{
			if(attrValue.type == Number && attrValue.toNumber() >= 0)
			{
				indexSet = true;
				index = cast(uint)attrValue.toNumber();
			}
			else
				throw new Exception("image index of tile must be specified as "
					~ "a non-negative number.");
		}
		if(attrName == "ix")
		{
			if(attrValue.type == Number && attrValue.toNumber() >= 0)
			{
				ixSet = true;
				ix = cast(uint)attrValue.toNumber();
			}
			else
				throw new Exception("image x-coordinate of tile must be "
					~"specified as a non-negative number.");
		}
		if(attrName == "iy")
		{
			if(attrValue.type == Number && attrValue.toNumber() >= 0)
			{
				iySet = true;
				iy = cast(uint)attrValue.toNumber();
			}
			else
				throw new Exception("image y-coordinate of tile must be "
					~ "specified as a non-negative number.");
		}
	}

	if(!xSet)
		throw new Exception("x-coordinate of tile must be specified as "
			~ "a non-negative number.");

	if(!ySet)
		throw new Exception("y-coordinate of tile must be specified as "
			~ "a non-negative number.");

	if(!indexSet)
		throw new Exception("image index of tile must be specified as "
			~ "a non-negative number.");

	if(!ixSet)
		throw new Exception("image x-coordinate of tile must be "
			~"specified as a non-negative number.");

	if(!iySet)
		throw new Exception("image y-coordinate of tile must be "
			~ "specified as a non-negative number.");

	map.addTile(x, y, layerIndex, ix, iy, index);
}


/*
 * Add images to the map.
 * Params:
 *     images = the JSON array of images
 *     map = the map that the images are being added to
 *     dataDir = the directory to look for the image files in.
 */
private void parseImages(Value[] images, ref TileMap map, char[] dataDir = "")
{
	foreach(Value image; images)
	{
		uint index = uint.max;
		bool indexFound = false;
		char[] fileName = null;

		foreach(char[] attrName, Value attrValue; image.toObject().attributes())
		{
			if(attrName == "index")
			{
				if(attrValue.type == Number && attrValue.toNumber() >= 0)
				{
					index = cast(uint)attrValue.toNumber();
					indexFound = true;
					continue;
				}
				else
					throw new Exception("Error parsing map: the image index"
						~ " must be a non-negative number");
			}

			if(attrName == "fileName")
			{
				if(attrValue.type == String)
				{
					fileName = attrValue.toString();
					continue;
				}
				else
					throw new Exception("Error parsing map: the fileName must"
						~ " be the path to a file. (Must be a string)");
			}
		}

		if(!indexFound)
		{
			throw new Exception("Error parsing map: No index specified for "
				~ "image file");
		}

		if(fileName == null)
		{
			throw new Exception("Error parsing map: No file specified for "
				"image with index " ~ Format("{0}", index));
		}

		char[] path = getFilePath(fileName, dataDir);
		map.addTileSet(path, index);
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
