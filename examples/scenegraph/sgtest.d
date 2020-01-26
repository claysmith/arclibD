import
	arc.all,
	arc.x.scenegraph.all;
    
import tango.math.Math;

Frame asteroidFrame, orbiterFrame;

class Orbiter : Sprite, IAdvancable
{
	this()
	{
		super(orbiterFrame);
	}
	
	override void advance(arcfl msDt)
	{
		transform.rotation = restrictRad(transform.rotation + 0.001*msDt);
	}
}

class Asteroid : Sprite
{
	this()
	{
		super(asteroidFrame);
	}
}

class TransformEffect : Transform, IAdvancable
{
	this()
	{
		translation = Point(320,240);
		elapsed = 0;
		makeNewTarget();
	}
	
	override void advance(arcfl msDt)
	{
		elapsed += msDt;
		
		if(elapsed > duration)
		{
			makeNewTarget();
			elapsed = 0;
		}
		
		arcfl alpha;
		if(elapsed < duration/2)
		{
			alpha = elapsed/(duration/2);
		}
		else
		{
			alpha = 2 - elapsed / (duration/2);
		}
			
		translation = Point(320,240) + alpha * targetMove;
		rotation = alpha * targetRot;
		scale = Point(1,1) + alpha * targetScale;
	}
	
	void makeNewTarget()
	{
		duration = randomRange(2000,5000);
		
		targetRot = randomRange(0,100) / 100. * PI/2 - PI/4;
		targetMove = Point(randomRange(-100,100),randomRange(-100,100));
		targetScale = Point(randomRange(-3,5) / 5., randomRange(-3,5) / 5.);
	}
	
	Radians targetRot;
	Point targetMove;
	Point targetScale;
	
	arcfl duration;
	arcfl elapsed;
}

class Grid : MultiParentNode, IDrawable
{
	this()
	{
		attr.fill = Color.Red; 
		attr.isFill = false; 
	}
	
	override void draw()
	{
		uint n_rects = 10;
		for(uint i = 1; i <= 10; ++i)
		{
			drawRectangle(Point(-320 * (i/10.),-240 * (i/10.)), Size(640*(i/10.),480*(i/10.)), attr);
		}
	}
	
	DrawAttributes attr; 
}

void main()
{
	// transform unittest 
	GroupNode root = new GroupNode;
	Transform a = new Transform, b = new Transform, c = new Transform;
	Point res;
	
	root.addChild(a);
	a.addChild(b);
	root.addChild(c);
	
	a.translation = Point(1,0);
	b.translation = Point(2,0);
	c.translation = Point(4,0);
	
	res = transformCoordinates(Point(8,1), b, c);
	assert(res.x == 7 && res.y == 1);
	
	a.rotation = PI/2;
	res = transformCoordinates(Point(8,1), b, c);
	//assert(res.x + 4 + res.y - 10 < arcfl.epsilon * 10);
	
	res = transformCoordinates(Point(-4, 10), c, b);
	assert(res.x - 8 + res.y - 1 < arcfl.epsilon * 10);
	
	res = transformCoordinates(Point(0,0), root, b);
	assert(res.x + 2 + res.y - 1 < arcfl.epsilon * 10);
	
	a.scale = 0.5;
	res = transformCoordinates(Point(4,10), a, root);
	//assert(res.x + 4 + res.y - 2 < arcfl.epsilon * 10);
	
	// open window with specific settings
	arc.window.open("Scenegraph Test", 640, 480, false);
	arc.window.coordinates.setSize(Size(640,480));
	arc.input.open();
	
	arc.input.showCursor(false);
		
	asteroidFrame = new Frame(Texture("testbin/asteroid1.png"));
	orbiterFrame = new Frame(Texture("testbin/arrow.png"), Point(12, -50));
	
	auto asteroid = new Asteroid;
	auto transformEffect = new TransformEffect;
	
	rootNode.addChild(transformEffect);
	transformEffect.addChild(new Grid);
	transformEffect.addChild(asteroid);
	asteroid.addChild(new Orbiter);
	
	// main loop
	while (!arc.input.keyDown(ARC_QUIT))
	{ 
		// clear the screen before drawing
		arc.window.clear();
		arc.input.process();
		arc.time.process();

		asteroid.transform.translation = arc.input.mousePos - Point(320,240);
		
		advanceScenegraph(arc.time.elapsedMilliseconds());
		drawScenegraph();

		// flip to next screen
		arc.window.swap();
	}

	// close window when done with it
	scope(exit)
	{
		arc.input.close();
		arc.window.close();
	}
}
