/******************************************************************************* 

    Arc's GUI system 

    Authors:       ArcLib team, see AUTHORS file 
    Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
    License:       zlib/libpng license: $(LICENSE) 
    Copyright:     ArcLib team 
    
    Description:    
		Arc GUI class can hold a number of layouts of GUI widgets to 
		allow users to create GUI's for their games. 

	Examples:
	--------------------
	import arc.x.gui.gui;

	int main()
	{
		// load GUI file from XML
		HandleGUI handle = new HandleGUI; 
		GUI gui = new GUI("unittestbin/gui.xml");

		// connect layout widgets actions with specific code 
		gui.getLayout("layout1").getWidget("myimg").clicked.attach(&handle.image);
		gui.getLayout("layout1").getWidget("lbl1").clicked.attach(&handle.label);
		
		while (!arc.input.keyDown(ARC_QUIT))
		{
			arc.input.process();
			arc.window.clear(); 

			gui.process();
			gui.draw(); 

			arc.window.swap(); 
		}
		
		return 0; 
	}

	--------------------

*******************************************************************************/

module arc.x.gui.gui; 

import
	tango.util.log.Log;

import 
	arc.x.gui.layout,
	arc.x.gui.readxml,
	arc.types; 

public import arc.x.gui.widgets.widget; 

/// logger for this module
public Logger logger;

static this()
{
	// setup logger
	logger = Log.getLogger("arc.x.gui.gui");
}

/// GUI class 
class GUI 
{
  public: 
	/// load GUI from xml file 
	this(char[] xmlfile)
	{
		logger.info("Loading GUI " ~ xmlfile); 
		// read GUI xml data 
		
		logger.info("Reading " ~ xmlfile); 
		GUIData gui = readGUIXMLData(xmlfile);

		// load each of the layouts 
		foreach(GUILayoutData layout; gui.layouts)
		{
			logger.info("Loading layout " ~ layout.name); 
			Layout l = new Layout(layout.file); 
			l.setHide(layout.hide); 
			layouts[layout.name] = l; 
			logger.info("Loaded layout " ~ layout.name);
		}

		// optimize layout hash 
		layouts.rehash; 
	}

	/// draw gui 
	void draw()
	{
		foreach(Layout l; layouts)
			l.draw(); 
	}
    
    /// draw layout bounds of the GUI
    void drawBounds()
    {
        foreach(Layout l; layouts)
            l.drawBounds(); 
    }

	/// process gui 
	void process()
	{
		foreach(Layout l; layouts)
			l.process(); 
	}

	/// get layout 
	Layout getLayout(char[] layoutName)
	{
		if (!(layoutName in layouts))
		{
			logger.fatal("Layout name " ~ layoutName ~ " is not in layouts!"); 
		}
		
		return layouts[layoutName];
	}
  
  private: 
	Layout[char[]] layouts; 
}
