﻿/******************************************************************************* 

	Conversion and functions for angles.

	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Christian Kamm (kamm incasoftware de)
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:     ArcLib team 
	
	Description:
	The aliases 'Degrees' and 'Radians' are provided to make it easy
	to see what unit an angle is supposed to be.
	
	Examples:
	--------------------
		void doSomething(Radians angle);
	
		Degrees degRotation = 90;
		Radians radRotation = degreesToRadians(degRotation);
	--------------------

*******************************************************************************/
module arc.math.angle; 

public import tango.math.Math; 

public import arc.types;


/// alias to point out that this stores radians, not degrees
// a typedef causes all kind of annoyances, unfortunately
alias arcfl Radians;

/// alias to notify a reader that this variable stores degrees
alias arcfl Degrees;

/// Twice the value of PI 
const arcfl TWOPI = PI*2; 

/// converts an angle in degrees to radians
Radians degreesToRadians(Degrees deg)
{
	return deg * DEGREE_TO_RADIAN;
}

/// converts an angle in radians to degrees
Degrees radiansToDegrees(Radians rad)
{
	return rad * RADIAN_TO_DEGREE;
}

/// restricts an angle to the 0 - 360 range
Degrees restrictDeg(Degrees deg)
{
	return deg % 360.;
}

/// restricts an angle to the 0 - 2PI range
Radians restrictRad(Radians rad)
{
	return rad % (2*PI);
}

private
{
	/// precalculated PI / 180 Degrees value
	const real DEGREE_TO_RADIAN = PI / 180;
	
	/// precalculated 180 / PI value
	const real RADIAN_TO_DEGREE = 180 / PI;
}