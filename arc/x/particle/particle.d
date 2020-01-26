/******************************************************************************* 

	Particle engine allows particle effects 

	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:     ArcLib team 
    
    Description:    
		Particle engine allows particle effects 

	Examples:
	--------------------
		None provided.
	--------------------

*******************************************************************************/

module arc.x.particle.particle;

// openGL + SDL
import 
	derelict.opengl.gl,
	derelict.sdl.sdl,  
	derelict.sdl.image; 

// ARC
import 
	arc.types,
	arc.texture, 
	arc.math.routines;

import
	arc.draw.image;

//
// randomness
//

template Adapter(T : arcfl)
{
	const n = 1;
	void get(arcfl val, arcfl[n] data) { data[0] = val; }
	void set(ref arcfl val, arcfl[] data) { val = data[0]; }
}

template Adapter(T : Point)
{
	const n = 2;
	void get(ref Point p, arcfl[n] data) { data[0] = p.x; data[1] = p.y; }
	void set(ref Point p, arcfl[] data) { p = Point(data[0], data[1]); }
}

template Adapter(T : Size)
{
	const n = 2;
	void get(ref Size p, arcfl[n] data) { data[0] = p.w; data[1] = p.h; }
	void set(ref Size p, arcfl[] data) { p = Size(data[0], data[1]); }
}

template Adapter(T : Color)
{
	const n = 4;
	void get(ref Color c, arcfl[n] data) { data[0] = c.r; data[1] = c.g; data[2] = c.b; data[3] = c.a; }
	void set(ref Color c, arcfl[] data) { c = Color(data[0], data[1], data[2], data[3]); }	
}

class Random(T)
{
	abstract arcfl[] getRandom();

	void set(ref T target)
	{
		Adapter!(T).set(target, getRandom());
	}
}


template makeLineRandom(alias distr)
{
	LineRandom!(T, distr) makeLineRandom(T)(T start_, T end_)
	{
		auto rand = new LineRandom!(T, distr);
		Adapter!(T).get(start_, rand.start);
		Adapter!(T).get(end_, rand.end);
		return rand;
	}
}

class LineRandom(T, alias distr) : Random!(T)
{
	const n = Adapter!(T).n;

	override arcfl[] getRandom()
	{
		arcfl t = distr();
		for(size_t i = 0; i < n; ++i)
			random[i] = start[i] + t * (end[i] - start[i]);
		return random;
	}
	
	private arcfl[n] start, end, random;
}

template makeTriangleRandom(alias distr = uniform1D)
{
	TriangleRandom!(T, distr) makeTriangleRandom(T)(T v1_, T v2_, T v3_)
	{
		auto rand = new TriangleRandom!(T, distr);
		Adapter!(T).get(v1_, rand.v1);
		Adapter!(T).get(v2_, rand.v2);
		Adapter!(T).get(v3_, rand.v3);
		return rand;		
	}
}
	
class TriangleRandom(T, alias distr) : Random!(T)
{
	const n = Adapter!(T).n;

	override arcfl[] getRandom()
	{
		arcfl b1 = distr();
		arcfl b2 = distr();
		arcfl b3 = 1. - b1 - b2;
		if(b3 < 0)
		{
			b1 += b3;
			b2 += b3;
			b3 = abs(b3);
		}
		for(size_t i = 0; i < n; ++i)
			random[i] = b1 * v1[i] + b2 * v2[i] + b3 * v3[i];
		return random;
	}

	private arcfl[n] v1, v2, v3, random;
}
	
template makeBallRandom(alias radiusdistr, alias angledistr = uniform1D)
{
	BallRandom!(T, radiusdistr, angledistr) makeBallRandom(T)(T center_, arcfl radius_)
	{
		auto rand = new BallRandom!(T, radiusdistr, angledistr);
		Adapter!(T).get(center_, rand.center);
		rand.radius = radius_;
		return rand;
	}
}
	
class BallRandom(T, alias radiusdistr, alias angledistr) : Random!(T)
{
	const n = Adapter!(T).n;

