/*******************************************************************************

	Level provides some convenience functions for storing a Blaze world,
	parallax information, and tile map information in a single file.

	Authors:        ArcLib team, see AUTHORS file
	Maintainer:     Brian Schott (brian-schott at cox dot net)
	License:        zlib/libpng license: $(LICENSE)
	Copyright:      ArcLib team

	Description:
		Code for loading game levels from files on disk, and then getting
		references to their components.

	Note:
		Blaze does not currently compile.

	Examples:
	--------------------
// Load the level from a file on disk
auto level = loadFromJSON("levels/level2.json", "/usr/share/games/test/data");
auto map = level.map;
auto parallax = level.parallax;
auto world = level.blazeWorld;
	--------------------

*******************************************************************************/

module arc.x.level.level;

private import tango.io.device.File,
               tango.io.FilePath,
			   tango.text.json.Json,
			   tango.util.log.Log,
			   tango.util.log.AppendFile;

private import arc.x.level.tilemap,
               arc.x.level.jsonmaploader,
               arc.x.level.parallax,
               arc.x.level.jsonparallaxloader,
			   arc.x.level.common;
//			   arc.x.blaze.world;


static this()
{
	initializeLogging();
	log = Log.getLogger("arc.x.level.level");
}


public struct Level
{
	TileMap map = null;
	Parallax parallax = null;
//	World blazeWorld;
}


/**
 * Loads a level from the given JSON file
 * Params:
 *     fileName = the path to the file to load from
 */
public Level loadFromJSON(char[] fileName, char[] dataDir = "")
{
	auto path = FilePath(fileName);
	auto dataPath = FilePath(FilePath.join(fileName, dataDir));
	char[] jsonText;
	Level level;

	jsonText = loadJsonText(fileName, dataDir);

	assert(jsonText != null);

	auto json = new Json!(char);
	json.parse(jsonText);

	auto levelObject = json.value().toObject;

	foreach(char[] attrName, Value attrValue; levelObject.attributes())
	{
		if(attrName == "tileMap")
		{
			log.info("tilemap element found");
			if(attrValue.type == JsonObject)
			{
				log.info("parsing tilemap");
				level.map = parseTileMap(attrValue.toObject(), dataDir);
				continue;
			}
			else
				throw new Exception("Error loading level: the tilemap is "
					~"invalid.");
		}

		if(attrName == "background")
		{
			if(attrValue.type == JsonObject)
			{
				level.parallax = parseParallax(attrValue.toObject(), dataDir);
				continue;
			}
			else
				throw new Exception("Error loading level: the background is"
					~ "invalid.");
		}
	}

	return level;
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
