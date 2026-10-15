using Libdl: dlopen, dlsym
lib_alloc = dlopen("./lib_alloc.so")
all_ptr, fre_ptr = map(x->dlsym(lib_alloc, x), [:my_alloc, :my_free])


so = Libc.FILE(Libc.RawFD(1), "w") 

function myalloc(n::Int, so)
  ptr = ccall(all_ptr, Ptr{Float64}, (Int64, Ptr{Cvoid}), n, so)
  return unsafe_wrap(Array, ptr, n)
end

macro myfree(p)
    quote
      ccall(fre_ptr, Cvoid, (Ptr{Float64},), $(esc(p)))
      $(esc(p)) = nothing
    end
end
function myfree!(p::Vector{Float64})
   ccall(fre_ptr, Cvoid, (Ptr{Float64}, ), p)
end

for i=1:1000
   w = myalloc(1000, so);
   #println("address of w -> ", pointer(w))
   #@myfree w
end
