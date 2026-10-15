using MPI
using Random

MPI.Init()

comm = MPI.COMM_WORLD
nranks = MPI.Comm_size(comm)
rank = MPI.Comm_rank(comm)

N_global = 1_000_000

# TODO: update local number of random values
N_local = ...

rng = Random.default_rng()

# Make results reproducible if one changes the number of procs.
Random.seed!(rng, 42)

# Advance RNG (result is discarded). This is not very efficient...
for i in 1:(i_begin - 1)
    x = rand(rng, Float64)
    y = rand(rng, Float64)
end

# The result is ≈ π * N_local / 4
sum_local = sum(1:N_local) do n
    x = rand(rng, Float64)
    y = rand(rng, Float64)
    float(x^2 + y^2 < 1)  # = 1 if within the circle
end
@show rank, sum_local * 4 / N_local  # close to π

# TODO: sum across all ranks
sum_global = ...

if rank == 0
    π_global = sum_global * 4 / N_global
    @show π_global
end

MPI.Finalize()
