module arc.draw.attributes;

import arc.draw.color; 

/// SVG styled drawing attributes 
struct DrawAttributes
{
	// Color of shape outline
	Color stroke=Color.Blue; 
	
	// Color of shape
	Color fill=Color.Red; 
	
	// Width of outline, 0 and outline will be ignored
	float strokeWidth=1;
	
	// whether or not to fill, otherwise will stroke
	bool isFill=true; 
	
	// detail to draw curves with
	int detail=10; 
}