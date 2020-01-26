import 
	arc.types,
	arc.window, 
	arc.time,
	arc.input,
	arc.texture, 
        arc.x.particle.particle;
	 

struct Particle
{
	Point position = Point(0,0);
	Point velocity = Point(100,100);
	Size size = Size(32,32);
	Color color = Color.White;
	
	bool alive = true;
	arcfl age = 0.;
}

struct ParticleSystem
{
	void setup()
	{
		tex = Texture("testbin/particle.png");
		particles.length = 1000;
		particles.length = 0;
	
		posrnd = makeLineRandom!(uniform1D)(Point(0,500), Point(640,500));
		velrnd = makeTriangleRandom!()(Point(10,-100), Point(-10,-100), Point(0,0));
		colrnd = makeLineRandom!(risingLinear1D)(Color(1., 0.5, 0.), Color.Red);
		agernd = makeLineRandom!(fallingLinear1D)(cast(arcfl)0.f, cast(arcfl)1.f);
	}
	
		
	void advance(arcfl msDt)
	{
		arcfl sDt = msDt / 1000.;
		
		Particle newParticle()
		{
			Particle newPart;
			posrnd.set(newPart.position);
			colrnd.set(newPart.color);
			velrnd.set(newPart.velocity);
			agernd.set(newPart.age);
			return newPart;
		}
		
		spawnPerSecond(particles, sDt, cast(arcfl)1000.f, &newParticle);
		age(particles, sDt);
		killOldAge(particles, cast(arcfl)2.f);
		move(particles, sDt);
	}
	
	void draw()
	{
		.draw(particles, tex);
	}
	
	Random!(Point) posrnd, velrnd;
	Random!(Color) colrnd;
 	Random!(arcfl) agernd;
	
	Particle[] particles;
	Texture tex;
}

// main is just here to handle states
int main()
{
	// open window with specific settings
	arc.window.open("Particle Test", 640, 480, false);
	
	ParticleSystem psystem;
	psystem.setup();
	
	// main loop
	while (!arc.input.keyDown(ARC_QUIT))
	{ 
		// clear the screen before drawing
		arc.window.clear();
		arc.input.process();
		arc.time.process();
		
		psystem.advance(elapsedMilliseconds());
		psystem.draw();

		// flip to next screen
		arc.window.swap();
		arc.time.limitFPS(40);
	}

	// close window when done with it
	scope(exit)
	{
		arc.window.close();
	}
	
	return 0;
}
