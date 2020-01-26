/*
 *  Copyright (c) 2008 Rene Schulte. http://www.rene-schulte.info/
 *  Ported to D by Mason Green. http:/www.dsource.org/projects/blaze
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
module arc.x.blaze.dynamics.fluid.smoothingKernals.SKPoly6;

import arc.x.blaze.common.math;
import arc.x.blaze.dynamics.fluid.smoothingKernals.smoothingKernel;

/// <summary>
/// Implementation of the Poly6 Smoothing-Kernel for SPH-based fluid simulation
/// </summary>
public class SKPoly6 : SmoothingKernel {

    this() {
        super();
    }

    this(float kernelSize) {
        super(kernelSize);
    }

    protected override void calculateFactor() {
        float kernelRad9 = pow(m_kernelSize, 9.0f);
        m_factor = (315.0f / (64.0f * PI * kernelRad9));
    }

    public override float calculate(bVec2 distance) {
        float lenSq = distance.lengthSquared;
        if (lenSq > m_kernelSizeSq) {
            return 0.0f;
        }
        if (lenSq < float.epsilon) {
            lenSq = float.epsilon;
        }

        float diffSq = m_kernelSizeSq - lenSq;
        return m_factor * diffSq * diffSq * diffSq;
    }

    public override bVec2 calculateGradient(bVec2 distance) {
        float lenSq = distance.lengthSquared;
        if (lenSq > m_kernelSizeSq) {
            return bVec2.zeroVect;
        }
        if (lenSq < float.epsilon) {
            lenSq = float.epsilon;
        }
        float diffSq = m_kernelSizeSq - lenSq;
        float f = -m_factor * 6.0f * diffSq * diffSq;
        return bVec2(distance.x * f, distance.y * f);
    }

    public override float calculateLaplacian(bVec2 distance) {
        throw new Exception("Net yet implemented!");
    }
}

