/******************************************************************************* 

	A 2d Point Structure 

	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Christian Kamm (kamm incasoftware de) 
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:     ArcLib team 

    Description:    
		A 2d Point Structure, holding math pertaining to 2D points. 

	Examples:
	--------------------
	import arc.math.point;

	int main() 
	{
		Point vec = Point(x, y);

		return 0;
	}
	--------------------

*******************************************************************************/

module arc.math.point; 

import tango.util.log.Log;
import tango.text.convert.Float;
import tango.math.Math : abs;

import derelict.opengl.gl;

import 
	arc.math.routines,
	arc.math.angle,
	arc.math.size,
	arc.math.matrix,
	arc.math.size, 
	arc.types;

/***
  A point structure
 
  Generally, methods perform actions in-place if possible.
  If the method ends in Copy it's a convenience wrapper for 
  copying the vector and then applying the method.
 
  Freely uses inout arguments for speed reasons.
*/
struct Point
{

	/** X axis coordinate */
	arcfl x = 0.0f;
	/** Y Axis coordinate */
	arcfl y = 0.0f;

	/// get x coord
	final arcfl getX() { return x; }

	/// get y cord
	final arcfl getY() { return y; }

	/// set x coord
	final void setX(arcfl ex) { x = ex; }

	/// set y coord
	final void setY(arcfl why) { y = why; }

	/** Return a zero vector */
	static const Point zeroVect = { 0, 0 };
	static const Point Zero = { 0, 0 };

	/** Constructor */
	static Point opCall(arcfl ax, arcfl ay) 
	{
		Point u;
		u.x = ax;
		u.y = ay;
		return u;
	}

	/// rotate
	Point rotateCopy(Radians angle)
	{
		return Point(x*cos(angle)-y*sin(angle),
							x*sin(angle)+y*cos(angle));
	}

	/// rotate around pivot point
	Point rotateCopy(Point center, Radians angle)
	{
		Point v = Point(x,y) + center;
		v.rotate(angle);
		return v;
	}   

	///
	static Point makePerpTo(inout Point p)
	{
		Point v;
		v.y = p.x;
		v.x = - p.y;
		return v;
	}

	/*** unfortunately, making this an opCall makes Point(1,1) ambigious...
	Point 'constructor' from polar coordinates
	*/
	static Point fromPolar(arcfl length, Radians angle)
	{
		Point v;
		v.x = length * cos(angle);
		v.y = length * sin(angle);
		return v;
	}


	/// scaling product
	Point scale(arcfl by) { *this *= by; return *this; }
	Point scale(inout Point by) { x *= by.x; y *= by.y; return *this; }

	/** Return a copy of the vector */
	Point clone() {
		return Point(x, y);
	}

	/** Set the vector */
	void set(arcfl px, arcfl py) {
		x = px;
		y = py;
	}

	/** Set the vector */
	void zero() {
		x = 0.0f;
		y = 0.0f;
	}

	/** Vector bDot product */
	arcfl dot(Point v) {
		return x * v.x + y * v.y;
	}

	/** Vector bCross product */
	arcfl cross(Point v) {
		return x * v.y - y * v.x;
	}

	/** Scalar cross product */
	Point cross(arcfl s) {
		return Point(-s * y, s * x);
	}


	/** Vector bDot product */
	arcfl bDot(Point v) {
		return x * v.x + y * v.y;
	}

	/** Vector bCross product */
	arcfl bCross(Point v) {
		return x * v.y - y * v.x;
	}

	/** Scalar cross product */
	Point bCross(arcfl s) {
		return Point(-s * y, s * x);
	}

	Point opAdd(Size size) 
	{
		return Point(x + size.w, y + size.h); 
	}

	// subtract size from point, return point
	Point opSub(Size size) 
	{
		return Point(x - size.w, y - size.h); 
	}

	/** Scalar addition */
	Point opAdd(arcfl V) 
	{
		return Point(x + V, y + V);
	}

	/** Scalar subtraction */
	Point opSub(arcfl n) 
	{
		return Point(x - n, y - n);
	}

	/** Scalar addition */
	Point opAddAssign(arcfl V) 
	{
		x += V;
		y += V;
		return *this;
	}

	/** Scalar subtraction */
	Point opSubAssign(arcfl V) 
	{
		x -= V;
		y -= V;
		return *this;
	}

	/** Scalar multiplication */
	Point opMulAssign(arcfl s) 
	{
		x *= s;
		y *= s;
		return *this;
	}

