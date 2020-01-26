/******************************************************************************* 

    Arc's layout can hold and arrange all GUI widgets 

    Authors:       ArcLib team, see AUTHORS file 
    Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
    License:       zlib/libpng license: $(LICENSE) 
    Copyright:     ArcLib team 
    
    Description:    
		Arc's layout can hold and arrange all GUI widgets.
	Use the GUI class if you want to hold multiple layouts in 
	one class. 
 

	Examples:
	--------------------
	import arc.x.gui.layout;

	int main()
	{
		// load GUI file from XML
		HandleGUI handle = new HandleGUI; 
		Layout layout = new Layout("layout.xml"); 

		// connect layout widgets actions with specific code 
		layout.getWidget("myimg").clicked.attach(&handle.image);
		layout.getWidget("lbl1").clicked.attach(&handle.label);
		
		while (!arc.input.keyDown(ARC_QUIT))
		{
			arc.input.process();
			arc.window.clear(); 

			layout.process();
			layout.draw(); 

			arc.window.swap(); 
		}
		
		return 0; 
	}

	--------------------

*******************************************************************************/

module arc.x.gui.layout; 

import
	tango.util.log.Log,
	tango.text.convert.Integer,
	tango.text.Util;

import 
	arc.font, 
	arc.x.gui.widgets.widget,
	arc.x.gui.widgets.image,
	arc.x.gui.widgets.label,
	arc.x.gui.widgets.button,
	arc.x.gui.widgets.textbox,
	arc.x.gui.readxml,
	arc.math.collision,
	arc.types,
	arc.math.point,
	arc.draw.shape,
	arc.draw.color; 

/// logger for this module
public Logger logger;

static this()
{
	// setup logger
	logger = Log.getLogger("arc.x.gui.layout");
}

/// Layout class 
class Layout : Widget
{
  public:
	/// read layout from an xml file 
	this(char[] fileName)
	{
		// read layout xml data 
		logger.info("Loading layout " ~ fileName); 
		LayoutData layout = readLayoutXMLData(fileName); 

		// set layout position and width 
		setPosition(layout.position);
		setSize(layout.size);

		Color makeColor(char[][] colorStr)
		{
			return Color(
				tango.text.convert.Integer.toInt(colorStr[0]), 
				tango.text.convert.Integer.toInt(colorStr[1]),
				tango.text.convert.Integer.toInt(colorStr[2]),
				tango.text.convert.Integer.toInt(colorStr[3]));
		}
		
		// add all images to the layout 
		foreach(ImageData image; layout.images)
		{
			if (!(image.name in widgets))
			{
				char[] currw = image.name; 
				char[][] color = tango.text.Util.split(image.color,";"); 

				widgets[currw] = new Image(image.image); 
				widgets[currw].setPosition(image.position);
				widgets[currw].setSize(image.size);
				widgets[currw].setColor(makeColor(color)); 

				widgetBoundsCheck(widgets[currw]);
			}
			else
			{
				logger.fatal("Error: The image " ~ image.name ~ " has the same name as another widget in " ~ fileName); 
			}
		}

		// add all labels to the layout 
		foreach(LabelData label; layout.labels)
		{
			if (!(label.name in widgets))
			{
				char[] currw = label.name; 
				char[][] color = tango.text.Util.split(label.color,";"); 
				char[][] fontcolor = tango.text.Util.split(label.fontcolor,";"); 

				Font font = new Font(label.fontname, label.fontheight); 

				widgets[currw] = new Label; 
				widgets[currw].setFont(font); 
				widgets[currw].setText(label.text); 
				widgets[currw].setPosition(label.position);
				widgets[currw].setSize(label.size);
				widgets[currw].setAlignment(ALIGN.CENTER); 
				
				widgets[currw].setColor(makeColor(color)); 
										
				widgets[currw].setFontColor(makeColor(fontcolor)); 

				widgetBoundsCheck(widgets[currw]);
			}
			else
			{
				logger.fatal("Error: The label " ~ label.name ~ " has the same name as another widget in " ~ fileName); 
			}

		}

		// add all buttons to the layout 
		foreach(ButtonData button; layout.buttons)
		{
			if (!(button.name in widgets))
			{
				char[] currw = button.name; 
				char[][] color = tango.text.Util.split(button.color,";"); 
				char[][] fontcolor = tango.text.Util.split(button.fontcolor,";"); 

				Font font = new Font(button.fontname, button.fontheight); 
	
				widgets[currw] = new Button();
				widgets[currw].setFont(font); 
				widgets[currw].setText(button.text); 
				widgets[currw].setPosition(button.position);
				widgets[currw].setSize(button.size);
				widgets[currw].setAlignment(ALIGN.CENTER); 

				widgets[currw].setColor(makeColor(color)); 
										
				widgets[currw].setFontColor(makeColor(fontcolor)); 

				widgetBoundsCheck(widgets[currw]);

			}
			else
			{
				logger.fatal("Error: The button " ~ button.name ~ " has the same name as another widget in " ~ fileName); 
			}

		}

		// add all textboxes to the layout 
		foreach(TextBoxData textboxes; layout.textboxes)
		{
			if (!(textboxes.name in widgets))
			{
				char[] currw = textboxes.name; 
				char[][] color = tango.text.Util.split(textboxes.color,";"); 
				char[][] fontcolor = tango.text.Util.split(textboxes.fontcolor,";"); 

				Font font = new Font(textboxes.fontname, textboxes.fontheight);

				widgets[currw] = new TextBox();
				widgets[currw].setFont(font); 
				widgets[currw].setText(textboxes.text); 
				widgets[currw].setPosition(textboxes.position);
				widgets[currw].setSize(textboxes.size);
				widgets[currw].setAlignment(ALIGN.CENTER); 


				widgets[currw].setColor(makeColor(color)); 
										
				widgets[currw].setFontColor(makeColor(fontcolor)); 

				widgetBoundsCheck(widgets[currw]);
			}
			else
			{
				logger.fatal("Error: The textbox " ~ textboxes.name ~ " has the same name as another widget in " ~ fileName); 
			}
		}

	}

