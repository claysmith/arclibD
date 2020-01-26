module soundtest;

/*

// For Texture 
// For Sound 


*/

import arc.window,
		arc.math.point,
		arc.input,
		arc.sound;

import tango.io.Stdout;
        
int main()
{
  	Stdout("Press 's' to play a sound");

	arc.window.open("Sound Test", 800, 600, 0);
	arc.input.open(); 
	arc.sound.open(); 

	arc.sound.setListenerPosition(Point(0,0));
	arc.sound.setListenerVelocity(Point(0,0));
	arc.sound.setListenerOrientation(Point(0,0));

	SoundFile sf = new SoundFile("testbin/laser.wav"); 
	SoundFile sf2 = new SoundFile("testbin/remix.ogg"); 

	Sound snd = new Sound(sf);
	Sound snd2 = new Sound(sf2); 
	
	snd2.play();

	while (!(arc.input.keyPressed(ARC_QUIT) || arc.input.keyPressed(ARC_ESCAPE)))
	{
		arc.input.process(); 
		arc.window.clear();

		if (arc.input.keyPressed('s'))
		{
			snd.stop(); 
			snd.play();
			Stdout("Sound played");
		}

		snd.process(); 
		snd2.process();

		arc.window.swap();
	}

	scope(exit) { arc.sound.close(); arc.window.close(); }

	return 0;
}
