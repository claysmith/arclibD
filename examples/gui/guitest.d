import arc.all,
       arc.x.gui.all;

import tango.io.Console;

class HandleGUI
{
	void label()
	{
		Cout("click on label")(); 
	}

	void image()
	{
		Cout("click on image")(); 
	}
}


int main()
{
	arc.window.open("GUI Development", 800, 600, false); 
	arc.input.open(); 
        arc.font.open();

	HandleGUI handle = new HandleGUI; 

	GUI gui = new GUI("testbin/gui.xml");

	//gui.getLayout("layout1").getWidget("myimg").clicked.attach(&handle.image);
	//gui.getLayout("layout1").getWidget("lbl1").clicked.attach(&handle.label);
	
	setTheme(new FreeUniverseTheme); 

	while (!arc.input.keyDown(ARC_QUIT))
	{
		arc.input.process();
		arc.window.clear(); 

		gui.process();
		gui.draw(); 
        gui.drawBounds();
		
		arc.window.swap(); 
	}

	scope(exit) { arc.window.close(); }

	return 0;
}





