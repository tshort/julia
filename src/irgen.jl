# Test file to try out a "standalone_aot_mode".

module X
import LLVM

function irgen(@nospecialize(f), @nospecialize(tt), filename = "")
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
        if filename != ""
            ccall(:jl_dump_native_lib, Nothing, (Ptr{Cvoid}, Cstring), native_code, filename)
            return
        end
        llvm_mod_ref = ccall(:jl_get_llvm_module, LLVM.API.LLVMModuleRef,
                             (Ptr{Cvoid},), native_code)
        @assert llvm_mod_ref != C_NULL
    catch e
        ccall(:jl_clear_standalone_aot_mode, Nothing, ())
        println(e)
    end
    return LLVM.Module(llvm_mod_ref)
end

macro c_str(s) unescape_string(replace(s, "\\" => "\\x")) end

function test_read()    ## OUT OF DATE!
    # mini_sysimg = c"\16\88\C6\EB\12\09\00\00\00jkljkljkl\12\05\00\00\00qwery\12\0C\00\00\00asdfasdfasdf\04\07\14@\E6\01\1F\1C=\06\03\00\12\00\12\00\12\16\88\C2\EB\16\88\C2\EB\08\FF\FF\FF\FF"
    mini_sysimg = c"\16\88\C7\EB\02\0Cjkljkljkljkl\02\08asdfasdf\12\09\00\00\00jkljkljkl\12\0C\00\00\00asdfasdfasdf\04\07\14@\E6\01\1F\1C=\06\04\00\12\00\02\00\02\00\12\16\88\C2\EB\16\88\C2\EB\16\88\C2\EB\FF\FF\FF\FF" 
    io = IOStream("iosmem")
    ccall(:ios_mem, Ptr{Cvoid}, (Ptr{UInt8}, UInt), io.ios, 0)
    write(io, mini_sysimg)
    seekstart(io)
    ccall(:jl_restore_mini_sysimg, Any, (Ptr{Cvoid},), io)
end
# @show rest = test_read()

export @jlrun
macro jlrun(fun, args...)
    _jlrun(fun, args...)
end
function _jlrun(fun, args...)
    efun = esc(fun)
    eargs = args
    tt = Tuple{(typeof(eval(a)) for a in eargs)...}
    rettype = code_typed(eval(fun), tt)[1][2]
    funname = string(fun)
    quote
        irgen($efun, $tt, $(string("lib", funname, ".o")))
        run($(`clang -shared -fpic lib$fun.o -o lib$fun.so -L/home/tshort/jn-codegen/usr/lib -ljulia-debug`))
        ccall((:init_lib, $(string("/home/tshort/jn-codegen/src/lib", fun, ".so"))), Cvoid, ()) 
        ccall(($(Meta.quot(fun)), $(string("/home/tshort/jn-codegen/src/lib", fun, ".so"))), 
              $rettype, ($((typeof(eval(a)) for a in eargs)...),), $(eargs...))
    end
end

# Various tests

# Base.@ccallable Float64 f_2x(x) = 2x
# twox(x) = 2x
# @show irgen(twox, Tuple{Int})
# irgen(twox, Tuple{Int}, "libtwox.o")
# @show @jlrun twox 5.1
# m_2x = irgen(twox, Tuple{Float64}, "lib2x.o")

# f_ccall() = ccall("myfun", Int, ())
# println("f_ccall")
# m_ccall = irgen(f_ccall, Tuple{})

# fccall(x) = ccall(:jl_ver_major, Cint, ())
# @show irgen(fccall, Tuple{Int})
# @show @jlrun fccall 1

# f_cglobal() = cglobal("myglobal", Int)
# println("f_cglobal")
# m_cglobal = irgen(f_cglobal, Tuple{})

# f_cglobal2() = cglobal("myglobal", Float64)
# println("f_cglobal2")
# m_cglobal2 = irgen(f_cglobal2, Tuple{})

# f_Int(x) = UInt32
# @show @jlrun f_Int 1
# println("f_Int")
# m_Int = irgen(f_Int, Tuple{})

# f_arr(x) = Array{UInt32,1}
# @show @jlrun f_arr 1
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
# f_array(x) = arr
# @show @jlrun f_array 5
# @show f_array(5)
# println("f_array")
# @show m_array = irgen(f_array, Tuple{Int})
# m_array = irgen(f_array, Tuple{Int}, "libarr.o")
# run(`clang -shared -fpic libarr.o -o libarr.so`)
# ccall((:init_lib, "/home/tshort/jn-codegen/src/libarr.so"), Cvoid, ()) 
# z = ccall((:f_array, "/home/tshort/jn-codegen/src/libarr.so"), Any, (Int,), 1) 

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
# @show z = @jlrun A2 A
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
# ccall((:init_lib, "/home/tshort/jn-codegen/src/libarraysum.so"), Cvoid, ()) 
# ccall((:f_arraysum, "/home/tshort/jn-codegen/src/libarraysum.so"), Int, (Int,), 6) 

# arraysum(x) = sum([x, 1])
# @show macroexpand(X, :(@jlrun arraysum 3))
# @show @jlrun arraysum 3

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
# @show m_many = irgen(f_many, Tuple{})
# m_many = irgen(f_many, Tuple{}, "libmany.o")
# run(`clang -shared -fpic libmany.o -o libmany.so`)
# ccall((:init_lib, "/home/tshort/jn-codegen/src/libmany.so"), Cvoid, ()) 
# @show ccall((:f_many, "/home/tshort/jn-codegen/src/libmany.so"), Any, ()) 
# @show ccall((:f_many, "/home/tshort/jn-codegen/src/libmany.so"), Tuple{String,Symbol,Symbol,String}, ()) 



end   # module
nothing