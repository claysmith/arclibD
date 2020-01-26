/******************************************************************************* 

	A node that draws text.

	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Christian Kamm (kamm incasoftware de) 
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:     ArcLib team 

	Description:    
		Renders text with specific font and color 


	Example:
	---------------------
	Text mytext = new Text(myfont, Color.Red);
	mytext.text = "Hello World!";
	
	rootNode.addChild(mytext);
	---------------------

*******************************************************************************/

module arc.x.scenegraph.text;

import
	arc.x.scenegraph.node,
	arc.x.scenegraph.drawable,
	arc.types,
	arc.font,
	arc.draw.color,
	arc.math.point;

//TODO: This could use an integrated transform.

/**
	Drawable that displays a line of text.
**/
class Text : MultiParentNode, IDrawable
{
	/// construct with font and color values
	this(Font afont, Color acolor)
	{
		font = afont;
		color = acolor;
	}
	
	/// draw text at position 
	override void draw()
	{		
		font.draw(text, Point.Zero, color); 
	}
	
	char[] text;
	
private:
	Font font;
	Color color;
}
