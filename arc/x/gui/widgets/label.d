/******************************************************************************* 

	A label that can be clicked on.
	
    Authors:       ArcLib team, see AUTHORS file 
    Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
    License:       zlib/libpng license: $(LICENSE) 
    Copyright:     ArcLib team 
    
    Description:    
		Simply is a single label that can be used in GUI's. 

	Examples:
	--------------------
		import arc.x.gui.widgets.label; 
		
		Label label = new Label(); 
		label.setFont(font);
		label.setText("Hello"); 

		while (!arc.input.keyDown(ARC_QUIT))
		{
			arc.input.process(); 
			arc.window.clear();

			label.setPosition(arc.input.mouseX, arc.input.mouseY); 
			label.process(); 
			label.draw();

			arc.window.swap();
		}
		--------------------

*******************************************************************************/

module arc.x.gui.widgets.label;

import
	arc.types,
    arc.math.point, 
	arc.font,
	arc.x.gui.widgets.widget,
	arc.x.gui.themes.theme;
    
/// Label widget 
class Label : Widget 
{
  public: 

	/// draw label with parent x and y position 
	void draw(Point parentPos = Point(0,0))
	{
		arc.x.gui.themes.theme.theme.drawLabel(action, focus, position + parentPos, size, attr);
		font.draw(text, parentPos + fontAlign, fontColor);
	}
  
	/// set font and set widget size correctly
	void setFont(Font argFont)
	{
		font = argFont; 
		setSize(Size(font.getWidth(text), font.getHeight));
	}
}
