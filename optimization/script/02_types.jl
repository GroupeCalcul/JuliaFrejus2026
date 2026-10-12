# # Exercise 2 — Type stability
#
# Run the cells one by one with `Shift+Enter` in Jupyter.
#
# Julia compiles each function **for the concrete types of its arguments**.
# If the compiler can infer the type of every variable, it produces machine
# code comparable to C/Fortran; otherwise it falls back to dynamic dispatch
# and "boxed" values, which allocate.
#
# - **Concrete** types (`Float64`, `Vector{Float64}`, `Matrix{Float64}`):
#   size and memory layout are known.
# - **Abstract** types (`Real`, `Any`, `AbstractVector`): the value is
#   "boxed", and calls are resolved at run time.
#
# A function is **type-stable** when the type of every variable (and of the
# result) depends only on the *types* of the arguments, not on their *values*.
#
# Diagnosis tools:
# - `@code_warntype f(x)`: look for `Any` / `Union` in red or yellow;
# - `@report_opt f(x)` (JET): lists the dynamic dispatches, i.e. the calls
#   whose method can only be chosen at run time;
# - in a profile (exercise 4), red bars are dynamic dispatches.
#
# Classic causes and their fixes:
#
# | Problem                                   | Fix                                            |
# |:------------------------------------------|:-----------------------------------------------|
# | non-`const` global                        | `const`, argument, `x::Float64 = …`            |
# | field `x::Real`                           | `struct P{T<:Real}; x::T; end`                 |
# | `[]`, `Dict{String,Any}`                  | typed container, function barrier              |
# | `s = 0` then `s += 1.0`                   | `s = zero(eltype(x))`                          |
# | reassigned variable captured in a closure | `let`, don't reassign                          |
#
# For each of the three functions below:
# 1. measure with `@btime` (time and allocations);
# 2. diagnose with `@code_warntype` and/or `@report_opt`;
# 3. write a fixed version, then measure again.
#
# When you are done, call `check()` (at the bottom of the notebook).

using BenchmarkTools, InteractiveUtils, JET, Test

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 1.0;  # shorter benchmarks for the session

## A. Non-constant global variable

rate = 0.05

function final_capital(capital, n)
    for _ in 1:n
        capital *= 1 + rate
    end
    return capital
end

@btime final_capital(1000.0, 1000);

# **Q1.** Why does `final_capital` allocate on every iteration? Look at the
# type of `rate` in the two diagnostics below.

@code_warntype final_capital(1000.0, 10)
#-
@report_opt final_capital(1000.0, 10)

# **Q2.** Propose two fixes:
# - `final_capital_const(capital, n)`, which uses a global constant `RATE`;
# - `final_capital_arg(capital, n, rate)`, which takes the rate as an argument.
#
# Which one do you prefer? Why?

const RATE = 0.05

function final_capital_const(capital, n)
    return final_capital(capital, n)  # TODO: write this
end

function final_capital_arg(capital, n, rate)
    return final_capital(capital, n)  # TODO: write this
end
#-
@btime final_capital_const(1000.0, 1000);
#-
@btime final_capital_arg(1000.0, 1000, 0.05);

## B. Fields of abstract type

struct Particle
    x::Real
    v::Real
end

function kinetic_energy(ps)
    E = 0.0
    for p in ps
        E += p.v^2 / 2
    end
    return E
end

ps = [Particle(rand(), rand()) for _ in 1:(10^4)];
#-
@btime kinetic_energy($ps);

# **Q3.** Why 3 allocations per particle? What is `isconcretetype(Real)`?

@code_warntype kinetic_energy(ps)
#-
isconcretetype(Real)
#-
isconcretetype(Particle)

# **Q4.** Define a parametric type `ParticleT{T<:Real}` whose fields have a
# concrete type, build `ps_t` from `ps`, and measure `kinetic_energy` again.
# Do you need to change `kinetic_energy`? (Parametric types are covered in
# depth in the session on multiple dispatch and generic typing.)

ps_t = ps;  # TODO: define `ParticleT`, then build a vector of `ParticleT`
#-
@btime kinetic_energy($ps_t);

## C. Untyped container and function barrier

# Parameters read from a configuration file: the type of each entry is only
# known at run time.

config = Dict{String,Any}("name" => "test", "values" => rand(10^4))

function sum_squares_config(config)
    v = config["values"]  # ::Any
    s = 0.0
    for i in eachindex(v)
        s += v[i]^2
    end
    return s
end
#-
@btime sum_squares_config($config);
#-
@code_warntype sum_squares_config(config)

# **Q5.** We cannot change the type of the `Dict`: it holds values of
# different types. Write `sum_squares_config_barrier(config)`, which extracts
# `config["values"]` and then calls a separate function that does the loop
# (a "function barrier"). Why is it faster?

function sum_squares_config_barrier(config)
    return sum_squares_config(config)  # TODO: write this
end
#-
@btime sum_squares_config_barrier($config);

## What did we learn?
#
# In your own words: what are the classic causes of type instability, how do
# you detect them, and how do you fix them? (Double-click to edit this cell.)
#
# - …
# - …
# - …

## Check

function check()
    @testset "Exercise 2" begin
        @test final_capital_arg(1000.0, 100, 0.05) ≈ final_capital(1000.0, 100)
        @test final_capital_const(1000.0, 100) ≈ final_capital(1000.0, 100)
        @test isempty(JET.get_reports(@report_opt final_capital_const(1000.0, 100)))
        @test isempty(JET.get_reports(@report_opt final_capital_arg(1000.0, 100, 0.05)))
        @test isconcretetype(eltype(ps_t))
        @test kinetic_energy(ps_t) ≈ kinetic_energy(ps)
        @test isempty(JET.get_reports(@report_opt kinetic_energy(ps_t)))
        @test (@allocated kinetic_energy(ps_t)) == 0
        @test sum_squares_config_barrier(config) ≈ sum_squares_config(config)
        sum_squares_config_barrier(config)  # compilation
        @test (@allocated sum_squares_config_barrier(config)) <= 32  # one boxed result
    end
    return nothing
end

# Run the check once you have answered all the questions:

#nb check()
