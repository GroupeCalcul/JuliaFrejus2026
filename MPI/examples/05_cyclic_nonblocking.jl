using MPI

MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
nranks = MPI.Comm_size(comm)

sendbuf = [rank, rank]
recvbuf = similar(sendbuf)
right = mod(rank + 1, nranks)
left = mod(rank - 1, nranks)

req_send = MPI.Request()
req_recv = MPI.Request()
MPI.Isend(sendbuf, comm, req_send; dest = right)
MPI.Irecv!(recvbuf, comm, req_recv; source = left)

MPI.Waitall([req_send, req_recv])

@show rank, recvbuf

MPI.Finalize()
