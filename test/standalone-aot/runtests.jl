include("IRGen.jl")
using .IRGen

using Test

# Various tests

twox(x) = 2x
@test twox(10) == @jlrun twox(10)

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

# f_cglobal() = cglobal("myglobal", Int)
# println("f_cglobal")
# m_cglobal = irgen(f_cglobal, Tuple{})

## BROKEN

sv = Core.svec(1,2,3,4)
f_sv() = sv
# @show @jlrun f_sv()

arr = [9,9,9,9]
f_array() = arr
# @show @jlrun f_array()

struct AaaaaA
    a::Int
    b::Float64
end

A = AaaaaA(1, 2.2)
A2(x) = x.a > 2 ? 2*x.b : x.b
# @show z = @jlrun A2(A)

many() = ("jkljkljkl", :jkljkljkljkl, :asdfasdf, "asdfasdfasdf")
# @test many() == @jlrun many()

