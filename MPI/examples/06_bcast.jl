using MPI

MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
nranks = MPI.Comm_size(comm)

msg = [rank, rank]

# Send from rank 0 to all other ranks
MPI.Bcast!(msg, comm; root = 0)

# Now all ranks have [0, 0]
@show rank, msg

MPI.Finalize()
