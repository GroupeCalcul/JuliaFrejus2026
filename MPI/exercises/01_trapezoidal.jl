using MPI

MPI.Init()

comm = MPI.COMM_WORLD
nranks = MPI.Comm_size(comm)
rank = MPI.Comm_rank(comm)

f(x) = 4 * sqrt(1 - x^2)
N = 211  # prime number (to make things fun)
xs = range(0, 1; length = N + 1)  # evaluation points (equidistant)

# Local integration interval (making sure there is no overlap)
# TODO: update interval
i_begin = ...
i_end = ...
# @show rank, i_begin, i_end

# Compute local integral
integ_local = sum(i_begin:i_end) do i
    xa, xb = xs[i], xs[i + 1]
    (f(xa) + f(xb)) * (xb - xa) / 2
end

# TODO: compute and print full integral

MPI.Finalize()