	/** Scalar multiplication */
	Point opMul(arcfl s) 
	{
		return Point(x * s, y * s);
	}

	/** 2x2 matrix multiplication */
	Point opMul(Matrix a) 
	{
		return Point(a.col1.x * x + a.col2.x * y, a.col1.y * x + a.col2.y * y);
	}

	/** Scalar division */
	Point opDivAssign(arcfl s) 
	{
		x /= s;
		y /= s;
		return *this;
	}

	/** Scalar division */
	Point opDiv(arcfl s) 
	{
		return Point(x / s, y / s);
	}

	/** Vector addition */
	Point opAddAssign(Point Other) 
	{
		x += Other.x;
		y += Other.y;
		return *this;
	}

	///
	Point opAdd(Point V) 
	{
		return Point(x + V.x, y + V.y);
	}

	///
	Point opSubAssign(Point Other) 
	{
		x -= Other.x;
		y -= Other.y;
		return *this;
	}

	///
	Point opSub(Point V) 
	{
		return Point(x - V.x, y - V.y);
	}

	/// negation
	Point opNeg() 
	{
		return Point(-x, -y);
	}

	///
	arcfl magnitude() 
	{
		arcfl mag = sqrt(x * x + y * y);
		if (!(mag <>= 0)) mag = arcfl.epsilon;
		return mag;
	}

	/// Get the length squared. For performance, use this instead of
	/// Point.length (if possible).
	arcfl lengthSquared() 
	{
		return x * x + y * y;
	}

	/// Get the length of this vector (the norm).
	arcfl length() 
	{
		return sqrt(x * x + y * y);
	}

	/// Convert this vector into a unit vector. Returns the length.
	arcfl normalize()
	{
		arcfl length = length();
		if (length < arcfl.epsilon)
		{
			return 0.0f;
		}
		arcfl invLength = 1.0f / length;
		x *= invLength;
		y *= invLength;

		return length;
	}

	///
	Point normalizeCopy()
	{
		Point p = *this;
		p.normalize(); 
		return p; 
	}

	///
	arcfl distance(Point v) 
	{
		Point delta = Point(x, y) - v;
		return delta.magnitude();
	}

	///
	Point perp() 
	{
		return Point(-y, x);
	}

	///
	Point clampMax(arcfl max) 
	{
		arcfl l = magnitude();

		if (l > max)
			*this *= (max / l);
		return Point(x, y);
	}

	///
	Point interpEquals(arcfl blend, Point v) 
	{
		x += blend * (v.x - x);
		y += blend * (v.y - y);
		return Point(x, y);
	}

	///
	Point projectOnto(Point v) 
	{
		arcfl dp = Point(x, y).bDot(v);
		arcfl f = dp / (v.x * v.x + v.y * v.y);

		return Point(f * v.x, f * v.y);
	}

	///
	arcfl angle(Point v) 
	{
		return atan2(Point(x, y).bCross(v), Point(x, y).bDot(v));
	}

	///
	static Point forAngle(arcfl a) 
	{
		return Point(cos(a), sin(a));
	}

	///
	void forAngleEquals(arcfl a) 
	{
		this.x = cos(a);
		this.y = sin(a);
	}

	Point rotate(Point v) 
	{
		return Point(x * v.x - y * v.y, x * v.y + y * v.x);
	}

	///
	Point rotate(arcfl angle) 
	{
		arcfl cos = cos(angle);
		arcfl sin = sin(angle);

		return Point((cos * x) - (sin * y), (cos * y) + (sin * x));
	}

	///
	Point rotateAbout(arcfl angle, Point point) 
	{
		Point d = (Point(x, y) - point).rotate(angle);

		x = point.x + d.x;
		y = point.y + d.y;
		return Point(x, y);
	}

	///
	Point rotateEquals(arcfl angle) 
	{
		arcfl cos = cos(angle);
		arcfl sin = sin(angle);
		arcfl rx = (cos * x) - (sin * y);
		arcfl ry = (cos * y) + (sin * x);

		x = rx;
		y = ry;
		return Point(x, y);
	}

	///
	Point[] createVectorArray(int len) 
	{
		Point[] vectorArray;
		vectorArray.length = len;
		return vectorArray;
	}

	///
	bool equalsZero() 
	{
		return x == 0 && y == 0;
	}

	Point rotateLeft90() 
	{
		return Point(-y, x);
	}

	Point rotateRight90() 
	{
		return Point(y, -x);
	}
    
}

