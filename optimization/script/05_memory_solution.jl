# # Exercise 5 — Memory and cache (solution)
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
    fill!(y, zero(eltype(y)))
    for j in axes(A, 2)
        xj = x[j]  # local value: stays in a register
        for i in axes(A, 1)
            y[i] += A[i, j] * xj
        end
    end
    return y
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

# **Answer.** In `matvec_rows!`, the inner loop runs over `j`: each access
# jumps by `size(A, 1)` elements, and each cache line loaded is used only
# once. In `matvec_cols!`, the inner loop is contiguous: ~4× faster here.

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
#
# **Answer.**
# - **Q2a.** 8n² bytes read for 2n² operations: 0.25 flop/byte. The
#   matrix-vector product is limited by memory bandwidth, not by computation:
#   it is memory-bound.
# - **Q2b.** The throughput is the number of bytes of `A` read, divided by the
#   time.

function bandwidth(f!, n)
    A = rand(n, n)
    x = rand(n)
    y = zeros(n)
    t = @belapsed $f!($y, $A, $x)
    return 8n^2 / t / 1e9  # GB/s
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

# **Answer.** Results on an Intel Core Ultra 7 165H (L2 2 MiB/core, L3 24 MiB):
#
# ```
#      n     size A     rows      cols     mul!   (GB/s)
#     32      0.0 MiB     15.3      27.7     91.2
#    128      0.1 MiB     11.8      60.3    114.2
#    512      2.0 MiB      8.6      67.3    109.4
#   1024      8.0 MiB      4.6      63.9     78.3
#   2048     32.0 MiB      1.3      28.9     37.3
#   4096    128.0 MiB      0.7      21.6     28.3
# ```
#
# - **Q2c.** Even in cache, the row-wise traversal is 2 to 6× slower: its
#   inner loop makes strided accesses and a floating-point reduction, so the
#   compiler does not use SIMD instructions; column-wise, the inner loop is
#   contiguous and uses SIMD. As soon as `A` exceeds the L2 cache, the
#   row-wise traversal collapses (20 to 30× slower): each cache line loaded is used
#   only once. Once `A` no longer fits in L3, the column-wise traversal and
#   `mul!` slow down to the RAM bandwidth.
# - **Q2d.** No: once out of cache, `mul!` ≈ a well-written loop. For a
#   memory-bound computation, BLAS cannot work miracles.

## Q3. Matrix-matrix product
#
# - **Q3a.** How many operations, and how many bytes of data, for `C = A * B`
#   (n × n matrices)? Is the computation memory-bound or compute-bound?
# - **Q3b.** Choose the right loop order in `matmul!` (6 possible orders!),
#   then compare the Gflop/s obtained with `mul!` (BLAS).

function matmul!(C, A, B)
    fill!(C, zero(eltype(C)))
    for j in axes(B, 2), k in axes(A, 2)
        bkj = B[k, j]
        for i in axes(A, 1)  # inner loop over the first index of `C` and `A`
            C[i, j] += A[i, k] * bkj
        end
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

# **Answer.**
# - **Q3a.** 2n³ operations for 3 × 8n² bytes: the arithmetic intensity is
#   n/12 flop/byte, it grows with n. The computation is limited by the CPU
#   (compute-bound), and BLAS exploits the cache (blocking), SIMD and FMA.
# - **Q3b.** The inner loop must run over `i`, the first index of both `C`
#   and `A`: orders `(j, k, i)` or `(k, j, i)`. Result: loops ~11 Gflop/s,
#   BLAS ~57 Gflop/s (×5) on a single core. (With the naive `(i, j, k)`
#   order: ~1.7 Gflop/s.)

# **Q3c.** Bonus: run `mul!` again after `BLAS.set_num_threads(4)`. (The
# number of BLAS threads is independent of the number of Julia threads.)

BLAS.set_num_threads(4)
t_blas_mt = @belapsed mul!($C, $A, $B)
@printf("BLAS, %d threads: %.1f Gflop/s\n", BLAS.get_num_threads(), 2n^3 / t_blas_mt / 1e9)
BLAS.set_num_threads(1)

# **Answer.** ~200 Gflop/s with 4 threads: ×3.5 compared to one BLAS thread,
# ×18 compared to our loops.

## What did we learn?
#
# - Column-major: the inner loop runs over the first index (contiguous
#   accesses, full cache lines, SIMD).
# - The throughput drops in steps when the data leave L2, then L3.
# - Arithmetic intensity: matvec (0.25 flop/byte) is memory-bound, `mul!` ≈
#   a well-written loop; matmul (n/12) is compute-bound, BLAS is ×5 faster on
#   one core, ×18 with 4 threads.
# - Before writing a kernel, check whether it exists in a library.

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
