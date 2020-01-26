/******************************************************************************* 

	Lighting code

	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Christian Kamm (kamm incasoftware de)
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:     ArcLib team 
	
	Description:
	Lighting code
	
	Examples:
	--------------------
	--------------------

*******************************************************************************/

module arc.x.light.edge; 

import arc.math.point; 

/// oriented edge, normal is 'to the right'
struct Edge
{
	///
	Point from, to;
	
	///
	Point normal()
	{
		Point rotate90cw(ref Point p)	{
			return Point(p.y, -p.x);
		}
		
		return rotate90cw(to - from);
	}
	
	///
	Point tangent()
	{
		return to - from;
	}
}