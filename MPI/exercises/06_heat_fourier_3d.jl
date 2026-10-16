# Generalise the 2D heat equation example to 3D.

using MPI
using PencilArrays
using PencilArrays.PencilIO
using PencilFFTs
using AbstractFFTs
using GLMakie

# This plots local values on the 3D domain.
function plot_contour(u::PencilArray, grid, Ls; label = "", kws...)
    fig = Figure(size = (700, 600))
    ax = Axis3(fig[1, 1]; aspect = :data, xlabel = "x", ylabel = "y", zlabel = "z")
    hidespines!(ax)
    # Plot global domain limits
    wireframe!(ax, Rect((0, 0, 0), Ls); color = :gray)
    up = parent(u)  # Makie doesn't like PencilArray (`up` is a regular Array)
    # Contour requires an interval (start, stop)
    points = map(xs -> (xs[begin], xs[end]), grid.coords)
    cf = contour!(ax, points..., up; kws...)
    Colorbar(fig[1, 2], cf; label)
    fig
end

# Typical usage:
# fig = plot_contour(u, grid, Ls; label = L"u", levels = 0:0.1:1)
# save("u_rank$(rank).png", fig)

## ================================================================================ ##

# TODO: your code here
