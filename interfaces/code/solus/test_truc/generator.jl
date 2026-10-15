using Clang.Generators
cd(@__DIR__)
include_dir = pwd()
options = load_options(joinpath(@__DIR__, "generator.toml"))
args = get_default_args() 
push!(args, "-I$include_dir")
headers = [ joinpath(include_dir, "alloc.h")]
ctx = create_context(headers, args, options)
build!(ctx)
