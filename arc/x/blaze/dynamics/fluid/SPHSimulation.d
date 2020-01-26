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
module arc.x.blaze.dynamics.fluid.SPHSimulation;

import arc.x.blaze.common.math;
import arc.x.blaze.common.constants;
import arc.x.blaze.world;
import arc.x.blaze.collision.shapes.fluidParticle;
import arc.x.blaze.dynamics.fluid.smoothingKernals.smoothingKernel;
import arc.x.blaze.dynamics.fluid.smoothingKernals.SKPoly6;
import arc.x.blaze.dynamics.fluid.smoothingKernals.SKSpiky;
import arc.x.blaze.dynamics.fluid.smoothingKernals.SKViscosity;

/// <summary>
/// Implementation of a SPH-based fluid simulation
/// </summary>
public class SPHSimulation {

    public float cellSpace;
    public SmoothingKernel SKGeneral;
    public SmoothingKernel SKPressure;
    public SmoothingKernel SKViscos;
    public float Viscosity;

    private FluidParticle[] m_particles;

    this() {
        cellSpace = CELL_SPACE;
        Viscosity = VISCOSCITY;
        SKGeneral = new SKPoly6(cellSpace);
        SKPressure = new SKSpiky(cellSpace);
        SKViscos = new SKViscosity(cellSpace);
    }

    /** Add particle to simulation */
    void addParticle(FluidParticle particle) {
        particle.ID = m_particles.length;
        m_particles ~= particle;
    }

    /** Remove particle from simulation */
    void removeParticle(FluidParticle particle) {
        bKill(m_particles, particle);
    }

    /** Return float of particles */
    int numParticles() {
        return m_particles.length;
    }

    /** Return particle list */
    FluidParticle[] particles() {
        return m_particles;
    }

    /** Reset force */
    void resetForce() {
        foreach(p; m_particles) {
            p.force = bVec2.zeroVect;
        }
    }

    /// <summary>
    /// Simulates the specified particles.
    /// </summary>
    /// <param name="particles">The particles.</param>
    /// <param name="gravity">The gravity.</param>
    /// <param name="dTime">The time step.</param>
    void update(bVec2 gravity, TimeStep step) {
        foreach (inout particle; m_particles) {
            particle.neighbors ~= particle.ID;
        }
        calculatePressureAndDensities();
        calculateForces();
        updateParticles(step, gravity);
        checkParticleDistance();
        foreach (inout particle; m_particles) {
            // Clear neighbor list
            particle.neighbors = null;
            particle.updateAABB();
        }
    }

    /// <summary>
    /// Calculates the pressure and densities.
    /// </summary>
    /// <param name="particles">The particles.</param>
    /// <param name="grid">The grid.</param>
    private void calculatePressureAndDensities() {
        bVec2 dist;
        foreach (inout particle; m_particles) {
            particle.density = 0.0f;
            foreach (nIdx; particle.neighbors) {
                dist = particle.position - m_particles[nIdx].position;
                particle.density += (particle.mass * SKGeneral.calculate(dist));
            }
            particle.updatePressure();
        }
    }

    /// <summary>
    /// Calculates the pressure and viscosity forces.
    /// </summary>
    /// <param name="particles">The particles.</param>
    /// <param name="grid">The grid.</param>
    /// <param name="gravity">The gravity.</param>
    private void calculateForces() {
        bVec2 dist, force;
        float scalar;
        for (int i = 0; i < m_particles.length; i++) {
            foreach (nIdx; m_particles[i].neighbors) {
                // Prevent double tests
                if (nIdx < i) {
                    if (m_particles[nIdx].density > float.epsilon) {
                        dist = m_particles[i].position - m_particles[nIdx].position;
                        // pressure
                        scalar = m_particles[nIdx].mass * (m_particles[i].pressure
                                                         + m_particles[nIdx].pressure) / (2.0f * m_particles[nIdx].density);
                        force = SKPressure.calculateGradient(dist);
                        force *= scalar;
                        m_particles[i].force -= force;
                        m_particles[nIdx].force += force;

                        // viscosity
                        scalar = m_particles[nIdx].mass * SKViscos. calculateLaplacian(dist)
                                 * Viscosity * 1 / m_particles[nIdx].density;
                        force = m_particles[nIdx].velocity - m_particles[i].velocity;
                        force *= scalar;
                        m_particles[i].force += force;
                        m_particles[nIdx].force -= force;
                    }
                }
            }
        }
    }

    /// <summary>
    /// Updates the particles posotions using integration and clips them to the domain space.
    /// </summary>
    /// <param name="particles">The particles.</param>
    /// <param name="dTime">The time step.</param>
    private void updateParticles(TimeStep step, bVec2 gravity) {
        foreach (particle; m_particles) {
            // Update velocity + position using forces
            particle.update(step, gravity);
        }
    }

    /// <summary>
    /// Checks the distance between the particles and corrects it, if they are to near.
    /// </summary>
    /// <param name="particles">The particles.</param>
    /// <param name="grid">The grid.</param>
    private void checkParticleDistance() {
        float minDist = 0.5f * cellSpace;
        float minDistSq = minDist * minDist;
        for (int i = 0; i < m_particles.length; i++) {
            foreach (nIdx; m_particles[i].neighbors) {
                bVec2 dist = m_particles[nIdx].position - m_particles[i].position;
                float distLenSq = dist.lengthSquared;
                if (distLenSq < minDistSq) {
                    if (distLenSq > float.epsilon) {
                        float distLen = sqrt(distLenSq);
                        dist *= (0.5f * (distLen - minDist) / distLen);
                        m_particles[nIdx].position -= dist;
                        m_particles[nIdx].positionOld -= dist;
                        m_particles[i].position += dist;
                        m_particles[i].positionOld += dist;
                    } else {
                        float diff = 0.5f * minDist;
                        m_particles[nIdx].position.y -= diff;
                        m_particles[nIdx].positionOld.y -= diff;
                        m_particles[i].position.y += diff;
                        m_particles[i].positionOld.y += diff;
                    }
                }
            }
        }
    }
}
