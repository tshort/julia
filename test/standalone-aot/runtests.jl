include("IRGen.jl")
using .IRGen


# Various tests

# Base.@ccallable Float64 f_2x(x) = 2x
# twox(x) = 2x
# @show irgen(twox, Tuple{Int})
# irgen(twox, Tuple{Int}, "libtwox.o")
# @show @jlrun twox 5.0
# m_2x = irgen(twox, Tuple{Float64}, "lib2x.o")

# f_ccall() = ccall("myfun", Int, ())
# println("f_ccall")
# m_ccall = irgen(f_ccall, Tuple{})

# f_cglobal() = cglobal("myglobal", Int)
# println("f_cglobal")
# m_cglobal = irgen(f_cglobal, Tuple{})

# f_cglobal2() = cglobal("myglobal", Float64)
# println("f_cglobal2")
# m_cglobal2 = irgen(f_cglobal2, Tuple{})

# f_Int() = UInt32
# println("f_Int")
# m_Int = irgen(f_Int, Tuple{})

# hello() = "hellllllo world!"
# @show @jlrun hello
# f_string() = "hellllllo world!"
# println("f_string")
# @show m_string = irgen(f_string, Tuple{})
# m_string = irgen(f_string, Tuple{}, "libstring.o")
# run(`clang -shared -fpic libstring.o -o libstring.so`)
# println("after f_string")
# ccall(( :init_lib, "/home/tshort/jn-codegen/src/libstring.so"), Cvoid, ()) 
# ccall((:julia_f_string_170, "/home/tshort/jn-codegen/src/libstring.so"), Cvoid, ()) 

# sv = Core.svec(1,2,3,4)
# @show pointer_from_objref(sv)
# f_sv() = sv
# println("f_sv")
# m_sv = irgen(f_sv, Tuple{})

# arr = [9,9,9,9]
# @show pointer_from_objref(arr)
# @show pointer_from_objref(Array{Int,1})
# f_array() = arr
# println("f_array")
# m_array = irgen(f_array, Tuple{})

# struct AaaaaA
#     a::Int
#     b::Float64
# end

# f_Atype() = AaaaaA
# m_Atype = irgen(f_Atype, Tuple{}, dump = false)

# A = AaaaaA(1, 2.2)
# A2(x) = x.a > 2 ? 2*x.b : x.b
# @show macroexpand(X, :(@jlrun A2 A))
# @show m_A2 = irgen(A2, Tuple{AaaaaA})
# z = @jlrun A2 A
# ccall((:init_lib, "/home/tshort/jn-codegen/src/libA2.so"), Cvoid, ()) 
# ccall((:A2, "/home/tshort/jn-codegen/src/libA2.so"), Float64, (AaaaaA,), A) 

# println("f_A")
# m_A = irgen(f_A, Tuple{})
# m_A2 = irgen(f_A2, Tuple{AaaaaA})

# # Makes a really big mini image if the type is included in the lookup

# const a = Ref(0x80808080)
# f_jglobal() = a[]
# println("f_jglobal")
# m_jglobal = irgen(f_jglobal, Tuple{})

# f_arraysum(x) = sum([x, 1])
# println("f_arraysum")
# @show m_arraysum = irgen(f_arraysum, Tuple{Int})
# m_arraysum = irgen(f_arraysum, Tuple{Int}, "libarraysum.o")
# run(`clang -shared -fpic libarraysum.o -o libarraysum.so`)

arraysum(x) = sum([x, 1])
# @show macroexpand(Main, :(@jlrun arraysum(3)))
@show z = jlrun(arraysum, 3)

# fsin(x) = sin(x)
# @show irgen(fsin, Tuple{Float64})
# @show z = @jlrun fsin 0.5
# @show ccall((:fsin, "/home/tshort/jn-codegen/src/libsin.so"), Float64, (Float64,), 0.5)

# f_helloworld() = println("hello world")
# f_helloworld() = write(stdout, "hello world\n")
# @show m_helloworld = irgen(f_helloworld, Tuple{})
# m_helloworld = irgen(f_helloworld, Tuple{}, "libhelloworld.o")
# run(`clang -shared -fpic libhelloworld.o -o libhelloworld.so`)
# ccall((:init_lib, "/home/tshort/jn-codegen/src/libhelloworld.so"), Cvoid, ()) 
# @show ccall((:julia_f_helloworld_149, "/home/tshort/jn-codegen/src/libhelloworld.so"), Cvoid, ())

# f_many() = ("jkljkljkl", :jkljkljkljkl, :asdfasdf, "asdfasdfasdf")
# # f_many() = (:jkljkljkljkl, :asdfasdf, :qwerty)
# # f_many() = ("jkljkljkl", "qwery", "asdfasdfasdf")
# println("f_many")
# m_many = irgen(f_many, Tuple{}, "libmany.o")
# run(`clang -shared -fpic libmany.o -o libmany.so`)

