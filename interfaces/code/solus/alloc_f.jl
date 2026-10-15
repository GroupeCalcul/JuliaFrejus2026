using Libdl: dlopen, dlsym
lib_alloc = dlopen("./liballoc_f.so")
all_ptr, fre_ptr, set_ptr, get_ptr = map(x->dlsym(lib_alloc, x), [:my_alloc, :my_free, :set_values, :get_values])

function alloc(n::Int64)
  ret = Ref(0)
  ccall(all_ptr, Cvoid, (Ref{Int64}, Ref{Int64}), n, ret)
  if (ret == -2) println("allocation table is full") end
  if (ret == -1) println("could not allocate another bloc") end
  ret[]
end

function free(n::Int64)
  ccall(fre_ptr, Cvoid, (Ref{Int64},), n)
end

function set_values(id, val::Vector{Float64})
  ret = Ref(0)
  ccall(set_ptr, Cvoid,(Ref{Int64}, Ref{Int64}, Ptr{Float64}, Ref{Int64}), length(val), id, val, ret) 
  return ret[]
end

function get_values!(id, val::Vector{Float64}, nb)
  ret = Ref(0)
  ccall(get_ptr, Cvoid,(Ref{Int64}, Ref{Int64}, Ptr{Float64}, Ref{Int64}), nb, id, val, ret) 
  return ret[]
end

