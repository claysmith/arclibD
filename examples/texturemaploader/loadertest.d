module lvltest;

import arc.all; 
import arc.x.texturemaploader.texturemaploader; 
import arc.x.sprite.all; 

import tango.io.Stdout; 

import derelict.opengl.gl; 

import tango.text.convert.Integer; 

class MyGame : Game
{
	this(char[] argT, Size argS, bool argFS)
	{
		super(argT, argS, argFS);
	
		loader = new TextureMapLoader("testbin/spritesheet.png", Size(33,39));
		map = loader.getTextureMap();
		
		s = new Sprite(COLLISION_TYPE.BOX); 
		
		int i = 0; 
		
		// now we can build a sprite 
		foreach(Texture[] anim; map)
		{
			//char[] animName = "anim" ~ tango.text.convert.Integer.toString(i); 
			
			// load up anim
			foreach(Texture t; anim)
			{
				s.addFrame(t, "anim", 500, null); 
			}
		}
		
		s.setAnim("anim"); 
		
	}
	
	void process()
	{
		s.setPosition(200,200); 
		s.process();
		s.draw();
		s.drawBounds();
	}
	
	void shutdown()
	{
	}

	TextureMapLoader loader; 
	Texture[][] map; 
	Sprite s; 
}

int main() 
{ 
	Game g = new MyGame("Arclib Test", Size.d640x480, false); 
	g.setFPS(60);
	g.loop(); 
	
	return 0; 
} 
