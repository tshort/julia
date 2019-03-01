# Test file to try out a "standalone_aot_mode".

module X
import LLVM

function irgen(@nospecialize(f), @nospecialize(tt); dump = false)
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
    function hook_raise_exception(insblock::Ptr{Cvoid}, ex::Ptr{Cvoid})
        insblock = convert(LLVM.API.LLVMValueRef, insblock)
        ex = convert(LLVM.API.LLVMValueRef, ex)
        raise_exception(BasicBlock(insblock), Value(ex))
    end
    params = Base.CodegenParams(track_allocations=false,
                                code_coverage=false,
                                static_alloc=false,
                                prefer_specsig=true,
                                raise_exception=hook_raise_exception)

    # generate IR
    ccall(:jl_set_standalone_aot_mode, Nothing, ())
    native_code = ccall(:jl_create_native, Ptr{Cvoid},
                        (Vector{Core.MethodInstance}, Base.CodegenParams), [linfo], params)
    @assert native_code != C_NULL
    # ccall(:jl_emit_globals_table, Nothing, (Ptr{Cvoid},), native_code)
    llvm_mod_ref = ccall(:jl_get_llvm_module, LLVM.API.LLVMModuleRef,
                         (Ptr{Cvoid},), native_code)
    @assert llvm_mod_ref != C_NULL
#    if dump
#	    a = Array{UInt8}(undef, 1000000)
#	    ptr = pointer(a)
#	    ccall(:jl_dump_native, Nothing, 
#		  (Ptr{Cvoid}, String, Cstring, Cstring, Ptr{UInt8}, Csize_t), 
#		  native_code, Cvoid, "unopt_bc_fname.bc", Cvoid, ptr, length(a))
#		  #native_code, "bc_fname.bc", "unopt_bc_fname.bc", "obj_fname.o", ptr, length(a))
#    end
    ccall(:jl_clear_standalone_aot_mode, Nothing, ())
    LLVM.Module(llvm_mod_ref)
end

# Various tests

f_ccall() = ccall("myfun", Int, ())
println("f_ccall")
m_ccall = irgen(f_ccall, Tuple{})

f_cglobal() = cglobal("myglobal", Int)
println("f_cglobal")
m_cglobal = irgen(f_cglobal, Tuple{})

f_cglobal2() = cglobal("myglobal", Float64)
println("f_cglobal2")
m_cglobal2 = irgen(f_cglobal2, Tuple{})

f_Int() = UInt32
println("f_Int")
m_Int = irgen(f_Int, Tuple{})

f_string() = "asdfjkl"
println("f_string")
m_string = irgen(f_string, Tuple{})

const a = Ref(0x80808080)
f_jglobal() = a[]
println("f_jglobal")
m_jglobal = irgen(f_jglobal, Tuple{})

struct A
    a::Int
    b::Float64
end

f_Atype() = A
println("f_Atype")
m_Atype = irgen(f_Atype, Tuple{})

@noinline f_A() = A(1, 2.2)
@noinline f_A2(x) = x.a > 2 ? 2*x.b : x.b
println("f_A")
m_A = irgen(f_A, Tuple{})
m_A2 = irgen(f_A2, Tuple{A})

# f_arraysum(x) = sum([x, 1])
# m_arraysum = irgen(f_arraysum, Tuple{Int})
end   # module
nothing
