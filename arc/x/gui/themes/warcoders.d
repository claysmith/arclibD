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

module arc.x.gui.themes.warcoders; 

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
class WarCodersTheme : BaseTheme
{
  public:
	this()
	{
		setThemeName("WarCoders"); 
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
		attr.detail = 6; 
		
		Color d = Color(5,73,144, 220);
		Color mo = Color(5,73,144-30, 180);
		
		attr.fill = mo;
		attr.isFill = true; 
		
		switch(type)
		{
			case ACTIONTYPE.DEFAULT:
				attr.fill = d; 
				drawRoundEdgeRect(pos, size, attr);
			break;

			case ACTIONTYPE.MOUSEOVER:
				drawRoundEdgeRect(pos, size, attr);
			break; 

			case ACTIONTYPE.CLICKON:
				drawRoundEdgeRect(pos, size, attr);
			break; 

			case ACTIONTYPE.CLICKOFF:
				drawRoundEdgeRect(pos, size, attr);
			break; 
		}
	}
}
