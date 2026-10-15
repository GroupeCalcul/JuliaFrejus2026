using MPI

MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
nranks = MPI.Comm_size(comm)

data = [rank, rank]
T = eltype(data)

file = MPI.File.open(comm, "output.dat"; write = true)
offset = sizeof(T) * length(data) * rank

# Alternative, using a view (useful when we want to write to a non contiguous region of the
# file)
# T = eltype(data)
# etype = MPI.Datatype(T)  # input data type
# filetype = etype         # data type in file
# MPI.File.set_view!(file, start, etype, filetype)
# MPI.File.write_all(file, data)

# Contiguous write
MPI.File.write_at_all(file, offset, data)

close(file)

# Verification
data_full = MPI.Gather(data, comm; root = 0)
if rank == 0
    @assert filesize("output.dat") == nranks * length(data) * sizeof(T)
    data_read = Array{T}(undef, length(data), nranks)
    read!("output.dat", data_read)
    display(data_read)
    @assert data_full == vec(data_read)
end

# Read the data back with MPI-IO
buf = similar(data)  # data to be read
file = MPI.File.open(comm, "output.dat"; read = true)
offset = sizeof(T) * length(buf) * rank
MPI.File.read_at_all!(file, offset, buf)
close(file)

@show rank, data, buf

MPI.Finalize()
