
println("before init")
ccall((:init_lib, "/home/tshort/jn-codegen/src/libmany.so"), Cvoid, ()) 
println("after init")
@show ccall((:julia_f_many_149, "/home/tshort/jn-codegen/src/libmany.so"), Any, ())