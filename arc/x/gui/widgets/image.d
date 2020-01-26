/******************************************************************************* 

	A image that can be clicked on.
	
    Authors:       ArcLib team, see AUTHORS file 
    Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
    License:       zlib/libpng license: $(LICENSE) 
    Copyright:     ArcLib team 
    
    Description:    
		Simply is a single image that can be used in GUI's. 

	Examples:
	--------------------
		import arc.x.gui.widgets.image; 
		
		Image image = new Image("guibin/penguin.png"); 

		while (!arc.input.keyDown(ARC_QUIT))
		{
			arc.input.process(); 
			arc.window.clear();

			image.setPosition(arc.input.mouseX, arc.input.mouseY); 
			image.process(); 
			image.draw();

			arc.window.swap();
		}
		--------------------

*******************************************************************************/

module arc.x.gui.widgets.image; 

import 	
	arc.types,
	arc.texture, 
	arc.draw.image, 
    arc.math.point, 
	arc.x.gui.widgets.widget;
	
import tango.util.log.Log;
	
/// logger for this module
public Logger logger;

static this()
{
	// setup logger
	logger = Log.getLogger("arc.x.gui.widgets.image");
}

/// Image widget 
class Image : Widget
{
  public:

	/// load widget based on image
	this(char[] argFullPath)
	{
		load(argFullPath); 
	}

	/// load image 
	void load(char[] argFullPath)
	{
		texture = Texture(argFullPath);
		setSize(texture.getSize);
	}

	/// draw image from position + parent position  
	void draw(Point parentPos = Point(0,0))
	{
		drawImageTopLeft(texture, position + parentPos, size, attr.fill); 
	}

  private:
	Texture texture; 
}
