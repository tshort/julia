# Test file to try out a "standalone_aot_mode".

module X
import LLVM

function irgen(@nospecialize(f), @nospecialize(tt), filename = "test.so")
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
        @assert native_code != C_NULL
        ccall(:jl_clear_standalone_aot_mode, Nothing, ())
        llvm_mod_ref = ccall(:jl_get_llvm_module, LLVM.API.LLVMModuleRef,
                             (Ptr{Cvoid},), native_code)
        @assert llvm_mod_ref != C_NULL
        # ccall(:jl_dump_native_lib, Nothing, (Ptr{Cvoid}, Cstring), native_code, filename)
    catch e
        ccall(:jl_clear_standalone_aot_mode, Nothing, ())
        println(e)
    end
    return LLVM.Module(llvm_mod_ref)
end

macro c_str(s) unescape_string(replace(s, "\\" => "\\x")) end

function test_read()
    # mini_sysimg = c"\16\88\C6\EB\12\09\00\00\00jkljkljkl\12\05\00\00\00qwery\12\0C\00\00\00asdfasdfasdf\04\07\14@\E6\01\1F\1C=\06\03\00\12\00\12\00\12\16\88\C2\EB\16\88\C2\EB\08\FF\FF\FF\FF"
    mini_sysimg = c"\16\88\C7\EB\02\0Cjkljkljkljkl\02\08asdfasdf\12\09\00\00\00jkljkljkl\12\0C\00\00\00asdfasdfasdf\04\07\14@\E6\01\1F\1C=\06\04\00\12\00\02\00\02\00\12\16\88\C2\EB\16\88\C2\EB\16\88\C2\EB\FF\FF\FF\FF" 
    io = IOStream("iosmem")
    ccall(:ios_mem, Ptr{Cvoid}, (Ptr{UInt8}, UInt), io.ios, 0)
    write(io, mini_sysimg)
    seekstart(io)
    ccall(:jl_restore_mini_sysimg, Any, (Ptr{Cvoid},), io)
end

# @show rest = test_read()

# Various tests

Base.@ccallable Float64 f_2x(x) = 2x
println("f_2x")
m_2x = irgen(f_2x, Tuple{Float64}, "lib_2x.so")
@show m_2x

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

astr = "hellllllo world"
f_string() = "hellllllo world!"
@show pointer_from_objref(astr)
@show pointer_from_objref(String)
println("f_string")
@show m_string = irgen(f_string, Tuple{})

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
# println("f_Atype")
# m_Atype = irgen(f_Atype, Tuple{}, dump = false)

# @noinline f_A() = AaaaaA(1, 2.2)
# @noinline f_A2(x) = x.a > 2 ? 2*x.b : x.b
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
# m_arraysum = irgen(f_arraysum, Tuple{Int})

# f_many() = ("jkljkljkl", :jkljkljkljkl, :asdfasdf, "asdfasdfasdf")
# # f_many() = (:jkljkljkljkl, :asdfasdf, :qwerty)
# # f_many() = ("jkljkljkl", "qwery", "asdfasdfasdf")
# println("f_many")
# m_many = irgen(f_many, Tuple{})



end   # module
nothing
