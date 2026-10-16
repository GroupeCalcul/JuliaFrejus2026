using MPI

MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
nranks = MPI.Comm_size(comm)

println("Hello world, I am $rank of $nranks")

MPI.Finalize()