	/// draw bounds of layout 
	void drawBounds(Point parentPos = Point(0,0))
	{
		if (hide)
			return; 
		
		attr.isFill = false; 
		
		drawRectangle(position + parentPos, size, attr);
	}

	/// draw layout 
	void draw(Point parentPos = Point(0,0))
	{
		if (hide)
			return; 

		foreach(char[] key; widgets.keys)
		{
			widgets[key].draw(position + parentPos);
		}
	}

	/// process layout 
	void process(Point parentPos = Point(0,0))
	{
		if (hide)
			return; 

		foreach(char[] key; widgets.keys)
		{
			widgets[key].process(position + parentPos);
		}
	}

	/// get widget by name from layout 
	Widget getWidget(char[] widgetName)
	{
		if (!(widgetName in widgets))
		{
			logger.fatal("The widget " ~ widgetName ~ " does not exist!");
		}
		
		return widgets[widgetName];
	}

	/// add a widget to the layout 
	void addWidget(char[] wname, Widget w)
	{
		if (wname in widgets)
		{
			logger.fatal("The widget " ~ wname ~ " already exist!");
		}
		
		widgets[wname] = w; 
		widgetBoundsCheck(w);
	}

	/// check to see if widget is within bounds 
	void widgetBoundsCheck(Widget w, Point parentPos = Point(0,0))
	{
		arcfl currX = parentPos.x + w.getX + position.x;
		arcfl currY = parentPos.y + w.getY + position.y;
		
		if (currX < position.x + parentPos.x || currX+w.getWidth > position.x + parentPos.x + size.w)
		{
			//writefln(currX, " ", position.x, " ", w.getX, " ", w.getWidth, " ", size.w);
			logger.fatal("widget outside of X bounds");
		}

		if (currY < position.y+parentPos.y || currY+w.getHeight > position.y+parentPos.y+size.h)
		{
			logger.fatal("widget outside of Y bounds"); 
		}
	}

	/// set hide or not 
	void setHide(bool argH) { hide = argH; }

  private:
		// hold widgets in array by name
		Widget[char[]] widgets;

		// whether to display and process layout or not 
		bool hide=false; 
  
}
