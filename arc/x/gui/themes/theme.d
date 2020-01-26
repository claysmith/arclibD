/******************************************************************************* 

	Allows user to set the theme style used by Arc's GUI mechanism. 
	
    Authors:       ArcLib team, see AUTHORS file 
    Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
    License:       zlib/libpng license: $(LICENSE) 
    Copyright:     ArcLib team 
    
    Description:    
		Allows user to set the theme style used by Arc's GUI mechanism. 
	Currently only the FreeUniverse theme is supported. 

	Examples:
	--------------------

	--------------------

*******************************************************************************/

module arc.x.gui.themes.theme; 

import
	tango.util.log.Log;

import 
	arc.types,
	arc.draw.color,
	arc.draw.attributes, 
	arc.x.gui.widgets.types;

/// logger for this module
public Logger logger;

static this()
{
	// setup logger
	logger = Log.getLogger("arc.x.gui.themes.theme");
	
	// set new basetheme so it can give error on failure
	theme = new BaseTheme; 
}

///
class BaseTheme
{
	/// draw button with current theme
	void drawButton(ACTIONTYPE type, bool focus, Point pos, Size size, DrawAttributes attr)
	{
		logger.fatal("No gui Theme has been set"); 
	}

	/// draw label with current theme
	void drawLabel(ACTIONTYPE type, bool focus, Point pos, Size size, DrawAttributes attr)
	{
		logger.fatal("No GUI theme has been set"); 
	}

	/// draw textfields with current theme
	void drawTextField(ACTIONTYPE type, bool focus, Point pos, Size size, DrawAttributes attr)
	{
		logger.fatal("No GUI theme has been set"); 
	}
	
	/// set theme name 
	void setThemeName(char[] name_)
	{
		themeName = name_; 
	}
	
 private:
	char[] themeName; 
}

/// set theme of gui 
void setTheme(BaseTheme theme_)
{
	theme = theme_; 
}

/// exposed so other parts of arc can access it
BaseTheme theme; 
