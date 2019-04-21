
include("IRGen.jl")
using .IRGen

using Test

# Various tests
using LLVM
llvmmod(native_code) =
    LLVM.Module(ccall(:jl_get_llvm_module, LLVM.API.LLVMModuleRef,
                      (Ptr{Cvoid},), native_code.p))

pkgdir = @__DIR__

using Optim
rosenbrock(x) =  (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2
fopt(x) = minimum(optimize(rosenbrock, [0,x], BFGS()))

# @show llvmmod(irgen(fopt, Tuple{Float64}))
dump_native(irgen(fopt, Tuple{Float64}), "libfopt.o")
run(`clang -shared -fpic libfopt.o -o libfopt.so -L$pkgdir/../../usr/lib -ljulia-debug -ldSFMT`)
@show ccall((:init_lib, "./libfopt.so"), Cvoid, ()) 
GC.enable(false)
@show ccall((:fopt, "./libfopt.so"), Float64, (Float64,), 0.0) 
GC.enable(true)