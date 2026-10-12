# Profiling and performance optimization

- 9:00 - 10:20 (1h20)
- 10:40 - 12:00 (1h20)

## Setup

From this folder:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

The exercises are Jupyter notebooks. Since they live under `optimization/`, the Julia kernel installed with `--project=@.` (see the main README) uses this folder's `Project.toml`. Use a single-thread kernel: measurements are easier to interpret, and multithreading is covered in another session (only the bonus of exercise 6 uses threads).

## Contents

| Notebook                                                         | Part                      |
| ---------------------------------------------------------------- | ------------------------- |
| [exercises/01_measure.ipynb](exercises/01_measure.ipynb)         | Measuring correctly       |
| [exercises/02_types.ipynb](exercises/02_types.ipynb)             | Type stability            |
| [exercises/03_allocations.ipynb](exercises/03_allocations.ipynb) | Allocations and GC        |
| [exercises/04_profiling.ipynb](exercises/04_profiling.ipynb)     | Profiling                 |
| [exercises/05_memory.ipynb](exercises/05_memory.ipynb)           | Memory and cache          |
| [exercises/06_case_study.ipynb](exercises/06_case_study.ipynb)   | Case study: heat equation |

Each exercise has its solution next to it, in `exercises/NN_name_solution.ipynb`. Each notebook ends with a `check()` function, which tests your answers against the reference code.

## Editing the exercises

The notebooks are generated from the scripts in [script/](script/) with [Literate.jl](https://github.com/fredrikekre/Literate.jl): `NN_name.jl` gives `exercises/NN_name.ipynb`, and `NN_name_solution.jl` gives `exercises/NN_name_solution.ipynb`. The solution script is the exercise script with the TODOs filled in and an **Answer** cell after each question: keep the two in sync. After changing a script, regenerate the notebooks, from a Julia session started in `optimization/` (the environment [script/Project.toml](script/Project.toml) provides Literate.jl):

```julia
] activate script
include("script/make_notebooks.jl")
make_notebook()     # all notebooks
make_notebook(1)    # only notebook 01 (exercise and solution)
```

When editing the scripts, keep them convertible:

- `# text` at the start of a line becomes Markdown, so leave a `#` line before a list or a paragraph that must stay separate;
- `## Title` becomes a Markdown heading;
- a `#-` line splits two code cells;
- comments inside code (for example in a function body) must be trailing comments, otherwise they split the cell;
- `#nb code` is a comment in the script and code in the notebook (used for the final `check()`).

## Slides

The slides ([slides/content.tex](slides/content.tex), Beamer with the Moloch theme) are built with LuaLaTeX from [slides/main.tex](slides/main.tex):

```bash
cd slides
latexmk -lualatex main.tex
```
