z=Ref(Int32(0))
ccall((:truc,"./libtruc.so"), Cvoid, (Ref{Int32},), z)
println(z[])
