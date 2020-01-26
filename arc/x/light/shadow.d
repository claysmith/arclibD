/******************************************************************************* 

	Lighting code

	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Christian Kamm (kamm incasoftware de)
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:     ArcLib team 
	
	Description:
	Lighting code
	
	Examples:
	--------------------
	--------------------

*******************************************************************************/

module arc.x.light.shadow;

import arc.math.point;

import derelict.opengl.gl;

import 
	arc.x.light.light,
	arc.x.light.lightblocker,
	arc.x.light.penumbra,
	arc.x.light.umbra;


/***
	Draws the shadow of 'blocker' under the given 'light'
*/
void renderShadow(ref Light light, ref LightBlocker blocker)
{
	// get the line that blocks light for the blocker and light combination
	// move the light position towards blocker by its sourceradius to avoid
	// popping of penumbrae
	Point normal = blocker.position - light.position; normal.normalize; 
	
	Point[] blockerLine = blocker.getBlockedLine(light.position + normal * light.sourceradius);
	
	// if the light source is completely surrounded by the blocker, don't draw its shadow
	if(blockerLine.length == blocker.shape.edges.length + 1)
		return;
	
	/**
		scales a vector with respect to the light radius
		used for penumbra and umbra lights where the tips
		are not supposed to be visible
	**/
	Point extendDir(ref Point dir) { 
		return dir.normalizeCopy() * light.outerradius * 1.5; 
	}
	
	/**
		Displaces the light pos by sourceradius orthogonal to the line from
		reference to the light's position. Used for calculating penumbra size.
	**/
	Point getLightDisplacement(ref Point reference)	{
		Point lightdisp = Point.makePerpTo(reference - light.position);
		lightdisp.normalize();
		lightdisp *= light.sourceradius;
		if(lightdisp.dot(reference - blocker.position) < 0.)
			lightdisp *= -1.;
		return lightdisp;
	}
	
	/**
		Gets the direction that marks the beginning of total shadow
		for the given point.
	**/
	Point getTotalShadowStartDirection(ref Point at) {
		return extendDir(at - (light.position + getLightDisplacement(at)));
	}

	//
	// build penumbrae (soft shadows), cast from the edges
	//
	
	Penumbra rightpenumbra;
	{
		Point startdir = extendDir(blockerLine[0] - (light.position - getLightDisplacement(blockerLine[0])));
		rightpenumbra.sections ~= Penumbra.Section(
			blockerLine[0], 
			startdir,
			0.0);
		for(size_t i = 0; i < blockerLine.length - 1; ++i)
		{
			real wanted = abs(startdir.angle(getTotalShadowStartDirection(blockerLine[i])));
			real available = abs(startdir.angle(blockerLine[i+1] - blockerLine[i]));
			
			if(wanted < available)
			{
				rightpenumbra.sections ~= Penumbra.Section(
					blockerLine[i], 
					getTotalShadowStartDirection(blockerLine[i]), 
					1.0);
				break;
			}
			else
			{
				rightpenumbra.sections ~= Penumbra.Section(
					blockerLine[i+1], 
					extendDir(blockerLine[i+1] - blockerLine[i]),
					available / wanted);
			}
		}
	}
	
	Penumbra leftpenumbra;
	{
		Point startdir = extendDir(blockerLine[$-1] - (light.position - getLightDisplacement(blockerLine[$-1])));
		leftpenumbra.sections ~= Penumbra.Section(
			blockerLine[$-1], 
			startdir,
			0.0);
		for(size_t i = 0; i < blockerLine.length - 1; ++i)
		{
			real wanted = abs(startdir.angle(getTotalShadowStartDirection(blockerLine[$-i-1])));
			real available = abs(startdir.angle(blockerLine[$-i-2] - blockerLine[$-i-1]));
			
			if(wanted < available)
			{
				leftpenumbra.sections ~= Penumbra.Section(
					blockerLine[$-i-1], 
					getTotalShadowStartDirection(blockerLine[$-i-1]), 
					1.0);
				break;
			}
			else
			{
				leftpenumbra.sections ~= Penumbra.Section(
					blockerLine[$-i-2], 
					extendDir(blockerLine[$-i-2] - blockerLine[$-i-1]),
					available / wanted);
			}
		}
	}
	
	//
	// build umbrae (hard shadows), cast between the insides of penumbrae
	//
					
	Umbra umbra;
						
	umbra.sections ~= Umbra.Section(rightpenumbra.sections[$-1].base, rightpenumbra.sections[$-1].direction);
				
	foreach(ref vert; blockerLine[rightpenumbra.sections.length-1..$-leftpenumbra.sections.length+1])
		umbra.sections ~= Umbra.Section(vert, extendDir(0.5 * (leftpenumbra.sections[$-1].direction + rightpenumbra.sections[$-1].direction)));
	
	umbra.sections ~= Umbra.Section(leftpenumbra.sections[$-1].base, leftpenumbra.sections[$-1].direction);
						
	//
	// draw shadows to alpha
	//
	
	umbra.draw();
	rightpenumbra.draw();
	leftpenumbra.draw();	
}
