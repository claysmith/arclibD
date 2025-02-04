﻿/******************************************************************************* 

	GUI defined types 
	
	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:     ArcLib team 
    
    Description:    
		GUI defined types, currently only includes actiontype 

	Examples:
	--------------------
		None Provided
	--------------------

*******************************************************************************/

module arc.x.gui.widgets.types; 

public import 
	arc.draw.color,
	arc.math.point; 

public 
{
	/// ActionType Enum 
	enum ACTIONTYPE
	{
		DEFAULT, 
		CLICKON, 
		CLICKOFF, 
		MOUSEOVER 
	}
}
