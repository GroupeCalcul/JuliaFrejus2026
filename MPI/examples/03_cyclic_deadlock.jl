# Don't run this or be prepared to kill the launched MPI processes.

using MPI
MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
nranks = MPI.Comm_size(comm)

msg = [rank, rank]
right = mod(rank + 1, nranks)
left = mod(rank - 1, nranks)

MPI.Send(msg, comm; dest = right)
MPI.Recv!(msg, comm; source = left)

@show rank, msg

MPI.Finalize()
