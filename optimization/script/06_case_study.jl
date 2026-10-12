# # Exercise 6 — Case study: 2D heat equation
#
# Run the cells one by one with `Shift+Enter` in Jupyter.
#
# Apply the whole method seen in this session to a small grid code:
#
# 1. **Baseline**: measure + correctness test;
# 2. **Profile**: where is the time spent?
# 3. **Hypothesis**: why there?
# 4. **One** change;
# 5. **Re-measure** + check the result;
# 6. keep or revert, then start again at 2.
#
# After each step, record in the table at the bottom of the notebook the
# time, the number of allocations and the speedup relative to the baseline.
#
# When you are done, call `check()` (at the bottom of the notebook).

using BenchmarkTools, InteractiveUtils, ProfileCanvas, Test

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 2.0;  # each run of the baseline takes ~1 s

## Starting code (do not modify: this is the reference)

n = 256                 # n × n grid on [0, 1]²
dx = 1 / (n - 1)

function initial_condition(n)
    u = zeros(n, n)
    for j in 1:n, i in 1:n
        x, y = (i - 1) / (n - 1), (j - 1) / (n - 1)
        u[i, j] = exp(-100 * ((x - 0.5)^2 + (y - 0.5)^2))
    end
    return u
end

function energy(u)
    s = 0.0
    for i in 2:(size(u, 1)-1)
        for j in 2:(size(u, 2)-1)
            ux = (u[i+1, j] - u[i-1, j]) / (2dx)
            uy = (u[i, j+1] - u[i, j-1]) / (2dx)
            s += ux^2 + uy^2
        end
    end
    return s * dx^2
end

function heat_step(u, dt)
    unew = copy(u)
    for i in 2:(size(u, 1)-1)
        for j in 2:(size(u, 2)-1)
            unew[i, j] = u[i, j] + dt / dx^2 *
                (u[i+1, j] + u[i-1, j] + u[i, j+1] + u[i, j-1] - 4u[i, j])
        end
    end
    return unew
end

function simulate_heat(n, nsteps)
    u = initial_condition(n)
    dt = 0.2 * dx^2
    energies = []
    for _ in 1:nsteps
        u = heat_step(u, dt)
        push!(energies, energy(u))
    end
    return u, energies
end

## Step 0: baseline and diagnosis

simulate_heat(n, 2);  # compilation
#-
@btime simulate_heat($n, 100);

# Tools: `@btime`, `@code_warntype`, `ProfileCanvas.@profview`,
# `ProfileCanvas.@profview_allocs`.
#
# - **Q1.** Where is the time spent?
# - **Q2.** Where do the allocations come from? Is their number consistent
#   with the code?
# - **Q3.** Are the memory accesses contiguous?
# - **Q4.** Is the computation compute-bound or memory-bound?

ProfileCanvas.@profview simulate_heat(n, 100)
#-
@code_warntype energy(initial_condition(n))

## Next steps: your optimizations
#
# Write `simulate_heat_opt(n, nsteps)`, which returns the same result as
# `simulate_heat` (the final field `u` and the vector of energies).
# Tip: keep one version per step (`simulate_heat_1`, `simulate_heat_2`, …)
# so you can fill in the table.
#
# Bonus for those who are done:
# - `@inbounds` removes the bounds checks on array accesses (you then have to
#   guarantee that every index is valid), and `@simd` allows the compiler to
#   reorder the iterations of a loop to use SIMD instructions (see exercise
#   5). Add them to the inner loops: is it valid here?
# - Parallelize the loop over columns with `Threads.@threads for j in …`,
#   which splits the iterations among threads (a preview of the shared-memory
#   parallelism session). Watch out for the reduction in `energy`: several
#   threads must not update the same variable `s`! This needs a Jupyter
#   kernel started with several threads: check `Threads.nthreads()`.

function simulate_heat_opt(n, nsteps)
    return simulate_heat(n, nsteps)  # TODO: write this
end
#-
simulate_heat_opt(n, 2);  # compilation
#-
@btime simulate_heat_opt($n, 100);

## Speedup table (n = 256, 100 steps)
#
# | step        | time (ms) | allocations | speedup |
# |-------------|----------:|------------:|--------:|
# | 0. baseline |           |             |     1.0 |
# | 1.          |           |             |         |
# | 2.          |           |             |         |
# | 3.          |           |             |         |
# | 4.          |           |             |         |
# | 5. (bonus)  |           |             |         |

## What did we learn?
#
# In your own words: which steps brought the largest gains, and why?
# (Double-click to edit this cell.)
#
# - …
# - …
# - …

## Check

function check()
    u_ref, E_ref = simulate_heat(n, 20)
    u_opt, E_opt = simulate_heat_opt(n, 20)
    @testset "Exercise 6" begin
        @test u_opt ≈ u_ref
        @test E_opt ≈ E_ref
        @test eltype(E_opt) == Float64
        @inferred simulate_heat_opt(n, 2)
    end
    t_ref = @belapsed simulate_heat($n, 20)
    t_opt = @belapsed simulate_heat_opt($n, 20)
    println("Speedup: ×", round(t_ref / t_opt; digits=1))
    return nothing
end

# Run the check once you have answered all the questions:

#nb check()
