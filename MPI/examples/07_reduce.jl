using MPI

MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
nranks = MPI.Comm_size(comm)

buf = [rank, rank]

# Sum values from all ranks
MPI.Reduce!(buf, +, comm; root = 0)

# Now rank 0 has the result
@show rank, buf

MPI.Finalize()
