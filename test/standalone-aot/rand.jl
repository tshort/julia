
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
dump_native(irgen(rand, Tuple{}), "librand.o")
run(`clang -shared -fpic librand.o -o librand.so -L$pkgdir/../../usr/lib -ljulia-debug -ldSFMT`)
@show ccall((:init_lib, "./librand.so"), Cvoid, ()) 
GC.enable(false)
@show ccall((:rand, "./librand.so"), Float64, ()) 
@show ccall((:rand, "./librand.so"), Float64, ()) 
@show ccall((:rand, "./librand.so"), Float64, ()) 
GC.enable(true)