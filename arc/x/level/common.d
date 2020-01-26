/*******************************************************************************

	Code common to the different JSON parsers. Used internally.

	Authors:        ArcLib team, see AUTHORS file
	Maintainer:     Brian Schott (briancschott at gmail dot com)
	License:        zlib/libpng license: $(LICENSE)
	Copyright:      ArcLib team

	Description:
		Code for loading a tile map from a JSON description.

	Examples:
	--------------------
import tango.io.Stdout;

void main()
{
	Stderr.formatln("I am silly.");
	Stderr.formatln("I should not use code meant for internal use.");
}
	--------------------

*******************************************************************************/

module arc.x.level.common;

private import tango.io.device.File,
               tango.io.FilePath,
               tango.text.json.Json,
			   tango.util.log.Log,
			   tango.util.log.AppendFile,
			   tango.text.convert.Format;

private import tango.io.Stdout;

static this()
{
	initializeLogging();
	log = Log.getLogger("arc.x.level.common");
}


// This saves a lot of typing
public alias Json!(char).Value Value;
public alias Json!(char).Composite Composite;
public auto Number = Json!(char).Type.Number;
public auto String = Json!(char).Type.String;
public auto Array = Json!(char).Type.Array;
public auto JsonObject = Json!(char).Type.Object;
public auto JsonTrue = Json!(char).Type.True;
public auto JsonFalse = Json!(char).Type.False;


/**
 * Gets the path to a file, first looking in a data directory, then in the
 * current directory.
 * Params:
 *     fileName = the name of the file on disk
 *     dataDir = the path to look for the file in
 * Returns: The path to the file
 * Throws: an exception if the file could not be found.
 */
public char[] getFilePath(char[] fileName, char[] dataDir)
{
	auto dataPath = FilePath(FilePath.join(dataDir, fileName));

	if(dataPath.exists)
	{
		return FilePath.join(dataDir, fileName);
	}
	else
	{
		log.info("Could not find the file \""
			~ FilePath.join(dataDir, fileName) ~ "\". Looking in the current "
			~ "directory.");

		auto path = FilePath(fileName);

		if(path.exists())
		{
			return fileName;
		}
		else
			throw new Exception("Could not find the file \"" ~ fileName ~ "\"");
	}
}


/**
 * Params:
 *     fileName = the name of the file on disk
 *     dataDir = the path to look for the file in
 * Returns: The text contents of the file
 */
public char[] loadJsonText(char[] fileName, char[] dataDir = "")
{
	char[] filePath = getFilePath(fileName, dataDir);
	return cast(char[])File.get(filePath);
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
