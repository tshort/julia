module IRGen

import Libdl

export irgen, dumpnative, jlrun

struct LLVMNativeCode    # thin wrapper
    p::Ptr{Cvoid}
end

"""
Returns an LLVMNativeCode object for the function call `f` with TupleTypes `tt`.
"""
function irgen(@nospecialize(f), @nospecialize(tt))
    # get the method instance
    world = typemax(UInt)
    meth = which(f, tt)
    sig_tt = Tuple{typeof(f), tt.parameters...}
    (ti, env) = ccall(:jl_type_intersection_with_env, Any,
                      (Any, Any), sig_tt, meth.sig)::Core.SimpleVector
    meth = Base.func_for_method_checked(meth, ti)
    linfo = ccall(:jl_specializations_get_linfo, Ref{Core.MethodInstance},
                  (Any, Any, Any, UInt), meth, ti, env, world)

    # set-up the compiler interface
    params = Base.CodegenParams(track_allocations=false,
                                code_coverage=false,
                                static_alloc=false,
                                prefer_specsig=true)

    # generate IR
    ccall(:jl_set_standalone_aot_mode, Nothing, ())
    local llvm_mod_ref
    try
        native_code = ccall(:jl_create_native, Ptr{Cvoid},
                            (Vector{Core.MethodInstance}, Base.CodegenParams), [linfo], params)
        ccall(:jl_clear_standalone_aot_mode, Nothing, ())
        @assert native_code != C_NULL
        return LLVMNativeCode(native_code)
    catch e
        ccall(:jl_clear_standalone_aot_mode, Nothing, ())
        throw(e)
    end
end

"""
Creates an object file from `x`.
"""
dump_native(x::LLVMNativeCode, filename) =
    ccall(:jl_dump_native_lib, Nothing, (Ptr{Cvoid}, Cstring), x.p, filename)

"""
Compiles function call provided and calls it with `ccall` using the shared library that was created.
"""
function jlrun(f, args...)
    @show Tuple{typeof.(args)...}
    @show(nameof(f))
    native = irgen(f, Tuple{typeof.(args)...})
    libname = string("lib", nameof(f), ".o")
    soname = string("lib", nameof(f), ".so")
    pkgdir = @__DIR__
    localdir = pwd()
    dump_native(native, libname)
    run(`clang -shared -fPIC $libname -o $soname -L$pkgdir/../../usr/lib`)
    @show so = Libdl.dlopen(abspath(soname))
    ccall((:init_lib, "/home/tshort/jn-codegen/libarraysum.so"), Cvoid, ()) 
    ccall((:arraysum, so), Int, (Int,), args...)
end


end   # module
# nothing
