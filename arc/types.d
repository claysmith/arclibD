/******************************************************************************* 

    Arc defined types

    Authors:       ArcLib team, see AUTHORS file 
    Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
    License:       zlib/libpng license: $(LICENSE) 
    Copyright:     ArcLib team 
    
    Description:    
		User defined types in arc, including arcfl and Radians. 
		Also provides public imports of common types.

	Examples:
	--------------------
		arcfl user_value = 3;
	--------------------

*******************************************************************************/

module arc.types; 

public import 
		arc.math.angle,
		arc.math.point,
		arc.math.size,
		arc.math.rect,
		arc.draw.color;

import tango.text.xml.Document; 

///
alias double arcfl; 

/// XML Document
alias Document!(char) XMLDoc;

/// XML Document 16
//typedef Document!(wchar) XMLDoc16; 

/// XML Document 32 
//typedef Document!(dchar) XMLDoc32; 


/// XML Node
alias Document!(char).Node XMLNode;

/// XML Node 16
//typedef Document!(wchar).Node XMLNode16;

/// XML Node 32
//typedef Document!(dchar).Node XMLNode32;