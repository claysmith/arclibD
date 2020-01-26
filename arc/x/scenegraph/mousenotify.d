/******************************************************************************* 

	Notifications for mouse events in subsections of the screen.

	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Christian Kamm (kamm incasoftware de) 
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:     ArcLib team 

	Description:    
		The MouseNotifyNode will emit signals when the mouse moves, enters, 
		leaves or clicks within a given rectangular area.
		
		Note that if you want to catch all mouse events, deal with arc.input
		directly.

	Example:      
	---------------------
	auto notifier = new MouseNotifyNode(Rect(-16,-16,32,32));
	notifier.sigButtonDown(&switchOnSelectionBox);
	notifier.sigButtonUp(&switchOffSelectionBox);
	
	// shipNode is the child of a complex hierarchy of nodes, especially transforms
	shipNode.addChild(notifier);
	---------------------

*******************************************************************************/

module arc.x.scenegraph.mousenotify;

import
	arc.x.scenegraph.advancable,
	arc.x.scenegraph.node,
	arc.x.scenegraph.transform,
	arc.x.scenegraph.root,
	arc.math.rect,
	arc.math.point,
	arc.input,
	arc.internals.input.signals,
	arc.types;

import
	tango.core.Signal;

/**
	Will fire signals when the mouse moves, enters, leaves or clicks
	within a given rectangular area.
**/
class MouseNotifyNode : SingleParentNode, INotifyOnRootTreeAddRemove
{
	/**
		The rect determines the area that is checked for mouse activity.
		Usually, it'll be an area around the origin, like (-10,-10) to (10,10).
	**/
	this(Rect aarea)
	{
		area = aarea;
		inside = false;
	}
	
	/// emitted when mouse moves in area
	Signal!(Point, MouseNotifyNode) sigMove;
	/// emitted when mouse enters area
	Signal!(Point, MouseNotifyNode) sigEnter;
	/// emitted when mouse leaves area
	Signal!(Point, MouseNotifyNode) sigLeave;
	/// emitted when mouse button goes down in area
	Signal!(int, Point, MouseNotifyNode) sigButtonDown;
	/// emitted when mouse button goes up in area
	Signal!(int, Point, MouseNotifyNode) sigButtonUp;
	
	/**
		This node should only every worry about user input when it is 
		in the root tree. Therefore, make sure the input signals are
		connected and disconnected as needed.
	**/
	override void addedToRootTree()
	{
		arc.internals.input.signals.signals.mouseButtonDown.attach(&slotButtonDown);
		arc.internals.input.signals.signals.mouseButtonUp.attach(&slotButtonUp);
		arc.internals.input.signals.signals.mouseMove.attach(&slotMove);
	}
	
	/// ditto
	override void removedFromRootTree()
	{
		arc.internals.input.signals.signals.mouseButtonDown.detach(&slotButtonDown);
		arc.internals.input.signals.signals.mouseButtonUp.detach(&slotButtonUp);
		arc.internals.input.signals.signals.mouseMove.detach(&slotMove);		
	}

private:
	void slotMove(Point pos)
	{
		pos = transformCoordinates(pos, rootNode, this);
		if(area.contains(pos))
		{
			sigMove(pos, this);
			if(!inside)
			{
				inside = true;
				sigEnter(pos, this);
			}
		}
		else if(inside)
		{
			inside = false;
			sigLeave(pos, this);
		}
	}
	
	void slotButtonUp(int button, Point pos)
	{
		pos = transformCoordinates(pos, rootNode, this);
		if(area.contains(pos))
			sigButtonUp(button, pos, this);
	}
	
	void slotButtonDown(int button, Point pos)
	{
		pos = transformCoordinates(pos, rootNode, this);
		if(area.contains(pos))
			sigButtonDown(button, pos, this);
	}	

	Rect area;	
	bool inside;
}
