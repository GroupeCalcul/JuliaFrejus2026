# # Exercise 5 — Memory and cache
#
# Run the cells one by one with `Shift+Enter` in Jupyter.
#
# When you are done, call `check()` (at the bottom of the notebook).

using BenchmarkTools, LinearAlgebra, Printf, Test

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 1.0;  # shorter benchmarks for the session
BLAS.set_num_threads(1)  # fair comparison: our loops are sequential

## Starting code: matrix-vector product, row-wise traversal

function matvec_rows!(y, A, x)
    for i in axes(A, 1)
        y[i] = 0.0
        for j in axes(A, 2)
            y[i] += A[i, j] * x[j]
        end
    end
    return y
end

## Q1. Column-wise traversal
#
# Julia stores matrices column by column ("column-major", like Fortran):
# `A[1,1], A[2,1], …, A[n,1], A[1,2], …` are contiguous in memory. The
# processor loads memory by **cache lines** of 64 bytes = 8 `Float64`: jumping
# by `n` elements wastes 7/8 of each line loaded. The inner loop should run
# over the *first* index:
#
#     for j in axes(A, 2)        # outer loop: 2nd index
#         for i in axes(A, 1)    # inner loop: 1st index
#             ... A[i, j] ...
#         end
#     end
#
# Write `matvec_cols!(y, A, x)` whose inner loop walks through memory
# contiguously, then compare with `matvec_rows!` and `mul!`.

function matvec_cols!(y, A, x)
    return matvec_rows!(y, A, x)  # TODO: write this
end
#-
n = 2000
A = rand(n, n)
x = rand(n)
y = zeros(n);
#-
@btime matvec_rows!($y, $A, $x);
#-
@btime matvec_cols!($y, $A, $x);
#-
@btime mul!($y, $A, $x);

## Q2. Effective bandwidth as a function of size
#
# Orders of magnitude (recent CPU, one core):
#
# |       | size        | latency               |
# |:------|:------------|:----------------------|
# | L1    | 32–48 KiB   | ~1 ns                 |
# | L2    | 1–2 MiB     | ~4 ns                 |
# | L3    | 10–100 MiB  | ~15 ns                |
# | RAM   | GiB         | ~80 ns, 10–20 GB/s    |
#
# Compute: a few Gflop/s with scalar instructions (one operation at a time),
# ×4–8 with **SIMD** instructions (Single Instruction, Multiple Data: one
# instruction processes 4 to 8 `Float64` at once), ×2 with **FMA**
# (fused multiply-add: `a * b + c` in a single instruction). The compiler
# generates SIMD instructions on its own when the loop accesses memory
# contiguously and the order of the operations does not matter.
# (Run `lscpu` in a terminal to see your machine's caches.)
#
# Is a computation limited by memory or by the CPU? Compare its **arithmetic
# intensity** (flops / bytes transferred) with the ratio of the machine
# (Gflop/s / GB/s, ~1–10): below, it is **memory-bound**; above, it is
# **compute-bound**.
#
# The matrix-vector product reads each element of `A` (8 bytes) exactly once,
# for 2 operations (one multiplication, one addition).
#
# - **Q2a.** What is the arithmetic intensity of the matrix-vector product?
# - **Q2b.** Complete `bandwidth`: return the effective throughput in GB/s
#   (bytes of `A` read / time).

function bandwidth(f!, n)
    A = rand(n, n)
    x = rand(n)
    y = zeros(n)
    t = @belapsed $f!($y, $A, $x)
    return NaN  # TODO: write this
end

function bandwidth_table(ks=5:12)
    println("     n     size A     rows      cols     mul!   (GB/s)")
    for k in ks
        n = 2^k
        @printf("%6d %8.1f MiB %8.1f %9.1f %8.1f\n", n, 8n^2 / 2^20,
            bandwidth(matvec_rows!, n),
            bandwidth(matvec_cols!, n),
            bandwidth(mul!, n))
    end
end

# - **Q2c.** Run `bandwidth_table()`. Where are the "steps"? Relate them to the
#   cache sizes.
# - **Q2d.** For large sizes, is `mul!` much faster than `matvec_cols!`? Why?

bandwidth_table()

## Q3. Matrix-matrix product
#
# - **Q3a.** How many operations, and how many bytes of data, for `C = A * B`
#   (n × n matrices)? Is the computation memory-bound or compute-bound?
# - **Q3b.** Choose the right loop order in `matmul!` (6 possible orders!),
#   then compare the Gflop/s obtained with `mul!` (BLAS).

function matmul!(C, A, B)
    fill!(C, zero(eltype(C)))
    for i in axes(A, 1), j in axes(B, 2), k in axes(A, 2)  # TODO: loop order
        C[i, j] += A[i, k] * B[k, j]
    end
    return C
end
#-
n = 512
A = rand(n, n)
B = rand(n, n)
C = zeros(n, n);
#-
t_loops = @belapsed matmul!($C, $A, $B);
#-
t_blas = @belapsed mul!($C, $A, $B);
#-
@printf("matmul: loops %.1f Gflop/s, BLAS %.1f Gflop/s (×%.0f)\n",
    2n^3 / t_loops / 1e9, 2n^3 / t_blas / 1e9, t_loops / t_blas)

# **Q3c.** Bonus: run `mul!` again after `BLAS.set_num_threads(4)`. (The
# number of BLAS threads is independent of the number of Julia threads.)

## What did we learn?
#
# In your own words: how do memory layout and caches affect performance?
# When is it worth calling a library? (Double-click to edit this cell.)
#
# - …
# - …
# - …

## Check

function check()
    A = rand(300, 200)
    x = rand(200)
    B = rand(200, 100)
    @testset "Exercise 5" begin
        @test matvec_rows!(zeros(300), A, x) ≈ A * x
        @test matvec_cols!(zeros(300), A, x) ≈ A * x
        @test matvec_cols!(rand(300), A, x) ≈ A * x  # `y` is reset
        @test matmul!(zeros(300, 100), A, B) ≈ A * B
        @test 0 < bandwidth(matvec_cols!, 64) < 1e4  # GB/s
    end
    return nothing
end

# Run the check once you have answered all the questions:

#nb check()
