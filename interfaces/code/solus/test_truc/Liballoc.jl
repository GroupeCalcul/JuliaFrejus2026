module Liballoc

using CEnum: CEnum, @cenum

function my_alloc(size)
    ccall((:my_alloc, liballoc), Int64, (Int64,), size)
end

function my_free(num)
    ccall((:my_free, liballoc), Cvoid, (Int64,), num)
end

function set_values(size, num, val)
    ccall((:set_values, liballoc), Int64, (Int64, Int64, Ptr{Cdouble}), size, num, val)
end

function get_values(size, num, val)
    ccall((:get_values, liballoc), Int64, (Int64, Int64, Ptr{Cdouble}), size, num, val)
end

const ALLOC_MAX = 4

end # module
