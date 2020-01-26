/******************************************************************************* 

    FreeUniverse Theme for the GUI  

    Authors:       ArcLib team, see AUTHORS file 
    Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
    License:       zlib/libpng license: $(LICENSE) 
    Copyright:     ArcLib team 
    
    Description:    
		FreeUniverse Theme for the GUI  


	Examples:
	--------------------
		Not provided.
	--------------------

*******************************************************************************/

module arc.x.gui.themes.freeuniverse; 

import 
	arc.x.gui.themes.theme,
	arc.x.gui.widgets.types,
	arc.draw.shape,
	arc.draw.color,
	arc.draw.attributes, 
	arc.math.point,
	arc.types;
	
import derelict.opengl.gl; 

///
class FreeUniverseTheme : BaseTheme
{
  public:
	this()
	{
		setThemeName("FreeUniverse"); 
	}	
  
	/// Draw button FreeUniverse Style
	void drawButton(ACTIONTYPE type, bool focus, Point pos, Size size, DrawAttributes attr)
	{
		drawBorder(type, focus, pos, size, attr);
	}

	/// Draw label FreeUniverse Style
	void drawLabel(ACTIONTYPE type, bool focus, Point pos, Size size, DrawAttributes attr)
	{
		drawBorder(type, focus, pos, size, attr);
	}

	/// Draw textfield FreeUniverse Style
	void drawTextField(ACTIONTYPE type, bool focus, Point pos, Size size, DrawAttributes attr)
	{
		drawBorder(type, focus, pos, size, attr);
	}

  private:
	/// draw a nice rectangle border
	void drawBorder(ACTIONTYPE type, bool focus, Point pos, Size size, DrawAttributes attr)
	{
		if (focus)
		{
			glEnable(GL_LINE_STIPPLE);
			glLineStipple(3, 0xAAAA);
		}

		attr.isFill = false; 
		drawRectangle(pos, size, attr);
		
		attr.isFill = true; 
		
		switch(type)
		{
			case ACTIONTYPE.DEFAULT:
				attr.fill = Color(0, 50, 0, 150); 
				drawRectangle(pos + Point(1,1), size - Size(2,2) , attr);
			break;

			case ACTIONTYPE.MOUSEOVER:
				attr.fill = Color(0, 100, 0, 150);
				drawRectangle(pos + Point(1, 1), size - Size(2, 2), attr);
			break; 

			case ACTIONTYPE.CLICKON:
				attr.fill = Color(0, 150, 0, 150);
				drawRectangle(pos + Point(1, 1), size - Size(2, 2),  attr);
			break; 

			case ACTIONTYPE.CLICKOFF:
				attr.fill = Color(0, 50, 0, 150);
				drawRectangle(pos + Point(1, 1), size - Size(2, 2),  attr);
			break; 
		}

		if (focus)
			glDisable(GL_LINE_STIPPLE); 
	}
}
