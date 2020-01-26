/*
 *  Copyright (c) 2008 Mason Green http://www.dsource.org/projects/blaze
 *
 *   This software is provided 'as-is', without any express or implied
 *   warranty. In no event will the authors be held liable for any damages
 *   arising from the use of this software.
 *
 *   Permission is granted to anyone to use this software for any purpose,
 *   including commercial applications, and to alter it and redistribute it
 *   freely, subject to the following restrictions:
 *
 *   1. The origin of this software must not be misrepresented; you must not
 *   claim that you wrote the original software. If you use this software
 *   in a product, an acknowledgment in the product documentation would be
 *   appreciated but is not required.
 *
 *   2. Altered source versions must be plainly marked as such, and must not be
 *   misrepresented as being the original software.
 *
 *   3. This notice may not be removed or altered from any source
 *   distribution.
 */
module arc.x.blaze.common.math;

import arc.math.point; 
import arc.math.matrix; 

version(Tango) {
  public import tango.math.Math;
} else {
  public import std.math;
  alias std.math.fmin min;
  alias std.math.fmax max;
  alias std.math.fabs abs;
}

/// makes blaze use ArcLib's point
alias Point bVec2;
alias Matrix bMat22; 

bVec2 bzAbs(bVec2 a) {
    bVec2 b;
    b.set(abs(a.x), abs(a.y));
    return b;
}

bMat22 bzAbs(bMat22 A) {
    bMat22 B;
    B.set(bzAbs(A.col1), bzAbs(A.col2));
    return B;
}

bVec2 bzMin(bVec2 a, bVec2 b) {
    bVec2 c;
    c.x = min(a.x, b.x);
    c.y = min(a.y, b.y);
    return c;
}

bVec2 bzMax(bVec2 a, bVec2 b) {
    bVec2 c;
    c.x = max(a.x, b.x);
    c.y = max(a.y, b.y);
    return c;
}

/// remove element from array
void bKill(T, U) (inout T[] array, U element) {
    size_t index = 0;
    for (; index < array.length; ++index)
        if (array[index] == element)
            break;

    if (index == array.length)
        return;

    for (; index + 1 < array.length; ++index)
        array[index] = array[index + 1];

    array.length = array.length - 1;
    bKill(array, element);
}

/// A transform contains translation and rotation. It is used to represent
/// the position and orientation of rigid frames.
struct bXForm {

    /// Initialize using a position vector and a rotation matrix.
    static bXForm opCall(bVec2 position, bMat22 R) {
        bXForm x;
        x.position = position;
        x.R = R;
        return x;
    }

    /// Set this to the identity transform.
    void setIdentity() {
        position.zero();
        R.setIdentity();
    }

    bVec2 position;
    bMat22 R;
}

/// This describes the motion of a body/shape for TOI computation.
/// Shapes are defined with respect to the body origin, which may
/// no coincide with the center of mass. However, to support dynamics
/// we must interpolate the center of mass position.
struct bSweep {
    /// Get the interpolated transform at a specific time.
    /// @param t the normalized time in [0,1].
    void xForm(inout bXForm xf, float t) {
        // center = p + R * localCenter
        if (1.0f - t0 > float.epsilon) {
            float alpha = (t - t0) / (1.0f - t0);
            xf.position = (1.0f - alpha) * c0 + alpha * c;
            float angle = (1.0f - alpha) * a0 + alpha * a;
            xf.R.set(angle);
        } else {
            xf.position = c;
            xf.R.set(a);
        }

        // Shift to origin
        xf.position -= bMul(xf.R, localCenter);
    }

    /// Advance the sweep forward, yielding a new initial state.
    /// @param t the new initial time.
    void advance(float t) {
        if (t0 < t && 1.0f - t0 > float.epsilon) {
            float alpha = (t - t0) / (1.0f - t0);
            c0 = (1.0f - alpha) * c0 + alpha * c;
            a0 = (1.0f - alpha) * a0 + alpha * a;
            t0 = t;
        }
    }

    bVec2 localCenter;	///< local center of mass position
    bVec2 c0;            ///< center world positions
    bVec2 c;		        ///< center world positions
    float a0 = 0.0f;    ///< world angles
    float a = 0.0f;		///< world angles
    float t0 = 0.0f;	///< time interval = [t0,1], where t0 is in [0,1]
}

///
float bDot(bVec2 a, bVec2 b) {
    return a.x * b.x + a.y * b.y;
}

///
float bCross(bVec2 a, bVec2 b) {
    return a.x * b.y - a.y * b.x;
}

///
bVec2 bCross(bVec2 a, float s) {
    bVec2 v;
    v.set(s * a.y, -s * a.x);
    return v;
}

///
bVec2 bCross(float s, bVec2 a) {
    bVec2 v;
    v.set(-s * a.y, s * a.x);
    return v;
}

///
bVec2 bMul(bMat22 A, bVec2 v) {
    bVec2 u;
    u.set(A.col1.x * v.x + A.col2.x * v.y, A.col1.y * v.x + A.col2.y * v.y);
    return u;
}

///
bVec2 bMulT(bMat22 A, bVec2 v) {
    bVec2 u;
    u.set(bDot(v, A.col1), bDot(v, A.col2));
    return u;
}

bVec2 bMulT(bXForm T, bVec2 v)
{
	return bMulT(T.R, v - T.position);
}

/// A * B
bMat22 bMul(bMat22 A, bMat22 B) {
    bMat22 C;
    C.set(bMul(A, B.col1), bMul(A, B.col2));
    return C;
}

