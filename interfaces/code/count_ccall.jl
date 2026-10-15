versions=["v0.1","v0.2.0","v0.3.0","v0.4.0","v0.5.0","v0.6.0","v0.7.0","v1.0.0","v1.1.0","v1.2.0","v1.3.0","v1.4.0","v1.5.0","v1.6.0","v1.7.0","v1.8.0","v1.9.0"]
function count_ccall(versions)
  cc_count = zeros(Int64, size(versions,1))
  for (i,v) in enumerate(versions)
    run(`git checkout $v`)
    cc_count[i] = 0
    for z in readlines(pipeline(`ag  -c --julia ccall`)) # you need ag, the silver_searcher !
      cc_count[i] += parse(Int64,split(z, ":")[2])
    end
  end
  return cc_count
end
ccall_count = cd( ()->count_ccall(versions), "/path/to/julia/sources")
using Plots

#extract versions as numbers
x =  map(x->parse(Float64,x[2:4]),versions)
plot(x, ccall_count; label="#ccall", title="counting ccalls in Julia sources")
xlabel!("version number")
ylabel!("#occurences(ccall)")
myshow()
