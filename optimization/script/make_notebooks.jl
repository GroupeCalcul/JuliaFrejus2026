# Generate Jupyter notebooks from the exercise scripts.
#
# Usage, from a Julia session started in the `optimization/` folder:
#
#     ] activate script
#     include("script/make_notebooks.jl")
#     make_notebook()     # all notebooks
#     make_notebook(1)    # only notebook 01 (exercise and solution)
#
# The scripts in `script/` are converted, without being executed, to notebooks:
#
# - `script/NN_name.jl`          -> `exercises/NN_name.ipynb`
# - `script/NN_name_solution.jl` -> `exercises/NN_name_solution.ipynb`
#
# Conventions used in the scripts (see https://fredrikekre.github.io/Literate.jl):
# - `# text` at the start of a line becomes Markdown;
# - `## Title` delimits a cell in VS Code; it becomes a Markdown heading here;
# - a `#-` line splits two code cells;
# - `#nb code` is a comment in the script, and code in the notebook.

using Literate

# `## Title` -> Markdown heading
cells_to_headings(content) = replace(content, r"^## "m => "# ## ")

"""
    make_notebook()
    make_notebook(n::Int)

Convert the scripts of `script/` to notebooks in `exercises/`: all of them, or
only those of exercise `n` (exercise and solution).
"""
function make_notebook(n::Union{Int,Nothing}=nothing)
    script = @__DIR__
    outdir = joinpath(dirname(script), "exercises")
    for file in sort(readdir(script))
        m = match(r"^(\d+)_.*\.jl$", file)
        isnothing(m) && continue
        (isnothing(n) || parse(Int, m[1]) == n) || continue

        Literate.notebook(joinpath(script, file), outdir;
            execute=false, credit=false, preprocess=cells_to_headings)
    end
end
