include("IRGen.jl")
using .IRGen

using Test

# Various tests
using LLVM
llvmmod(native_code) =
    LLVM.Module(ccall(:jl_get_llvm_module, LLVM.API.LLVMModuleRef,
                      (Ptr{Cvoid},), native_code.p))

pkgdir = @__DIR__

# @show llvmmod(irgen(rand, Tuple{}))
# @show a = @jlrun rand()    # broken for some reason
# dump_native(irgen(rand, Tuple{}), "librand.o")
# run(`clang -shared -fpic librand.o -o librand.so -L$pkgdir/../../usr/lib -ljulia-debug -ldSFMT`)
# @show ccall((:init_lib, "./librand.so"), Cvoid, ()) 
# @show ccall((:rand, "./librand.so"), Float64, ()) 
# @show ccall((:rand, "./librand.so"), Float64, ()) 
# @show ccall((:rand, "./librand.so"), Float64, ()) 


using Dates
fdate(x) = Dates.days(Dates.DateTime(2016, x, 1))
native = irgen(fdate, Tuple{Int})
@show llvmmod(native)
@show @jlrun fdate(3)
@test fdate(3) == @jlrun fdate(3)

mutable struct AAA
    aaa::Int
    bbb::Int
end
@noinline ssum(x) = x.aaa + x.bbb
fstruct(x) = ssum(AAA(x, 99))
@test fstruct(10) == @jlrun fstruct(10)

module ZZ
mutable struct AAA
    aaa::Int
    bbb::Int
end
@noinline ssum(x) = x.aaa + x.bbb
fstruct(x) = ssum(AAA(x, 99))
end # module
ffstruct(x) = ZZ.fstruct(x)
@test ffstruct(10) == @jlrun ffstruct(10)

push!(LOAD_PATH, ".")
import ZZZ
fffstruct(x) = ZZZ.fstruct(x)
@test fffstruct(10) == @jlrun fffstruct(10)
# @show llvmmod(irgen(fffstruct, Tuple{Int}))

twox(x) = 2x
@test twox(10) == @jlrun twox(10)

fmap(x) = sum(map(twox, [1, x]))
# @test fmap(10) == @jlrun fmap(10)

hello() = "hellllllo world!"
@test hello() == @jlrun hello()

fint() = UInt32
@test fint() == @jlrun fint()

const a = Ref(0x80808080)
jglobal() = a[]
@test jglobal()[] == (@jlrun jglobal())[]

arraysum(x) = sum([x, 1])
@test arraysum(6) == @jlrun arraysum(6)

fsin(x) = sin(x)
@test fsin(0.5) == @jlrun fsin(0.5)

fccall() = ccall(:jl_ver_major, Cint, ())
@test fccall() == @jlrun fccall()

fcglobal() = cglobal(:jl_n_threads, Cint)
@test fcglobal() == @jlrun fcglobal()

many() = ("jkljkljkl", :jkljkljkljkl, :asdfasdf, "asdfasdfasdf")
## @jlrun doesn't work with this method.
## Here, ccall needs an Any return type, not the tuple type deduced by @jlrun.
# @show @jlrun many()
native = irgen(many, Tuple{})
dump_native(native, "libmany.o")
run(`clang -shared -fpic libmany.o -o libmany.so -L$pkgdir/../../usr/lib -ljulia-debug`)
ccall((:init_lib, "./libmany.so"), Cvoid, ()) 
@test many() == ccall((:many, "./libmany.so"), Any, ()) 

const sv = Core.svec(1,2,3,4)
fsv() = sv
@test fsv() == @jlrun fsv()

const arr = [9,9,9,9]
farray() = arr
@test farray() == @jlrun farray()


nothing
