# # Exercise 6 — Case study: 2D heat equation (solution)
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

using BenchmarkTools, InteractiveUtils, Printf, ProfileCanvas, Test

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

# **Answer.**
# - **Q1.** The profile: `energy` ~65% and `heat_step` ~35% of the samples,
#   with lots of red (dynamic dispatch) and GC.
# - **Q2.** ~10^8 allocations for 100 steps. A single `copy` per step cannot
#   explain this: it is a symptom of type instability. `@code_warntype`
#   shows that `dx` is `Any` (non-constant global), and so are `ux`, `uy` and
#   `s`. Also, `energies = []` is a `Vector{Any}`.
# - **Q3.** No: the inner loops run over `j`, the *second* index.
# - **Q4.** A 5-point stencil: ~7 flops per grid point, for 16 bytes (one
#   read, one write; the neighbors are already in cache), i.e. ~0.4
#   flop/byte: memory-bound for large grids, like the matrix-vector product.
#   Here the grid (512 KiB) fits in the L2 cache, so SIMD still helps.

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

## Step 1: type stability
#
# `dx` passed as an argument (it could also be recomputed from `size(u)`)
# and a typed vector of energies.

function energy_1(u, dx)
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

function heat_step_1(u, dt, dx)
    unew = copy(u)
    for i in 2:(size(u, 1)-1)
        for j in 2:(size(u, 2)-1)
            unew[i, j] = u[i, j] + dt / dx^2 *
                (u[i+1, j] + u[i-1, j] + u[i, j+1] + u[i, j-1] - 4u[i, j])
        end
    end
    return unew
end

function simulate_heat_1(n, nsteps)
    dx = 1 / (n - 1)
    u = initial_condition(n)
    dt = 0.2 * dx^2
    energies = Float64[]
    for _ in 1:nsteps
        u = heat_step_1(u, dt, dx)
        push!(energies, energy_1(u, dx))
    end
    return u, energies
end

## Step 2: allocations
#
# Two arrays allocated once, then swapped at each step ("double buffering").
# The boundaries never change (Dirichlet conditions): copying them once is
# enough.

function heat_step_2!(unew, u, dt, dx)
    for i in 2:(size(u, 1)-1)
        for j in 2:(size(u, 2)-1)
            unew[i, j] = u[i, j] + dt / dx^2 *
                (u[i+1, j] + u[i-1, j] + u[i, j+1] + u[i, j-1] - 4u[i, j])
        end
    end
    return unew
end

function simulate_heat_2(n, nsteps)
    dx = 1 / (n - 1)
    u = initial_condition(n)
    unew = copy(u)
    dt = 0.2 * dx^2
    energies = Vector{Float64}(undef, nsteps)
    for k in 1:nsteps
        heat_step_2!(unew, u, dt, dx)
        u, unew = unew, u
        energies[k] = energy_1(u, dx)
    end
    return u, energies
end

## Step 3: loop order (column-major)
#
# Inner loop over the first index `i`. We also hoist the constants out of the
# loop (`dt / dx^2`, `1 / (2dx)`); the compiler often does it on its own,
# but it is more readable.

function energy_3(u, dx)
    s = 0.0
    c = 1 / (2dx)
    for j in 2:(size(u, 2)-1)
        for i in 2:(size(u, 1)-1)
            ux = (u[i+1, j] - u[i-1, j]) * c
            uy = (u[i, j+1] - u[i, j-1]) * c
            s += ux^2 + uy^2
        end
    end
    return s * dx^2
end

function heat_step_3!(unew, u, dt, dx)
    r = dt / dx^2
    for j in 2:(size(u, 2)-1)
        for i in 2:(size(u, 1)-1)
            unew[i, j] = u[i, j] + r *
                (u[i+1, j] + u[i-1, j] + u[i, j+1] + u[i, j-1] - 4u[i, j])
        end
    end
    return unew
end

function simulate_heat_3(n, nsteps)
    dx = 1 / (n - 1)
    u = initial_condition(n)
    unew = copy(u)
    dt = 0.2 * dx^2
    energies = Vector{Float64}(undef, nsteps)
    for k in 1:nsteps
        heat_step_3!(unew, u, dt, dx)
        u, unew = unew, u
        energies[k] = energy_3(u, dx)
    end
    return u, energies
end

## Step 4 (bonus): `@inbounds` and `@simd`
#
# `@inbounds` removes the bounds checks: valid here, since the loop bounds
# guarantee that every access is inside the array. `@simd` allows the
# compiler to reorder the iterations to use SIMD instructions; for the sum in
# `energy`, the result may change in the last digits (see exercise 1, Q5).

function energy_4(u, dx)
    s = 0.0
    c = 1 / (2dx)
    @inbounds for j in 2:(size(u, 2)-1)
        @simd for i in 2:(size(u, 1)-1)
            ux = (u[i+1, j] - u[i-1, j]) * c
            uy = (u[i, j+1] - u[i, j-1]) * c
            s += ux^2 + uy^2
        end
    end
    return s * dx^2
