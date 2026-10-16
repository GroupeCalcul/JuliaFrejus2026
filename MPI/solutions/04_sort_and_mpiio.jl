using MPI
using Random

MPI.Init()

atexit() do
    MPI.Finalize()
end

comm = MPI.COMM_WORLD
nranks = MPI.Comm_size(comm)
rank = MPI.Comm_rank(comm)

# (1) Generate random numbers in [0, 1)
N_global = 1_000
values = Array{Float64}(undef, N_global)
if rank == 0
    rand!(values)
end
MPI.Bcast!(values, comm; root = 0)

# (2) Define local domain and sort local values
v_begin = rank / nranks
v_end = (rank + 1) / nranks

# (3) Sort "local" values in [v_begin, v_end)
values_local = filter(values) do v
    v_begin <= v < v_end
end
# Alternative:
# f(v) = v_begin <= v < v_end
# values_local = filter(f, values)
sort!(values_local)  # local sort

# (4) Determine offset wrt previous ranks
N_local = length(values_local)
N_accum = MPI.Scan(N_local, +, comm)  # similar to Base.accumulate
N_prev = N_accum - N_local    # remove contribution from local values
offset = N_prev * sizeof(eltype(values_local))  # in bytes

# (5) Write to binary file with MPI-IO
filename = "sorted.dat"
file = MPI.File.open(comm, filename; write = true)
MPI.File.write_at_all(file, offset, values_local)
close(file)

# (6) Verification
if rank == 0
    values_sorted = similar(values)
    read!(filename, values_sorted)
    @show issorted(values_sorted)
end
