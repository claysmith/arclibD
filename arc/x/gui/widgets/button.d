/******************************************************************************* 

	A button that can be clicked on and can support text to be drawn on it.
	
    Authors:       ArcLib team, see AUTHORS file 
    Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
    License:       zlib/libpng license: $(LICENSE) 
    Copyright:     ArcLib team 
    
    Description:    
		A button that can be clicked on and can support text to be drawn 
	on it. Widgets are not recommended for use by themselves, but it is 
	possible. 

	Examples:
	--------------------
		import arc.x.gui.widgets.button; 
		
		Button button = new Button(); 
		
		button.setSize(size);
		button.setPosition(pos);
		button.setFont(font); 
		button.setText("Hello World"); 
	--------------------

*******************************************************************************/

module arc.x.gui.widgets.button;

import
		arc.x.gui.widgets.widget,
		arc.x.gui.themes.theme, 
		arc.font,
		arc.input,
		arc.types,
		arc.math.point; 

/// Button Class, Derives from base class Widget 
class Button : Widget 
{
  public: 
  
	/// draw button 
	void draw(Point parentPos = Point(0,0))
	{
		arc.x.gui.themes.theme.theme.drawButton(action,focus, position + parentPos, size, attr); 
		font.draw(text, parentPos + fontAlign, fontColor);
	}

	/// set font and set widget size correctly
	void setFont(Font argFont)
	{
		font = argFont; 
		setSize(Size(font.getWidth(text), font.getHeight)); 
	}
}
