/******************************************************************************* 

    A 2x2 Matrix 

    Authors:       ArcLib team, see AUTHORS file 
    Maintainer:    Christian Kamm (kamm incasoftware de)
    License:       zlib/libpng license: $(LICENSE) 
    Copyright:     ArcLib team 
    
    Description:    
		A 2x2 matrix with standard matrix functionality.

	Examples:
	--------------------
		None provided 
	--------------------

*******************************************************************************/

module arc.math.matrix; 

import
	arc.math.point,
	arc.math.angle,
	arc.math.routines,
	arc.types;
	
import 
	tango.math.Math,
	tango.text.convert.Float : toString;


/// Matrix
struct Matrix 
{
	///
	static Matrix opCall(Point c1, Point c2) 
	{
		Matrix m;
		m.col1 = c1;
		m.col2 = c2;
		return m;
	}

	///Assumed to be a 2x2 rotation matrix 
	static Matrix opCall(float angle) 
	{
		Matrix m;
		float c = cos(angle), s = sin(angle);
		m.col1.x = c;
		m.col2.x = -s;
		m.col1.y = s;
		m.col2.y = c;
		return m;
	}

	/// Construct this matrix using scalars.
	static Matrix opCall(float a11, float a12, float a21, float a22) 
	{
		Matrix u;
		u.col1.x = a11;
		u.col1.y = a21;
		u.col2.x = a12;
		u.col2.y = a22;
		return u;
	}

	///
	void set(Point c1, Point c2) 
	{
		col1 = c1;
		col2 = c2;
	}

	/** Assumed to be a 2x2 rotation matrix */
	void set(float angle) 
	{
		float c = cos(angle), s = sin(angle);
		col1.x = c;
		col2.x = -s;
		col1.y = s;
		col2.y = c;
	}

	///
	void setIdentity() 
	{
		col1.x = 1.0f;
		col2.x = 0.0f;
		col1.y = 0.0f;
		col2.y = 1.0f;
	}

	///
	void zero() 
	{
		col1.x = 0.0f;
		col2.x = 0.0f;
		col1.y = 0.0f;
		col2.y = 0.0f;
	}

	///
	Matrix invert() 
	{
		float a = col1.x, b = col2.x, c = col1.y, d = col2.y;
		Matrix B;
		float det = a * d - b * c;
		assert(det != 0.0f);
		det = 1.0f / det;
		B.col1.x =  det * d;
		B.col2.x = -det * b;
		B.col1.y = -det * c;
		B.col2.y =  det * a;
		return B;
	}

	/// Compute the inverse of this matrix, such that inv(A) * A = identity.
	Matrix inverse() 
	{
		float a = col1.x, b = col2.x, c = col1.y, d = col2.y;
		Matrix B;
		float det = a * d - b * c;
		assert(det != 0.0f);
		det = 1.0f / det;
		B.col1.x =  det * d;
		B.col2.x = -det * b;
		B.col1.y = -det * c;
		B.col2.y =  det * a;
		return B;
	}

	/// Solve A * x = b, where b is a column vector. This is more efficient
	/// than computing the inverse in one-shot cases.
	Point solve(Point b) 
	{
		float a11 = col1.x, a12 = col2.x, a21 = col1.y, a22 = col2.y;
		float det = a11 * a22 - a12 * a21;
		assert(det != 0.0f);
		det = 1.0f / det;
		Point x;
		x.x = det * (a22 * b.x - a12 * b.y);
		x.y = det * (a11 * b.y - a21 * b.x);
		return x;
	}

	///
	Matrix opAdd(Matrix B) 
	{
		Matrix C;
		C.set(col1 + B.col1, col2 + B.col2);
		return C;
	}

	///
	Point col1, col2;
}