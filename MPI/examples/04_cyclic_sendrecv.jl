using MPI

MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
nranks = MPI.Comm_size(comm)

msg = [rank, rank]
right = mod(rank + 1, nranks)
left = mod(rank - 1, nranks)

sendbuf = msg
recvbuf = similar(msg)
MPI.Sendrecv!(sendbuf, recvbuf, comm; dest = right, source = left)

@show rank, recvbuf

MPI.Finalize()

