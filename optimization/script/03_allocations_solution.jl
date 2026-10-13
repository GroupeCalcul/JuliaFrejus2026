# # Exercise 3 — Allocations and GC (solution)
#
# Run the cells one by one with `Shift+Enter` in Jupyter.
#
# Measuring allocations:
#
#     @allocated f(x)     # bytes
#     @allocations f(x)   # count
#     @time f(x)          # ... and % of time spent in the garbage collector (GC)
#     @benchmark f($x)    # distribution of the times, with the % of GC time
#
# A heap allocation costs three times: the allocation itself, the work of the
# GC to free it, and the pollution of the caches by new memory.
#
# For each part: measure (`@btime`, `@time`), understand where the
# allocations come from, write a version that allocates less, measure again.
#
# When you are done, call `check()` (at the bottom of the notebook).

using BenchmarkTools, LinearAlgebra, StaticArrays, Test

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 1.0;  # shorter benchmarks for the session

## A. Temporary arrays

function f1(x)
    y = x .^ 2
    z = y .+ 1
    return sum(z)
end

x = rand(10^6)
y = similar(x);
#-
@btime f1($x);

# **Q1.** How many temporary arrays does `f1` allocate? Compare the minimum
# and the mean time: what fraction of the time of `f1` is spent in the GC?

@benchmark f1($x)

# **Answer.** Two temporary arrays (`y` and `z`), 8 MB each. The minimum time
# (the one reported by `@btime`) is a run without GC; the mean time is several
# times larger, and the difference is mostly GC time (see `GC (mean ± σ)`; the
# exact % depends on the machine and the Julia version). `@btime` alone hides
# the cost of the GC.

# **Q2.** Write, measuring each time:
# - `f2(x)`: a single line, with fusion of the "dotted" operations;
# - `f3(x)`: without any temporary array (hint: `sum(f, x)`);
# - `f4!(y, x)`: writes `x^2 + 1` into the buffer `y`, then returns its sum.

f2(x) = sum(x .^ 2 .+ 1)  # fused: a single temporary array

f3(x) = sum(xi -> xi^2 + 1, x)  # reduction with a function: no temporary array

function f4!(y, x)  # convention: the `!` signals that `y` is modified
    @. y = x^2 + 1
    return sum(y)
end
#-
@btime f2($x);
#-
@btime f3($x);
#-
@btime f4!($y, $x);

# **Answer.** Julia fuses the "dotted" operations of a single expression into
# one loop: `f2` allocates one array instead of two. `f3` allocates nothing.
# `f4!` reuses a buffer provided by the caller: useful when the intermediate
# array is needed. Without allocations, the GC has nothing left to do: 0% of
# GC time, and the mean time is close to the minimum.

@benchmark f3($x)

## B. Array slices
#
# Allocations often hide where you do not expect them:
# - slices: `A[:, j]` copies → `@views`;
# - repeated `push!` → preallocate, or `sizehint!`;
# - small `Vector`s used as points (`rand(3)`) → `SVector{3,Float64}`;
# - type instability → boxing (see exercise 2).

function column_sums(A)
    s = zeros(size(A, 2))
    for j in axes(A, 2)
        s[j] = sum(A[:, j])
    end
    return s
end

A = rand(1000, 1000);
#-
@btime column_sums($A);

# **Q3.** What does `A[:, j]` do? Write `column_sums_views` with `@views` and
# compare. Is there a standard library function that already does this?

function column_sums_views(A)
    s = zeros(size(A, 2))
    @views for j in axes(A, 2)
        s[j] = sum(A[:, j])
    end
    return s
end
#-
@btime column_sums_views($A);

# **Answer.** `A[:, j]` allocates a new vector and copies the column into it.
# `@views` turns slices into views (no copy). The standard library already
# does it:

@btime sum($A; dims=1);

## C. Building an array

function squares(n)
    v = Float64[]
    for i in 1:n
        push!(v, i^2)
    end
    return v
end

@btime squares(10^5);

# **Q4.** Why are there more allocations than calls to `squares`?
# Write `squares_prealloc(n)`, which allocates the array only once.

function squares_prealloc(n)
    v = Vector{Float64}(undef, n)
    for i in 1:n
        v[i] = i^2
    end
    return v
end
#-
@btime squares_prealloc(10^5);

# **Answer.** When the vector is full, `push!` allocates a bigger one and
# copies the elements: about `log(n)` allocations. The final size is known
# here: allocate only once. Alternatively: a comprehension,
# `[i^2 for i in 1:n]`, or `sizehint!(v, n)` before the `push!` calls.

## D. Small vectors: StaticArrays

function path_length(points)
    L = 0.0
    for i in 1:(length(points)-1)
        L += norm(points[i+1] - points[i])
    end
    return L
end

points = [rand(3) for _ in 1:(10^5)];
#-
@btime path_length($points);

# **Q5.** Where do the allocations come from?
#
# **Q6.** Build `points_s`, a vector of `SVector{3,Float64}` holding the same
# points, and measure again. Do you need to change `path_length`?

points_s = [SVector{3}(p) for p in points];
#-
@btime path_length($points_s);

# **Answer.** Each point is a heap-allocated `Vector{Float64}`, and each
# subtraction `points[i+1] - points[i]` allocates a new `Vector`.
#
# An `SVector{3,Float64}` has a size known at compile time: it is an immutable
# "bits" type, stored inline in the array, and operations on it never
# allocate (the loop over the 3 components is unrolled). `path_length` is
# generic: it does not need to change.

## What did we learn?
#
# - Measure allocations with `@btime`, `@allocated`, `@allocations`.
#   `@benchmark` also shows the % of GC time: the GC shows up in the mean
#   time, not in the minimum reported by `@btime`.
# - Temporaries: fuse the dots (`.`), use `sum(f, x)`, or reuse a buffer
#   (`f!`).
# - Slices copy: `@views`.
# - Growing arrays: preallocate, or `sizehint!`.
# - Small fixed-size vectors: `SVector` (StaticArrays), 0 allocations.
# - The goal: no allocations in critical loops, not zero allocations everywhere.

## Check

function check()
    x = rand(10^4)
    y = similar(x)
    A = rand(100, 100)
    f3(x), f4!(y, x), column_sums_views(A), squares_prealloc(100), path_length(points_s)  # compilation
    @testset "Exercise 3" begin
        @test f2(x) ≈ f1(x)
        @test f3(x) ≈ f1(x)
        @test f4!(y, x) ≈ f1(x)
        @test (@allocated f3(x)) == 0
        @test (@allocated f4!(y, x)) == 0
        @test column_sums_views(A) ≈ column_sums(A)
        @test (@allocated column_sums_views(A)) < (@allocated column_sums(A)) / 10
        @test squares_prealloc(100) == squares(100)
        @test (@allocations squares_prealloc(100)) < (@allocations squares(100))
        @test eltype(points_s) <: SVector{3}
        @test path_length(points_s) ≈ path_length(points)
        @test (@allocated path_length(points_s)) == 0
    end
    return nothing
end

# Run the check once you have answered all the questions:

#nb check()
