/******************************************************************************* 

	Base frame class.

	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:     ArcLib team 

	Description:    
		Base frame class.

	Examples:      
	---------------------
		None provided.  
	---------------------

*******************************************************************************/

module arc.x.sprite.frame.frame;

import 
	arc.texture,
	arc.types,
	arc.math.point,
	arc.sound;

/// Holds either PIXEL, RADIUS, or BOX.
enum COLLISION_TYPE
{
	RADIUS=0,
	CIRCLE = RADIUS,
	BOX
}

/// common base to PixFrame, BoxFrame, and RadFrame
class Frame 
{
  public:
	// default const/dest
	this(){}
	~this(){}

    ///
	void process() 
    {
        if (snd !is null)
            snd.process();
    }

	// time it will be displayed for
	int time=30;
	// and sound effect
	Sound snd;
	Texture texture;
}

