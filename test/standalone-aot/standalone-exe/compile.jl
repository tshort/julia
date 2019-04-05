include("../IRGen.jl")
using .IRGen
    
twox(x) = 2x
native = irgen(twox, Tuple{Int})
dump_native(native, "libtwox.o")
run(`clang -shared -fpic libtwox.o -o libtwox.so`)
dir = @__DIR__
run(`clang -c -std=gnu99 -I'../../../usr/include/julia' -DJULIA_ENABLE_THREADING=1 -fPIC twox.c`)
run(`clang -o twox twox.o -L$dir -L$dir/../../../usr/lib -Wl,--unresolved-symbols=ignore-in-object-files -Wl,-rpath,'.' -Wl,-rpath,'../../../usr/lib' -ljulia-debug -ltwox`)


arraysum(x) = sum([x, 1])
native = irgen(arraysum, Tuple{Int})
dump_native(native, "libarraysum.o")
run(`clang -shared -fpic libarraysum.o -o libarraysum.so`)
dir = @__DIR__
run(`clang -c -std=gnu99 -I'../../../usr/include/julia' -DJULIA_ENABLE_THREADING=1 -fPIC arraysum.c`)
run(`clang -o arraysum arraysum.o -L$dir -L$dir/../../../usr/lib -Wl,--unresolved-symbols=ignore-in-object-files -Wl,-rpath,'.' -Wl,-rpath,'../../../usr/lib' -ljulia-debug -larraysum`)
