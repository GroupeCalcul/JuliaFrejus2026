# This is a working example of solving the 2D heat equation using FFTs.
#
# For nicer coloured output, run as:
#
#   mpirun -n N julia --project --color=yes 05_heat_fourier_2d.jl
#

using MPI
using PencilArrays
using PencilFFTs
using AbstractFFTs
using CairoMakie

# Visualise decomposition of 2D domain.
function visualise_decomposition(filename, pen::Pencil{2})
    comm = get_comm(pen)
    nranks = MPI.Comm_size(comm)
    if rank == 0
        fig = Figure(size = (400, 300))
        ax = Axis(fig[1, 1]; aspect = DataAspect(), xlabel = L"x", ylabel = L"y")
        for n in 1:nranks
            is, js = range_remote(pen, n)
            a = Point2f(is[begin], js[begin])
            b = Point2f(is[end], js[end])
            vertices = Point2f[
                (a[1], a[2]),
                (a[1], b[2]),
                (b[1], b[2]),
                (b[1], a[2]),
            ]
            poly!(ax, vertices; strokewidth = 1)
            text!(
                ax, "$(n - 1)"; align = (:center, :center), fontsize = 20,
                position = (a + b) / 2
            )
        end
        save(filename, fig)
    end
    nothing
end

function plot_field(filename, xs_global, u::PencilArray)
    root = 0
    u_global = gather(u, root)  # returns `nothing` on ranks > 0
    u_global === nothing && return
    fig = Figure(size = (400, 340))
    ax = Axis(fig[1, 1]; aspect = DataAspect(), xlabel = L"x", ylabel = L"y")
    hm = heatmap!(ax, xs_global..., u_global; colorrange = (0, 1), rasterize = 2)
    Colorbar(fig[1, 2], hm)
    save(filename, fig)
end

## ================================================================================ ##

MPI.Init()

comm = MPI.COMM_WORLD
nranks = MPI.Comm_size(comm)
rank = MPI.Comm_rank(comm)

# Global grid size and domain
Ns = (256, 256)  # = Nx, Ny
Ls = (2π, 2π)    # = Lx, Ly
xs_global = (
    range(0, Ls[1]; length = Ns[1] + 1)[1:(end - 1)],  # exclude endpoint
    range(0, Ls[2]; length = Ns[2] + 1)[1:(end - 1)],  # exclude endpoint
)

# Create domain decomposition (a "Pencil")
pen = Pencil(Ns, comm)     # domain decomposition
grid = localgrid(pen, xs_global)  # local grid
rank == 0 && @info "Created decomposition" pen
visualise_decomposition("decomp_phys.svg", pen)

# Initial condition (Gaussian)
x₀, y₀ = Ls[1] / 2, Ls[2] / 2
σ = Ls[1] / 8
u_init = PencilArray{Float64}(undef, pen)  # contains local data
rank == 0 && @info "Initialised array" summary(u_init)
@. u_init = exp(-((grid.x - x₀)^2 + (grid.y - y₀)^2) / (2 * σ^2))
plot_field("u_initial.svg", xs_global, u_init)

# Perform parallel FFT
plan = PencilFFTPlan(u_init, Transforms.RFFT())
rank == 0 && @info "Created FFT plan" plan
u_hat = plan * u_init

# Let's look at the decomposition of u_hat
pen_f = pencil(u_hat)  # decomposition in Fourier space
rank == 0 && @info "Performed FFT" pen_f summary(u_hat)
visualise_decomposition("decomp_fourier.svg", pen_f)

# Define grid in Fourier space (wavenumbers kx, ky)
ks_global = (
    # Note: the first dimension uses `rfftfreq` instead of `fftfreq`.
    rfftfreq(Ns[1], 2π * Ns[1] / Ls[1]),
    fftfreq(Ns[2], 2π * Ns[2] / Ls[2]),
)
grid_f = localgrid(pen_f, ks_global)  # local grid

# Advance diffusion equation
ν = 0.2  # diffusivity
t = 1.0  # final time

# We can do a simple `for` loop over the local data
for I in CartesianIndices(u_hat)
    i, j = Tuple(I)
    kx, ky = grid_f[I]
    k² = kx^2 + ky^2
    op = exp(-ν * k² * t)     # diffusion operator
    u_hat[I] = op * u_hat[I]  # advance û(0) -> û(t)
end

# Transform back to physical space
u_final = plan \ u_hat
plot_field("u_final.svg", xs_global, u_final)

# Write result to binary file in parallel
using PencilArrays.PencilIO

# By default the output file is independent of the number of MPI processes.
# In general, this means that each process needs to write to discontiguous views of the file.
# This also saves a `u_final.dat.json` file with metadata which can be useful for reading
# back the file (poor man's HDF5).
open(MPIIODriver(), "u_final.dat", comm; write = true) do fh
    fh["temperature"] = u_final
end

# Alternatively, if HDF5.jl is loaded and parallel HDF5 is enabled:
# open(PHDF5Driver(), "u_final.h5", comm; write = true) do fh
#     fh["temperature"] = u_final
# end

# Read the file back
u_read = similar(u_final)
open(MPIIODriver(), "u_final.dat", comm; read = true) do fh
    read!(fh, u_read, "temperature")
end

@show u_read == u_final

MPI.Finalize()
