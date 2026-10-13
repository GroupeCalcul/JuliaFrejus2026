# # Exercise 1 — Measuring correctly (solution)
#
# Run the cells one by one with `Shift+Enter` in Jupyter.
#
# We do this exercise together, before any theory. For each question:
# 1. **predict** what you expect (time? allocations?);
# 2. run the cell and compare with your prediction;
# 3. discuss, then note what you learned: we will summarize it together at
#    the end.
#
# When you are done, call `check()` (at the bottom of the notebook).

using BenchmarkTools, InteractiveUtils, Test

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 1.0;  # shorter benchmarks for the session

## Starting code

function sum1(x)
    s = 0
    for i in 1:length(x)
        s += x[i]
    end
    return s
end

x = rand(10^6);

## Q1. First call vs subsequent calls
#
# Run the two cells below, one after the other.
# - What does the "compilation time" percentage of the first call represent?
# - Why does the first call allocate so much more than the second?

@time sum1(x);
#-
@time sum1(x);

# **Answer.** The first call includes the JIT compilation of `sum1` for
# `Vector{Float64}`: the "compilation time" percentage, and the allocations
# made by the compiler. Subsequent calls reuse the compiled code. The only
# remaining allocation (16 bytes) is the result being returned to global
# scope: negligible.
#
# => Never take the first call into account (or use BenchmarkTools).

## Q2. Code in global scope
#
# The same loop, written directly in global scope (outside a function).
# Compare time and allocations with `sum1(x)`. Why such a difference?

s = 0.0
@time for i in eachindex(x)
    global s += x[i]
end

# **Answer.** A non-`const` global variable can change type at any time: the
# compiler cannot assume anything about `s` or `x`. Every `+` goes through
# dynamic dispatch (the method to call is looked up at run time) and every
# result is "boxed" on the heap.
#
# => Millions of allocations, and code a few hundred times slower here.
#
# => Put performance-critical code inside functions.

## Q3. BenchmarkTools and `$` interpolation
#
# `@btime` runs the function many times and reports the minimum time.
# - Compare `@btime sum1(xs)` and `@btime sum1($xs)` on a small vector.
# - Why should global variables be interpolated with `$`?
# - What does `@benchmark` give you on top of `@btime`?
# - How do you get the time as a number (to use in a computation)? Try `@belapsed`.

xs = rand(10)
@btime sum1(xs);
#-
@btime sum1($xs);
#-
@benchmark sum1($x)
#-
t = @belapsed sum1($x)

# **Answer.** Without `$`, `xs` is an untyped global: the benchmark also
# measures the global access and the dynamic dispatch (a few ns, visible on a
# small vector). With `$`, the value is spliced into the benchmarked
# expression, just like a function argument.
#
# `@benchmark` gives the full distribution (min, median, mean, max,
# histogram) and the time spent in GC. `@belapsed` returns the minimum time
# in seconds, as a number.

## Q4. Type stability
#
# Look at the output of `@code_warntype`. What is the type of `s`? Why?

@code_warntype sum1(x)

# **Answer.** `s` starts as `0::Int64`, then becomes `Float64` after the first
# addition: its inferred type is `Union{Float64, Int64}` (yellow in
# `@code_warntype`).

# Write `sum2`, identical to `sum1` but with a type-stable accumulator,
# and compare the timings. You may see no speed difference: why? What does
# `sum1(Float64[])` return?
# Hint: `zero(eltype(x))`.

function sum2(x)
    s = zero(eltype(x))  # accumulator of the same type as the elements
    for i in eachindex(x)
        s += x[i]
    end
    return s
end
#-
@code_warntype sum2(x)
#-
@btime sum1($x);
#-
@btime sum2($x);
#-
sum1(Float64[]), sum2(Float64[])

# **Answer.** Here the timings are identical: Julia handles small unions
# without allocation ("union splitting"). But:
# - the result type depends on the data: `sum1(Float64[])` returns `0::Int`,
#   which propagates the instability to all the calling code;
# - in more complex code (larger union, non-inlined call), it turns into
#   dynamic dispatch and allocations.
#
# => A type instability is not always costly, but it always shows up in
#    `@code_warntype`: fix it systematically.

## Q5. Compare with the standard library
#
# - `sum(x)` is even faster than `sum2`. Why? (two reasons; hint: can the
#   processor do several additions at once? In which order?)
# - Are the results exactly equal? How should two floating-point results be
#   compared in a test?

@btime sum($x);
#-
sum2(x) == sum(x), sum2(x) ≈ sum(x)

# **Answer.** `sum(x)` is faster because:
# 1. it uses **SIMD** instructions (Single Instruction, Multiple Data): one
#    instruction adds 4 to 8 `Float64` at once. This requires several partial
#    sums, so the additions are done in a different order. Floating-point
#    addition is not associative, so the compiler does not reorder the loop
#    of `sum2` on its own; `sum` is written to allow it;
# 2. it uses pairwise summation, which is also more accurate.
#
# The results therefore differ in the last digits: compare with `≈`
# (`isapprox`), never with `==`.

## Q6. Benchmarking a function that mutates its argument
#
# This benchmark of `sort!` is wrong: why?
# Fix it with the `setup=(...)` and `evals=1` options of `@btime`.

v = rand(10^5)
@btime sort!($v);

# **Answer.** After the first evaluation, `v` is sorted: the following
# evaluations sort an already sorted vector, which is not the case we want to
# measure. We need a fresh random vector for each sample (`setup`) and a
# single evaluation per sample (`evals=1`).

@btime sort!(w) setup = (w = rand(10^5)) evals = 1;

## What did we learn?
#
# - The first call includes JIT compilation: ignore it. A single `@time` is
#   also noisy, and reports the share of GC time.
# - Performance-critical code goes inside functions (global scope: a few
#   hundred times slower here, with millions of allocations).
# - `@btime` / `@benchmark` (BenchmarkTools) warm up and repeat the
#   measurement; `@belapsed` returns the time in seconds, for computations.
#   Interpolate globals with `$`.
# - A function that mutates its argument needs `setup=(...)` and `evals=1`.
# - Floating point: compare with `≈` (`isapprox`), never `==`.

## Check

function check()
    x = rand(10^5)
    sum2(x)  # compilation
    @testset "Exercise 1" begin
        @test sum2(x) ≈ sum(x)
        @test sum2(x) isa Float64
        @test sum2(Float64[]) isa Float64  # type-stable accumulator
        @test sum2(Int[]) isa Int
        @inferred sum2(x)
        @test (@allocated sum2(x)) == 0
    end
    return nothing
end

# Run the check once you have answered all the questions:

#nb check()