	override arcfl[] getRandom()
	{
		arcfl d = radiusdistr() * radius;
		angles[0] = angledistr() * 2 * PI;
		for(size_t i = 1; i < n - 1; ++i)
			angles[i] = angledistr() * PI;
		for(size_t i = 0; i < n; ++i)
		{
			random[i] = d;
			for(size_t j = i; j < n - 1; ++j)
				random[i] *= sin(angles[j]);
			if(i > 0)
				random[i] *= cos(angles[i-1]);					
			random[i] += center[i];
		}
		return random;			
	}
	
	private arcfl[n] center, angles, random;
	private arcfl radius;
}


template makeBoxRandom(alias distr)
{
	BoxRandom!(T, distr) makeBoxRandom(T)(T corner1_, T corner2_)
	{
		auto rand = new BoxRandom!(T, distr);
		Adapter!(T).get(corner1_, rand.corner1);
		Adapter!(T).get(corner2_, rand.corner2);
		return rand;
	}
}
	
class BoxRandom(T, alias distr) : Random!(T)
{
	const n = Adapter!(T).n;

	override arcfl[] getRandom()
	{
		for(size_t i = 0; i < n; ++i)
		{
			arcfl rnd = distr();
			random[i] = (1. - rnd) * corner1[i] + rnd * corner2[i];
		}
		return random;			
	}
	
	private arcfl[n] corner1, corner2, random;
}


arcfl uniform1D()
{
	return randomRange(0.0, 1.0);
}

arcfl risingLinear1D()
{
	return sqrt(cast(arcfl)randomRange(0.0, 1.0));
}

arcfl fallingLinear1D()
{
	return 1. - sqrt(1. - randomRange(0.0, 1.0));
}


//
// particles
//

void slowSpawnPerSecond(T)(ref T[] pgroup, arcfl sDt, arcfl newPerSecond, T delegate() newT, ref arcfl leftover)
{
	size_t nNew = cast(size_t)( (sDt + leftover) * newPerSecond );
	if(nNew == 0)
	{
		leftover += sDt;
		return;
	}
	else
		leftover -= nNew / newPerSecond;

	spawn(pgroup, nNew, newT);
}

void spawnPerSecond(T)(ref T[] pgroup, arcfl sDt, arcfl newPerSecond, T delegate() newT)
{
	arcfl fNew = sDt * newPerSecond;
	size_t nNew = rndint(fNew - 0.5);
	if(randomRange(0.,1.) < fNew - nNew)
		nNew += 1;
	
	if(nNew == 0)
		return;
	
	spawn(pgroup, nNew, newT);
}

void spawn(T)(ref T[] pgroup, size_t nNew, T delegate() newT)
{
	size_t revived = 0;	
	foreach(ref p; pgroup)
		if(!p.alive)
		{
			p = newT();
			revived += 1;
			if(revived >= nNew)
				return;
		}
	
	auto new_particles = new T[nNew - revived];
	foreach(ref p; new_particles)
		p = newT();
	
	pgroup ~= new_particles;	
}

void move(T)(ref T[] pgroup, arcfl sDt)
{
	foreach(ref p; pgroup)
		p.position += (sDt) * p.velocity;
}

void age(T)(ref T[] pgroup, arcfl by)
{
	foreach(ref p; pgroup)
		p.age += by;
}

void killOldAge(T)(ref T[] pgroup, arcfl threshold)
{
	foreach(ref p; pgroup)
		if(p.alive && p.age >= threshold)
			p.alive = false;
}

int aliveCount(T)(ref T[] pgroup)
{
	int ret = 0;
	foreach(ref p; pgroup)
		if(p.alive)
			++ret;
	return ret;
}

void fade(T)(ref T[] pgroup, arcfl zeroby)
{
	foreach(ref p; pgroup)
		if(p.alive)
			p.color.a = p.age < zeroby ? (zeroby - p.age) / zeroby : 0.;
}

void draw(T)(ref T[] pgroup, ref Texture t)
{
	glBlendFunc(GL_SRC_ALPHA, GL_ONE);

	foreach(ref p; pgroup)
		if(p.alive)
			drawImage(t, p.position, p.size, Point(0,0), 0, p.color);
	
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}
