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
module arc.x.blaze.common.constants;

import arc.x.blaze.common.math;

const COLLISION_TOLLERANCE = 0.1;

/** SPH Constants */
const DENSITY_OFFSET = 100f;
const GAS_CONSTANT = 0.1f;
const VISCOSCITY = 0.002f;
const CELL_SPACE = 15.0f / 64.0f;

/** Global tuning constants based on meters-kilograms-seconds (MKS) units. */

// Collision
const k_maxManifoldPoints = 2;
const k_maxPolygonVertices = 8;
const k_maxProxies = 512;				// this must be a power of two
const k_maxPairs = 8 * k_maxProxies;	// this must be a power of two

// Dynamics

/// A small length used as a collision and constraint tolerance. Usually it is
/// chosen to be numerically significant, but visually insignificant.
const k_linearSlop = 0.005f;	// 0.5 cm

/// A small angle used as a collision and constraint tolerance. Usually it is
/// chosen to be numerically significant, but visually insignificant.
const k_angularSlop = 2.0f / 180.0f * PI;			// 2 degrees

/// Continuous collision detection (CCD) works with core, shrunken shapes. This is the
/// amount by which shapes are automatically shrunk to work with CCD. This must be
/// larger than k_linearSlop.
const k_toiSlop = 8.0f * k_linearSlop;

/// Maximum number of contacts to be handled to solve a TOI island.
const k_maxTOIContactsPerIsland = 32;

/// Maximum number of joints to be handled to solve a TOI island.
const k_maxTOIJointsPerIsland = 32;

/// A velocity threshold for elastic collisions. Any collision with a relative linear
/// velocity below this threshold will be treated as inelastic.
const k_velocityThreshold = 1.0f;		// 1 m/s

/// The maximum linear position correction used when solving constraints. This helps to
/// prevent overshoot.
const k_maxLinearCorrection = 0.2f;	// 20 cm

/// The maximum angular position correction used when solving constraints. This helps to
/// prevent overshoot.
const k_maxAngularCorrection = 8.0f / 180.0f * PI;			// 8 degrees

/// The maximum linear velocity of a body. This limit is very large and is used
/// to prevent numerical problems. You shouldn't need to adjust this.
const k_maxLinearVelocity = 200.0f;
const k_maxLinearVelocitySquared = k_maxLinearVelocity * k_maxLinearVelocity;

/// The maximum angular velocity of a body. This limit is very large and is used
/// to prevent numerical problems. You shouldn't need to adjust this.
const k_maxAngularVelocity = 250.0f;
const k_maxAngularVelocitySquared = k_maxAngularVelocity * k_maxAngularVelocity;

/// This scale factor controls how fast overlap is resolved. Ideally this would be 1 so
/// that overlap is removed in one time step. However using values close to 1 often lead
/// to overshoot.
const k_contactBaumgarte = 0.2f;

// Sleep

/// The time that a body must be still before it will go to sleep.
const k_timeToSleep = 0.5f;									// half a second

/// A body cannot sleep if its linear velocity is above this tolerance.
const k_linearSleepTolerance = 0.01f;		// 1 cm/s

/// A body cannot sleep if its angular velocity is above this tolerance.
const k_angularSleepTolerance = 2.0f / 180.0f;		// 2 degrees/s

/// Version numbering scheme.
/// See http://en.wikipedia.org/wiki/Software_versioning
struct Version
{
	int major;		///< significant changes
	int minor;		///< incremental changes
	int revision;	///< bug fixes
}

/// Current version.
extern Version k_version;

float k_errorTol;

float FORCE_SCALE(float x) { return cast(uint)(x) << 7; }
float FORCE_INV_SCALE(float x) { return cast(uint) (x) >> 7; }

/** Friction mixing law. Feel free to customize this. */
float mixFriction(float friction1, float friction2)
{
	return sqrt(friction1 * friction2);
}

/** Restitution mixing law. Feel free to customize this. */
float mixRestitution(float restitution1, float restitution2)
{
	return restitution1 > restitution2 ? restitution1 : restitution2;
}
