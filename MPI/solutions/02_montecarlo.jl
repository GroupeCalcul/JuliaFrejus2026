using MPI
using Random

MPI.Init()

atexit() do
    MPI.Finalize()
end

comm = MPI.COMM_WORLD
nranks = MPI.Comm_size(comm)
rank = MPI.Comm_rank(comm)

N_global = 1_000_000
i_begin = N_global * rank ÷ nranks + 1
i_end = N_global * (rank + 1) ÷ nranks
N_local = i_end - i_begin + 1

# Make sure all ranks generate different random numbers
rng = Random.default_rng()
Random.seed!(rng, 42 + rank)

# The result is ≈ π * N_local / 4
sum_local = sum(1:N_local) do n
    x = rand(rng, Float64)
    y = rand(rng, Float64)
    float(x^2 + y^2 < 1)  # = 1 if within the circle
end
@show rank, sum_local * 4 / N_local  # close to π

sum_global = MPI.Reduce(sum_local, +, comm; root = 0)

if rank == 0
    π_global = sum_global * 4 / N_global
    @show π_global
end
