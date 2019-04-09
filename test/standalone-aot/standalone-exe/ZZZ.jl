
module ZZZ
mutable struct AAA
    aaa::Int
    bbb::Int
end
@noinline ssum(x) = x.aaa + x.bbb
fstruct(x) = ssum(AAA(x, 99))
end # module