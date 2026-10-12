# # Exercise 1 — Measuring correctly
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

## Q2. Code in global scope
#
# The same loop, written directly in global scope (outside a function).
# Compare time and allocations with `sum1(x)`. Why such a difference?

s = 0.0
@time for i in eachindex(x)
    global s += x[i]
end

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

## Q4. Type stability
#
# Look at the output of `@code_warntype`. What is the type of `s`? Why?

@code_warntype sum1(x)

# Write `sum2`, identical to `sum1` but with a type-stable accumulator,
# and compare the timings. You may see no speed difference: why? What does
# `sum1(Float64[])` return?
# Hint: `zero(eltype(x))`.

function sum2(x)
    return sum1(x)  # TODO: write this
end
#-
@code_warntype sum2(x)
#-
@btime sum1($x);
#-
@btime sum2($x);
#-
sum1(Float64[]), sum2(Float64[])

## Q5. Compare with the standard library
#
# - `sum(x)` is even faster than `sum2`. Why? (two reasons; hint: can the
#   processor do several additions at once? In which order?)
# - Are the results exactly equal? How should two floating-point results be
#   compared in a test?

@btime sum($x);
#-
sum2(x) == sum(x), sum2(x) ≈ sum(x)

## Q6. Benchmarking a function that mutates its argument
#
# This benchmark of `sort!` is wrong: why?
# Fix it with the `setup=(...)` and `evals=1` options of `@btime`.

v = rand(10^5)
@btime sort!($v);

# TODO: `@btime sort!(w) setup=(...) evals=1`

## What did we learn?
#
# In your own words, in 4 to 5 lines: how do you measure the performance of
# a Julia function correctly? (Double-click to edit this cell.)
#
# - …
# - …
# - …

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
