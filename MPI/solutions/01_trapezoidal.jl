using MPI

MPI.Init()

comm = MPI.COMM_WORLD
nranks = MPI.Comm_size(comm)
rank = MPI.Comm_rank(comm)

f(x) = 4 * sqrt(1 - x^2)
N = 211  # prime number (to make things more interesting)
xs = range(0, 1; length = N + 1)  # evaluation points (equidistant)

# Local integration interval (making sure there is no overlap)
i_begin = (N * rank) ÷ nranks + 1
# Alternatives:
# i_begin = div(rank * N, nranks) + 1
# i_begin = floor(Int, rank * N / nranks) + 1

i_end = N * (rank + 1) ÷ nranks

# @show rank, i_begin, i_end

# Compute local integral
integ_local = sum(i_begin:i_end) do i
    xa, xb = xs[i], xs[i + 1]
    (f(xa) + f(xb)) * (xb - xa) / 2
end

integ = [integ_local]
MPI.Reduce!(integ, +, comm; root = 0)
if rank == 0
    println("Integral: ", integ[1])
end

MPI.Finalize()
