using Libdl: dlopen, dlsym
lib_alloc = dlopen("./liballoc.so")
all_ptr, fre_ptr, set_ptr, get_ptr = map(x->dlsym(lib_alloc, x), [:my_alloc, :my_free, :set_values, :get_values])

function alloc(n::Int)
    ret = ccall(all_ptr, Int64, (Int64, ), n)
    if (ret == -2) println("allocation table is full") end
    if (ret == -1) println("calloc could not allocate another bloc") end
    return ret
end

