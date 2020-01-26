/******************************************************************************* 

	The base class for all of the widgets 
	
	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:     ArcLib team 
    
    Description:    
		The base class for all of the widgets. This class is not to be used
		by itself. 

	Examples:
	--------------------
		None Provided
	--------------------

*******************************************************************************/

module arc.x.gui.widgets.widget; 

import 
	tango.util.log.Log,
	tango.core.Signal;
	
import 
	arc.draw.shape,
	arc.draw.attributes;
	
import 	
	arc.types,
	arc.texture,
	arc.draw.color,
	arc.draw.attributes, 
	arc.input,
	arc.math.collision,
	arc.math.point,
	arc.font,
	arc.x.gui.widgets.types;

/// logger for this module
public Logger logger;

/// initialize logger 
static this()
{
	// setup logger
	logger = Log.getLogger("arc.x.gui.widgets.widget");
}

public
{
	/// Text align left, center, and right 
	enum ALIGN 
	{
		///
		LEFTCENTER, 
		///
		LEFTUP,
		///
		LEFTDOWN,
		
		///
		RIGHTCENTER,
		///
		RIGHTUP,
		///
		RIGHTDOWN, 
		
		///
		CENTER, 
		///
		CENTERUP, 
		///
		CENTERDOWN
	}
}

/// Widget class, base class for all of the widgets 
class Widget
{
  public:
	this()
	{
	}

	/// set name of the widget 
	void setSize(Size argSize)
	{
		size = argSize;
	}

	/// set width of widget
	void setWidth(arcfl argW)
	{
		size.w = argW; 
	}

	/// set height of widget
	void setHeight(arcfl argH)
	{
		size.h = argH; 
	}

	/// set parent position of sprite 
	void setPosition(Point argPos)
	{
		position = argPos;
	}

	/// set color of the widget 
	void setColor(Color acolor)
	{
		attr.fill = acolor;
	}

	/// process widget 
	void process(Point parentPos = Point(0,0))
	{
		bool mOver = isMouseOver(parentPos); 

		action = ACTIONTYPE.DEFAULT;
	
		if (mOver && arc.input.mouseButtonPressed(LEFT))
		{
			//action = ACTIONTYPE.CLICKON;
			clickOn();

			if (arc.input.mouseButtonPressed(LEFT))
			{
				focus = true; 
			}
		}
		else if (arc.input.mouseButtonDown(LEFT))
		{
			// mouse button is clicked not on this widget
			clickOff(); 
			//action = ACTIONTYPE.CLICKOFF;

			if (arc.input.mouseButtonPressed(LEFT))
			{
				focus = false; 
			}
		}
		
		if (mOver)
		{
			// call mouse over signal
			mouseOver();
			action = ACTIONTYPE.MOUSEOVER; 
		}
		
	}

	/// get width 
	arcfl getWidth() {  return size.w; }

	/// get height 
	arcfl getHeight() { return size.h; } 
	
	/// get size
	Size getSize() { return size; }

	/// get x position 
	arcfl getX() { return position.x; }

	/// get Y position 
	arcfl getY() { return position.y; }
	
	/// get position
	Point getPosition() { return position; }

	/// return true if mouse is over widget 
	bool isMouseOver(Point parentPos) 
	{ 
		return boxXYCollision(	arc.input.mousePos, position + parentPos, size); 
	} 

	/// set color of font 
	void setFontColor(Color afontColor)
	{
		fontColor = afontColor;
	}

	/// set text values
	void setText(char[] argText)
	{
		text = argText; 
	}

	/// set font value 
	void setFont(Font argFont)
	{
		font = argFont; 
		fontAlign = getAlignment; 
	}

	/// draw image from position + parent position  
	void draw(Point parentPos = Point(0,0))
	{
		logger.fatal("Base Widget Class Draw Functionality Not Implemented"); 
	}

	/// set maximum amount of lines 
	void setMaxLines(uint argLines)
	{
		logger.fatal("Base Widget Class setMaxLines Functionality Not Implemented"); 
	}

	/// set maximum width  
	void setMaxWidth(uint maxWidth)
	{
		logger.fatal("Base Widget Class setMaxWidth Functionality Not Implemented"); 
	}

	/// return focus 
	bool getFocus() { return focus; }

	/// set alignment of text
	void setAlignment(ALIGN aText)
	{
		alignment = aText; 
		fontAlign = getAlignment(); 
	}
	
	/// get text inside of widget
	char[] getText() { return text; }
	
	/// called when widget is clicked on 
	Signal!() clickOn;
	
	/// called when widget is clicked off of 
	Signal!() clickOff; 
	
	/// called when mouse is over widget
	Signal!() mouseOver; 
	
  protected:

	// get alignment 	
	Point getAlignment()
	{
		Point drawFontPos;
		
		switch(alignment)
		{
			case ALIGN.LEFTCENTER: 
			drawFontPos = position;
			drawFontPos.y += size.h/2 - font.getLineSkip/2; 
			break; 
			
			case ALIGN.LEFTUP: 
			drawFontPos = position;
			break; 
			
			case ALIGN.LEFTDOWN: 
			drawFontPos = position;
			drawFontPos.y += size.h - font.getLineSkip; 
			break; 
			
			case ALIGN.RIGHTCENTER: 
			drawFontPos = position;
			drawFontPos.y += size.h/2 - font.getLineSkip/2;
			drawFontPos.x += size.w - font.getWidth(text); 			
			break;

			case ALIGN.RIGHTUP: 
			drawFontPos = position;
			drawFontPos.x += size.w - font.getWidth(text); 			
			break;

			case ALIGN.RIGHTDOWN: 
			drawFontPos = position;
			drawFontPos.y += size.h - font.getLineSkip;
			drawFontPos.x += size.w - font.getWidth(text); 			
			break;
			
			case ALIGN.CENTER: 
			drawFontPos = position + size/2 - Point(font.getWidth(text), font.getLineSkip)/2;
			break; 
			
			case ALIGN.CENTERUP: 
			drawFontPos = position;
			drawFontPos.x += size.w/2 - font.getWidth(text)/2;
			break; 
			
			case ALIGN.CENTERDOWN: 
			drawFontPos = position;
			drawFontPos.x += size.w/2 - font.getWidth(text)/2;
			drawFontPos.y += size.h - font.getLineSkip;
			break; 
		}

		return drawFontPos; 
	}
	  
	// will hold the position relative to the layout
	Point position;
	Size size;

	// color values 
	//Color color;
	DrawAttributes attr; 

	// font color values 
	Color fontColor; 

	// font text and alignment 
	char[] text; 
	ALIGN alignment = ALIGN.CENTER; 

	// font 
	Font font; 
	Point fontAlign; 

	// focus value 
	bool focus=false;

	// info signal will emit
	ACTIONTYPE action;  
}
