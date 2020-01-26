module memory; 

import 
	arc.memory.routines,
	arc.memory.freelist; 

import tango.io.Console; 

int main()
{
	int[] foo;
	int[] foo2; 
	foo.alloc(10);
	assert (foo.length == 10);
	foreach (i; foo) assert (i == int.init);
	foo.realloc(20);
	foo2 = foo.clone();
	assert(foo2.length == 20); 
	assert (foo.length == 20);
	foreach (i; foo) assert (i == int.init);
	foo.realloc(10);
	assert (foo.length == 10);
	foreach (i; foo) assert (i == int.init);
	foo.free();
	foo2.free();
	assert(foo2.length==0);
	
	uint barLen = 0;
	int[] bar;
	append(bar, 10, &barLen);
	append(bar, 20, &barLen);
	append(bar, 30, &barLen);
	append(bar, 40, &barLen);
	append(bar, 50, &barLen);
	
	assert (bar.length == 8);
	assert (barLen == 5);
	
	for (int i = 0; i < 20; ++i) 
	{
		append(bar, i, &barLen);
	}
	
	assert (bar.length == 32);
	assert (barLen == 25);
	
	assert (bar[6 .. 10] == [1, 2, 3, 4]);

	Cout("Slow Alloc")();
	SlowAlloc[10] s;
	
	for (int i = 0; i < 10000000; i++)
	{
		for(uint j = 0; j < 10; ++j)
			s[j] = new SlowAlloc;

		for(uint j = 0; j < 10; ++j)
			delete s[j];	
	}

	Cout("Fast Alloc")(); 

	FastAlloc[10] f; 
	for (int i = 0; i < 10000000; i++)
	{
		for(uint j = 0; j < 10; ++j)
			f[j] = FastAlloc.allocate();

		for(uint j = 0; j < 10; ++j)
			f[j].free(f[j]);		
	}

	return 0;
}

class SlowAlloc
{
	real a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p;
}

class FastAlloc 
{
	mixin FreeListAllocator; 
	real a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p;
}