end

function heat_step_4!(unew, u, dt, dx)
    r = dt / dx^2
    @inbounds for j in 2:(size(u, 2)-1)
        @simd for i in 2:(size(u, 1)-1)
            unew[i, j] = u[i, j] + r *
                (u[i+1, j] + u[i-1, j] + u[i, j+1] + u[i, j-1] - 4u[i, j])
        end
    end
    return unew
end

function simulate_heat_4(n, nsteps)
    dx = 1 / (n - 1)
    u = initial_condition(n)
    unew = copy(u)
    dt = 0.2 * dx^2
    energies = Vector{Float64}(undef, nsteps)
    for k in 1:nsteps
        heat_step_4!(unew, u, dt, dx)
        u, unew = unew, u
        energies[k] = energy_4(u, dx)
    end
    return u, energies
end

## Step 5 (bonus): multithreading
#
# A preview of the shared-memory parallelism session. This needs a Jupyter
# kernel started with several threads: check `Threads.nthreads()`. Each
# column `j` is independent: columns are split among the threads. The energy is a reduction: one partial
# sum per chunk of columns, with no shared variable (no data race).
#
# On a 256 × 256 grid (512 KiB, which fits in the L2 cache), the gain is
# small: each thread has too little work per time step compared to the cost
# of launching the tasks (granularity). Try with `n = 1024`.

function energy_5(u, dx)
    c = 1 / (2dx)
    columns = 2:(size(u, 2)-1)
    chunks = Iterators.partition(columns, cld(length(columns), Threads.nthreads()))
    tasks = map(chunks) do js
        Threads.@spawn begin
            s = 0.0
            @inbounds for j in js
                @simd for i in 2:(size(u, 1)-1)
                    ux = (u[i+1, j] - u[i-1, j]) * c
                    uy = (u[i, j+1] - u[i, j-1]) * c
                    s += ux^2 + uy^2
                end
            end
            s
        end
    end
    return sum(fetch, tasks) * dx^2
end

function heat_step_5!(unew, u, dt, dx)
    r = dt / dx^2
    Threads.@threads for j in 2:(size(u, 2)-1)
        @inbounds @simd for i in 2:(size(u, 1)-1)
            unew[i, j] = u[i, j] + r *
                (u[i+1, j] + u[i-1, j] + u[i, j+1] + u[i, j-1] - 4u[i, j])
        end
    end
    return unew
end

function simulate_heat_5(n, nsteps)
    dx = 1 / (n - 1)
    u = initial_condition(n)
    unew = copy(u)
    dt = 0.2 * dx^2
    energies = Vector{Float64}(undef, nsteps)
    for k in 1:nsteps
        heat_step_5!(unew, u, dt, dx)
        u, unew = unew, u
        energies[k] = energy_5(u, dx)
    end
    return u, energies
end

## Optimized version
#
# We keep step 4: step 5 needs several threads.

simulate_heat_opt(n, nsteps) = simulate_heat_4(n, nsteps)
#-
simulate_heat_opt(n, 2);  # compilation
#-
@btime simulate_heat_opt($n, 100);

## Speedup table (n = 256, 100 steps)
#

function speedup_table(n, nsteps)
    stages = [
        "0. baseline" => simulate_heat,
        "1. type stability" => simulate_heat_1,
        "2. allocations" => simulate_heat_2,
        "3. loop order" => simulate_heat_3,
        "4. @inbounds @simd" => simulate_heat_4,
        "5. threads (×$(Threads.nthreads()))" => simulate_heat_5,
    ]
    t_ref = 0.0
    println("step                       time (ms)   allocations       speedup")
    for (name, f) in stages
        f(n, 2)  # compilation
        b = @benchmark $f($n, $nsteps)
        t = minimum(b).time / 1e6
        name == "0. baseline" && (t_ref = t)
        @printf("%-26s %9.2f %13d %13.1f\n", name, t, b.allocs, t_ref / t)
    end
end

speedup_table(n, 100)

# Results (Intel Core Ultra 7 165H, n = 256, 100 steps, 4 threads):
#
# | step                 | time (ms) | allocations | speedup |
# |----------------------|----------:|------------:|--------:|
# | 0. baseline          |   1236.21 |   109677710 |     1.0 |
# | 1. type stability    |     25.79 |         308 |    47.9 |
# | 2. allocations       |     22.29 |           8 |    55.5 |
# | 3. loop order        |     11.43 |           8 |   108.1 |
# | 4. `@inbounds @simd` |      4.76 |           8 |   259.9 |
# | 5. threads (×4)      |      3.57 |        5308 |   346.4 |

## What did we learn?
#
# - The baseline and the profile point at type instability first: fixing it
#   gives most of the gain (~×48).
# - Then allocations (double buffering, ~×56), then loop order (column-major,
#   ~×108).
# - `@inbounds @simd`: ~×260, but only once the code is clean.
# - Threads bring little on a small grid: each thread has too little work.
# - One change at a time, and check the result after each one.

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
