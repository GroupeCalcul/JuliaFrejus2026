# # Exercise 4 — Profiling
#
# Run the cells one by one with `Shift+Enter` in Jupyter.
#
# A **sampling profiler** records the call stack every ~1 ms; the functions
# present in many samples are the hot spots. Two precautions:
# - **run the code once beforehand**, otherwise you profile the compilation;
# - make the computation last long enough (≥ 1 s) to collect enough samples.
#
# A small simulation of interacting particles in the plane. The code is
# deliberately written "naively" and contains several performance problems.
# The goal is to *find them with the profiler*, not by reading the code line
# by line!
#
# When you are done, call `check()` (at the bottom of the notebook).

using BenchmarkTools, LinearAlgebra, Profile, ProfileCanvas, Random, StaticArrays, Test

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 1.0;  # shorter benchmarks for the session

## Starting code (do not modify: this is the reference)

softening = 0.05

function initialize(n; seed=1234)
    rng = Xoshiro(seed)
    pos = [rand(rng, 2) for _ in 1:n]
    vel = [zeros(2) for _ in 1:n]
    return pos, vel
end

function forces(pos)
    n = length(pos)
    F = [zeros(2) for _ in 1:n]
    for i in 1:n
        for j in 1:n
            i == j && continue
            d = pos[j] - pos[i]
            r2 = dot(d, d) + softening^2
            F[i] += d / r2^(3 / 2)
        end
    end
    return F
end

function advance!(pos, vel, F, dt)
    for i in eachindex(pos)
        vel[i] += dt * F[i]
        pos[i] += dt * vel[i]
    end
    return nothing
end

function median_distance(pos)
    d = Float64[]
    for i in eachindex(pos), j in (i+1):lastindex(pos)
        push!(d, norm(pos[i] - pos[j]))
    end
    sort!(d)
    return d[length(d)÷2+1]
end

function simulate(n, nsteps; dt=1e-4, every=10)
    pos, vel = initialize(n)
    diagnostics = Float64[]
    for step in 1:nsteps
        F = forces(pos)
        advance!(pos, vel, F, dt)
        dmed = median_distance(pos)
        if step % every == 0
            push!(diagnostics, dmed)
        end
    end
    return pos, diagnostics
end

## Q1. Baseline measurement

simulate(50, 10);  # compilation: always run once before measuring or profiling
#-
@time simulate(400, 50);

## Q2. Profile
#
# The flame graph (ProfileCanvas) is displayed below the cell:

ProfileCanvas.@profview simulate(400, 50)

# Reading the flame graph:
# - vertical axis: the call stack (caller on top, callee below);
# - **width** of a bar = fraction of time spent in the function (and its callees);
# - red = dynamic dispatch (type instability); yellow = GC;
# - hover a bar to see the file and line; click to zoom.
#
# The same for allocations:

ProfileCanvas.@profview_allocs simulate(400, 50)

# Without a graphical display (e.g. on the cluster), use the text output, or
# save the flame graph as HTML (`ProfileCanvas.html_file("profile.html")`)
# and open it locally:

Profile.clear()
@profile simulate(400, 50)
Profile.print(format=:flat, sortedby=:count, mincount=50)

# - **Q2a.** Which function dominates? Which lines of that function?
# - **Q2b.** What are `Array`, `similar`, `copy` doing in the profile? Confirm
#   with the allocation profile.
# - **Q2c.** Are there red bars? Why?
# - **Q2d.** What is `pow_body` doing in the profile?

## Q3. Optimize
#
# Write `simulate_opt(n, nsteps; dt=1e-4, every=10)`, which returns the same
# results as `simulate` (final positions and diagnostics), fixing one problem
# at a time. **Profile again after each fix**: the hot spot moves!
#
# Hints:
# - `SVector{2,Float64}` (StaticArrays) for positions, velocities and forces;
#   `advance!` then does not need to change;
# - a constant, or an argument, instead of the global `softening`;
# - `r2^(3/2) == r2 * sqrt(r2)`;
# - the force of j on i is the opposite of the force of i on j;
# - when is the diagnostic actually used? `partialsort!`;
# - preallocate work arrays once, outside the loop.

function simulate_opt(n, nsteps; dt=1e-4, every=10)
    return simulate(n, nsteps; dt, every)  # TODO: write this
end
#-
simulate_opt(50, 10);
#-
@time simulate_opt(400, 50);
#-
ProfileCanvas.@profview simulate_opt(1000, 200)

## What did we learn?
#
# In your own words: how do you use the profiler to find what to optimize?
# (Double-click to edit this cell.)
#
# - …
# - …
# - …

## Check

function check()
    pos_ref, diag_ref = simulate(60, 30)
    pos_opt, diag_opt = simulate_opt(60, 30)
    @testset "Exercise 4" begin
        @test all(pos_opt .≈ pos_ref)
        @test diag_opt ≈ diag_ref
        @test eltype(diag_opt) == Float64
    end
    t_ref = @belapsed simulate(200, 20)
    t_opt = @belapsed simulate_opt(200, 20)
    println("Speedup: ×", round(t_ref / t_opt; digits=1))
    return nothing
end

# Run the check once you have answered all the questions:

#nb check()
