module arc.math.matrix3;

import
	arc.math.point,
	arc.math.angle,
	arc.math.routines,
	arc.types;

import 
	tango.math.Math,
	tango.text.convert.Float : toString;

/// 3x3 Matrix3 for SVG
struct Matrix3
{
	///
	void setTranslate(float tx, float ty)
	{
		c11 = 1; 
		c12 = 0;
		c13 = 0; 
		
		c21 = 0;
		c22 = 1; 
		c23 = 0; 
		
		c31 = tx; 
		c32 = ty; 
		c33 = 1; 
	}
	
	///
	void setScale(float sx, float sy)
	{
		c11 = sx; 
		c12 = 0;
		c13 = 0; 
		
		c21 = 0;
		c22 = sy; 
		c23 = 0; 
		
		c31 = 0; 
		c32 = 0; 
		c33 = 1; 
	}
	
	///
	void setSkewX(float a)
	{
		c11 = 1; 
		c12 = 0;
		c13 = 0; 
		
		c21 = tan(a);
		c22 = 1; 
		c23 = 0; 
		
		c31 = 0; 
		c32 = 0; 
		c33 = 1; 
	}
	
	///
	void setSkewY(float a)
	{
		c11 = 1; 
		c12 = tan(a);
		c13 = 0; 
		
		c21 = 0;
		c22 = 1; 
		c23 = 0; 
		
		c31 = 0; 
		c32 = 0; 
		c33 = 1; 
	}
	
	///
	float c11, c12, c13; 
	float c21, c22, c23; 
	float c31, c32, c33; 
}