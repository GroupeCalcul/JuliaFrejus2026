using MPI
using Random

MPI.Init()

comm = MPI.COMM_WORLD
nranks = MPI.Comm_size(comm)
rank = MPI.Comm_rank(comm)

# (1) Generate random numbers in [0, 1)
N_global = 1_000
values = Array{Float64}(undef, N_global)
if rank == 0
    rand!(values)
end
# TODO: send values to all ranks

# (2) Define local domain and sort local values
v_begin = rank / nranks
v_end = (rank + 1) / nranks

# (3) Sort "local" values in [v_begin, v_end)
values_local = filter(values) do v
    v_begin <= v < v_end
end
sort!(values_local)  # local sort

# (4) Determine offset wrt previous ranks
# TODO: determine number of elements included in all previous ranks
# See MPI.Scan: https://juliaparallel.org/MPI.jl/latest/reference/collective/#MPI.Scan!
N_prev = ...
offset = N_prev * sizeof(eltype(values_local))  # in bytes

# (5) Write to binary file with MPI-IO
filename = "sorted.dat"
file = MPI.File.open(...)   # TODO: complete
MPI.File.write_at_all(...)  # TODO: complete
close(file)

# (6) Verification
if rank == 0
    values_sorted = similar(values)
    read!(filename, values_sorted)
    @show issorted(values_sorted)
end

MPI.Finalize()
