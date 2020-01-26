/******************************************************************************* 

    ReadXML used in the background by layout to read XML files 

    Authors:       ArcLib team, see AUTHORS file 
    Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
    License:       zlib/libpng license: $(LICENSE) 
    Copyright:     ArcLib team 
    
    Description:    
		ReadXML used in the background by layout to read XML files.
	User will not want to use this file by itself. 

	Examples:
	--------------------
		Not provided.
	--------------------

*******************************************************************************/

module arc.x.gui.readxml; 

import
	tango.text.Util,
	tango.text.convert.Integer,
	tango.text.convert.Float,
	tango.text.xml.Document, 
	tango.io.Console,
	tango.io.FilePath,
	tango.io.File,
	tango.util.log.Log;

// XML parsing into Node structure code 
import arc.types;

/// logger for this module
public Logger logger;

static this()
{
	// setup logger
	logger = Log.getLogger("arc.x.gui.readxml");
}
	
// read xml layout data public interface 
public
{
	// Read layout data 
	LayoutData readLayoutXMLData(char[] fileName)
	{
		auto filepath = new FilePath(fileName);
		if (!filepath.exists())
		{
			throw new Exception("File " ~ fileName ~ " does not exist!"); 
		} 
		
		File file = new File(fileName); 
		
		auto doc = new XMLDoc;
		doc.parse(cast(char[])file.read());
		
		LayoutData layout; 
		
		// get our 'root' 
		auto root = doc.tree.child; 
		
		layout.name = root.name;

		char[] x,y,width,height; 
		
		foreach (attr; root.attributes())
		{
			if (attr.name == "x")
			{
				x = attr.value; 
			}
			if (attr.name == "y")
			{
				y = attr.value; 
			}
			if (attr.name == "width")
			{
				width = attr.value; 
			}
			if (attr.name == "height")
			{
				height = attr.value; 
			}
		}
		
		layout.position.x = tango.text.convert.Float.toFloat(x);
		layout.position.y = tango.text.convert.Float.toFloat(y);
		layout.size.w = tango.text.convert.Float.toFloat(width);
		layout.size.h = tango.text.convert.Float.toFloat(height);
		
		logger.info("Layout name is " ~ layout.name); 
		logger.info("Layout x, y is " ~ tango.text.convert.Float.toString(layout.position.x) ~ " , " ~ tango.text.convert.Float.toString(layout.position.y));
		logger.info("Layout w, h is " ~ tango.text.convert.Float.toString(layout.size.w) ~ " , " ~ tango.text.convert.Float.toString(layout.size.h));
		
		// Recurse through the entire tree and save data into skin
		recurseReadLayoutXML(layout, root);

		return layout;
	}

	// Read GUI data 
	GUIData readGUIXMLData(char[] fileName)
	{
		// Load XML into XML data structure
		auto filepath = new FilePath(fileName);
		if (!filepath.exists())
		{
			logger.fatal("File " ~ fileName ~ " does not exist!"); 
			throw new Exception("File " ~ fileName ~ " does not exist!"); 
		} 
		
		File file = new File(fileName); 
		
		auto doc = new XMLDoc;
		doc.parse(cast(char[])file.read());
		
		GUIData gui; 

		// Recurse through the entire tree and save data into skin
		recurseReadGUIXML(gui, doc.tree);

		return gui;
	}

	// GUI data /////////////////////////////////////////////
	struct GUIData
	{
		GUILayoutData[] layouts; 

		void addLayout(char[] name, char[] file, bool hide)
		{
			layouts.length = layouts.length + 1; 
			int curr = layouts.length-1; 
			
			layouts[curr].name = name;
			layouts[curr].file = file; 
			layouts[curr].hide = hide; 
		}
	}

	// each layout will contain this data 
	struct GUILayoutData
	{
		char[] name, file;
		bool hide; 
	}
	
	// Layout data //////////////////////////////////////////
	struct LayoutData
	{
		// name of the layout 
		char[] name;

		// x and y, width and height
		Point position;
		Size size;

		// layout widget data arrays
		ImageData[] images; 
		ButtonData[] buttons; 
		LabelData[] labels;
		TextBoxData[] textboxes; 
//        MenuData[] menus; 

		// add image widget 
		void addImage(char[] text, char[] name, Point pos, Size size, char[] color, char[] image)
		{
			images.length = images.length+1;
			int curr = images.length-1; 

			images[curr].name = name;
			images[curr].position = pos;
			images[curr].size = size;
			images[curr].color = color; 
			images[curr].image = image; 
		} 

		// add label widget 
		void addLabel(char[] text, Point pos, Size size, uint fontheight, char[] name, char[] color, char[] fontcolor, char[] fontname)
		{
			labels.length = labels.length+1;
			int curr = labels.length-1; 

			labels[curr].text = tango.text.Util.trim(text);
			labels[curr].position = pos;
			labels[curr].size = size;
			labels[curr].fontheight = fontheight;
			labels[curr].name = name;
			labels[curr].color = color;
			labels[curr].fontcolor = fontcolor; 
			labels[curr].fontname = fontname; 
			
			labels[curr].log(); 
		}

		void addTextBox(char[] text, Point pos, Size size, uint fontheight, char[] name, char[] color, char[] fontcolor, char[] fontname)
		{
			textboxes.length = textboxes.length+1;
			int curr = textboxes.length-1; 

			textboxes[curr].text = tango.text.Util.trim(text);
			textboxes[curr].position = pos;
			textboxes[curr].size = size;
			textboxes[curr].fontheight = fontheight; 
			textboxes[curr].name = name; 
			textboxes[curr].color = color; 
			textboxes[curr].fontcolor = fontcolor; 
			textboxes[curr].fontname = fontname; 
		}

		void addButton(char[] text, Point pos, Size size, uint fontheight, char[] name, char[] color, char[] fontcolor, char[] fontname)
		{
			buttons.length = buttons.length+1;
			int curr = buttons.length-1; 

			buttons[curr].text = tango.text.Util.trim(text);
			buttons[curr].position = pos;
			buttons[curr].size = size;
			buttons[curr].fontheight = fontheight;
			buttons[curr].name = name;
			buttons[curr].color = color;
			buttons[curr].fontcolor = fontcolor; 
			buttons[curr].fontname = fontname; 
		}
        
        // add a menu to the layout 
      /*  void addMenu(XMLNode items, char[] name, char[] color, char[] fontcolor, char[] fontname)
        {
            menus.length = menus.length+1; 
            int curr = menus.length-1; 
            
            // set up basic menu properties 
            menus[curr].name = name; 
            menus[curr].color = color; 
            menus[curr].fontcolor = fontcolor; 
            menus[curr].fontname = fontname; 
            
            // set up the menu tree structure into our tree structure 
            // create and set the root node 
            menus[curr].menu = new TreeStructure!(char[]);
            menus[curr].getRoot().setData("root"); 
            
            // process and add all the children to our tree structure 
            processMenuChildren(items, curr); 
        }*/
        
       /* void processMenuChildren(XMLNode parent, int curr)
        {
            foreach(XMLNode child; parent.children())
            {
                // If our parent name is menu
                if (parent.name() == "menu")
                {
                    // Create a new tree node and add it directly to our structure
                    Node!(char[]) n = new Node!(char[]); 
                    n.setData(fontheight("name")); 
                    
                    
                    
                    menus[curr].menu.addNode(n); 
                }
                
                processMenuChildren(child, curr); 
            }
        }*/

		void log()
		{
			int curr = 1;
			foreach(ImageData img; images)
			{
				logger.info("Image num " ~ tango.text.convert.Integer.toString(curr++)); 
				img.log(); 
			}
		}
	}
	
/*    struct MenuData
    {
        char[] name, color, fontcolor, fontname; 
        TreeStructure!(char[]) menu; 
    }*/

	struct ButtonData
	{
		Point position;
		Size size;
		uint fontheight; 
		char[] name, text, color, fontcolor, fontname; 
	}

	struct TextBoxData 
	{
		Point position; 
		Size size;
		uint fontheight; 
		uint maxwidth=0;
		uint maxlines=0; 
		char[] name, text, color, fontcolor, fontname;
	}

	struct LabelData 
	{
		Point position;
		Size size;
		uint fontheight; 
		char[] name, text, color, fontcolor, fontname; 
		
		void log()
		{	
			logger.info("Label x is " ~ tango.text.convert.Float.toString(position.x) ~ " and y is " ~ tango.text.convert.Float.toString(position.y) ~ " with name " ~ name); 
			logger.info("Label w is " ~ tango.text.convert.Float.toString(size.w) ~ " and h is " ~ tango.text.convert.Float.toString(size.h)); 
		}
	}

	// single image can hold a list of frames 
	struct ImageData
	{
		Point position;
		Size size;
		char[] name; 
		char[] color;
		char[] image;

		void log()
		{
			logger.info("Image x is " ~ tango.text.convert.Float.toString(position.x) ~ " and y is " ~ tango.text.convert.Float.toString(position.y) ~ " with name " ~ name); 
		}
	}

}