/// Multiply a matrix times a vector.
bVec3 bMul(bMat33 A, bVec3 v) {
    bVec3 u = (v.x * A.col1) + (v.y * A.col2) + (v.z * A.col3);
    return u;
}

bVec2 bMul(bXForm T, bVec2 v) {
    return (T.position + bMul(T.R, v));
}

/// A^T * B
bMat22 bMulT(bMat22 A, bMat22 B) {
    bVec2 c1;
    c1.set(bDot(A.col1, B.col1), bDot(A.col2, B.col1));
    bVec2 c2;
    c2.set(bDot(A.col1, B.col2), bDot(A.col2, B.col2));
    bMat22 C;
    C.set(c1, c2);
    return C;
}

/// Perform the bDot product on two vectors.
float bDot(bVec3 a, bVec3 b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

/// Perform the cross product on two vectors.
bVec3 bCross(bVec3 a, bVec3 b) {
    return bVec3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x);
}

float bClamp (float a, float low, float high) {
    return max(low, min(a, high));
}

bVec2 bClamp(bVec2 a, bVec2 low, bVec2 high) {
    return bzMax(low, bzMin(a, high));
}

///
void bSwap(T)(inout T a, inout T b) {
    T tmp = a;
    a = b;
    b = tmp;
}

struct bTri2 {
    bVec2 a;
    bVec2 b;
    bVec2 c;
    bVec2 cm;

    float area;

    static bTri2 opCal(bVec2 a, bVec2 b, bVec2 c) {
        bTri2 u;
        u.a = a;
        u.b = b;
        u.c = c;
        u.area = ((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)) / 2;
        u.cm = bVec2((a.x + b.x + c.x) / 3, (a.y + b.y + c.y) / 3);
        return u;
    }
}

/// A 2D column vector with 3 elements.
struct bVec3 {
    float x, y, z = 0;

    /// Construct using coordinates.
    static bVec3 opCall(float x, float y, float z) {
        bVec3 u;
        u.x = x;
        u.y = y;
        u.z = z;
        return u;
    }

    /// Set this vector to all zeros.
    void zero() {
        x = 0.0f;
        y = 0.0f;
        z = 0.0f;
    }

    /// Set this vector to some specified coordinates.
    void set(float x_, float y_, float z_) {
        x = x_;
        y = y_;
        z = z_;
    }

    /// Negate this vector.
    bVec3 opNeg() {
        return bVec3(-x,-y,-z);
    }

    /// Add a vector to this vector.
    void opAddAssign (bVec3 v) {
        x += v.x;
        y += v.y;
        z += v.z;
    }

    /// Subtract a vector from this vector.
    void opSubAssign (bVec3 v) {
        x -= v.x;
        y -= v.y;
        z -= v.z;
    }

    /// Multiply this vector by a scalar.
    void opMulAssign (float s) {
        x *= s;
        y *= s;
        z *= s;
    }

    bVec3 opMul(float s) {
        return bVec3(s * x, s * y, s * z);
    }

    /// Add two vectors component-wise.
    bVec3 opAdd(bVec3 b) {
        return bVec3(x + b.x, y + b.y, z + b.z);
    }

    /// Subtract two vectors component-wise.
    bVec3 opSub(bVec3 v) {
        return bVec3(x - v.x, y - v.y, z - v.z);
    }

}

/// A 3-by-3 matrix. Stored in column-major order.
struct bMat33 {
    bVec3 col1, col2, col3;

    /// Construct matrix using columns.
    static bMat33 opCall( bVec3 c1, bVec3 c2, bVec3 c3) {
        bMat33 u;
        u.col1 = c1;
        u.col2 = c2;
        u.col3 = c3;
        return u;
    }

    /// Set this matrix to all zeros.
    void zero() {
        col1.zero();
        col2.zero();
        col3.zero();
    }

    /// Solve A * x = b, where b is a column vector. This is more efficient
    /// than computing the inverse in one-shot cases.
    bVec3 solve33(bVec3 b) {
        float det = bDot(col1, bCross(col2, col3));
        assert(det != 0.0f);
        det = 1.0f / det;
        bVec3 x;
        x.x = det * bDot(b, bCross(col2, col3));
        x.y = det * bDot(col1, bCross(b, col3));
        x.z = det * bDot(col1, bCross(col2, b));
        return x;
    }

    /// Solve A * x = b, where b is a column vector. This is more efficient
    /// than computing the inverse in one-shot cases.
    bVec2 solve22(bVec2 b) {
        float a11 = col1.x, a12 = col2.x, a21 = col1.y, a22 = col2.y;
        float det = a11 * a22 - a12 * a21;
        assert(det != 0.0f);
        det = 1.0f / det;
        bVec2 x;
        x.x = det * (a22 * b.x - a12 * b.y);
        x.y = det * (a11 * b.y - a21 * b.x);
        return x;
    }
}

struct bJacobian {

    bVec2 linear1;
    float angular1;
    bVec2 linear2;
    float angular2;

    void zero() {
        linear1.zero();
        angular1 = 0.0f;
        linear2.zero();
        angular2 = 0.0f;
    }

    void set(bVec2 x1, float a1, bVec2 x2, float a2) {
        linear1 = x1;
        angular1 = a1;
        linear2 = x2;
        angular2 = a2;
    }

    float compute(bVec2 x1, float a1, bVec2 x2, float a2) {
        return bDot(linear1, x1) + angular1 * a1 + bDot(linear2, x2) + angular2 * a2;
    }

}
