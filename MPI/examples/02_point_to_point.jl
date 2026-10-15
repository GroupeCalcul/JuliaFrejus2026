using MPI

MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
nranks = MPI.Comm_size(comm)

if nranks < 2
    error("run this script with 2 processes or more")
end

msg = [rank, rank]
source = 0
dest = 1

if rank == source
    MPI.Send(msg, comm; dest)
elseif rank == dest
    MPI.Recv!(msg, comm; source)
end
@show rank, msg

MPI.Finalize()