// privates user should not access 
private 
{
	char[][] validWidgets; 
	
	void initializeValidParents()
	{
		validWidgets.length = 4; 
		validWidgets[0] = "button"; 
		validWidgets[1] = "image"; 
		validWidgets[2] = "label";
		validWidgets[3] = "textfield";
	}

	// Recursively print all Nodes in the xml tree
	void recurseReadLayoutXML(inout LayoutData layout, XMLNode node)
	{
		// For each xml node 
		foreach (XMLNode child; node.children())
		{
			char[] name = child.name(); 
			
			char[] attrName, x, y, width, height, color, image, fontcolor, fontheight, fontname;
			
			foreach(attr; child.attributes())
			{
				if (attr.name == "name")
				{
					attrName = attr.value; 
				}
				if (attr.name == "x")
				{
					x = attr.value; 
				}
				if (attr.name == "y")
				{
					y = attr.value; 
				}
				if (attr.name == "width")
				{
					width = attr.value; 
				}
				if (attr.name == "height")
				{
					height = attr.value; 
				}
				if (attr.name == "color")
				{
					color = attr.value; 
				}
				if (attr.name == "image")
				{
					image = attr.value; 
				}
				if (attr.name == "fontcolor")
				{
					fontcolor = attr.value; 
				}
				if (attr.name == "fontheight")
				{
					fontheight = attr.value; 
				}
				if (attr.name == "fontname")
				{
					fontname = attr.value; 
				}
			}
			
			
			if (name == "image")
			{
				layout.addImage(
								child.value,
								attrName, 
								Point(toFloat(x),	toFloat(y)), 
								Size(toFloat(width), toFloat(height)),
								color, 
								image);
			}
			else if (name == "label")
			{
				layout.addLabel(
								child.value,
								Point(toFloat(x),	toFloat(y)), 
								Size(toFloat(width), toFloat(height)),
								tango.text.convert.Integer.toInt(fontheight),
								attrName,
								color,
								fontcolor,
								fontname); 
			}
			else if (name == "button")
			{
                
				layout.addButton(
								child.value,
								Point(toFloat(x),	toFloat(y)), 
								Size(toFloat(width), toFloat(height)),
								tango.text.convert.Integer.toInt(fontheight),
								attrName,
								color,
								fontcolor,
								fontname); 
			}
			else if (name == "textbox")
			{
				layout.addTextBox(
								child.value,
								Point(toFloat(x),	toFloat(y)), 
								Size(toFloat(width), toFloat(height)),
								tango.text.convert.Integer.toInt(fontheight), 
								attrName, 
								color, 
								fontcolor,
								fontname);
			}
            else if (name == "menu")
            {
                // We are going to add a new menu to our GUI layout 
                /*layout.addMenu(child, 
                                attrName,
                                color,fontcolor,fontname); */
            }

			// recurse until we have read entire structure 
			recurseReadLayoutXML(layout, child);
		}
	}

	// Recursively print all Nodes in the xml tree
	void recurseReadGUIXML(inout GUIData gui, XMLNode node)
	{
		// For each xml node 
		foreach (XMLNode child; node.children())
		{
			char[] name = child.name(); 
						
			if (name == "layout")
			{
				logger.info("Layout name is " ~ name); 

				bool b=false;
				
				char[] attrName, attrFile; 
				
				foreach(attr; child.attributes())
				{
					if (attr.name=="hide" && attr.value=="true") 
					{
						logger.info("Set true"); 
						b=true; 
					}
					else if (attr.name=="hide" && attr.value=="false")
					{
						logger.info("Set false"); 
						b=false; 	
					}
					
					if (attr.name == "name")
					{
						attrName = attr.value; 
					}
					
					if (attr.name == "file")
					{
						attrFile = attr.value; 
					}
				}

				gui.addLayout(attrName, 
								attrFile,
								b);
			}
			
			
			// recurse until we have read entire structure 
			recurseReadGUIXML(gui, child);
		}
		
	}
}
