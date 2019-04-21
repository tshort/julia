
include("IRGen.jl")
using .IRGen

using Test

# Various tests
using LLVM
llvmmod(native_code) =
    LLVM.Module(ccall(:jl_get_llvm_module, LLVM.API.LLVMModuleRef,
                      (Ptr{Cvoid},), native_code.p))


pkgdir = @__DIR__

module M
struct Singleton end

struct SingletonP{Int} end

end

# tup() = ()
# native = irgen(tup, Tuple{})
# @show llvmmod(native)
# 
# no() = nothing
# native = irgen(no, Tuple{})
# @show llvmmod(native)

sing() = M.Singleton()
#native = irgen(sing, Tuple{})
#@show llvmmod(native)
# dump_native(native, "libsing.o")
# run(`$(Sys.BINDIR)/../tools/clang -shared -fpic libsing.o -o libsing.so -L$pkgdir/../../usr/lib -ljulia-debug`)
# ccall((:init_lib, "./libsing.so"), Cvoid, ()) 
# @test sing() == ccall((:sing, "./libsing.so"), Any, ()) 
GC.enable(false)
GC.enable(true)
@test sing() == @jlrun sing()


nothing