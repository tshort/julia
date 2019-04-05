# Standalone AOT compilation mode

This mode of compilation aims to statically compile Julia code to libraries or executables
that do not need a system image. This will allow Julia to support more use cases: 

* Smaller standalone executables with faster startup.
* Compilation to standalone libraries. For example, R or Python packages could link to
  Julia binary libraries.
* Cross compilation to more limited systems. This could be an embedded system or WebAssembly
  for web apps. 

To support these modes, the following compilation targets should be supported:

* A shared library that links to the `libjulia` shared library.
* An executable that links to the `libjulia` shared library.
* An object file meant to dynamically link to the `libjulia` shared library.

In addition to these, we'd also like to support these same targets, but statically link 
to `libjulia.a` for smaller standalone executables or libraries.

## Approach

This approach works by introducing a `standalone-aot-mode` into Julia's code generation
process. This is similar to the `imaging-mode`. The main differences are:

* `ccall` -- `foreigncall`'s normally are converted to calls to function pointers. In
  `standalone-aot-mode`, these are compiled to normal external function calls to be 
  resolved at link time.
* `cglobal` -- As with `ccall`'s, these are compiled to normal external references.
* *Global variables* -- This is the tricky part. Global variables (symbols, strings,
  and Julia global variables) are serialized to a "mini image" (a binary array). An
  initialization function is provided to restore the global variables upon startup.
  The serialization code reuses the machinery in "src/dump.c".

Initialization is another tricky bit. The standard way to embed Julia is to use the
following template:

```
int main(int argc, char *argv[])
{
    jl_init();
    // Do stuff...
    jl_atexit_hook(0);
    return 0;
}
```

It also may fail if `jl_init` relies on having the sysimg.
Beyond that, we may not want all of what `jl_init` does for some use cases.

## Current status

The code can handle `ccall` and `cglobal`. There's working code for serialization and 
restoration of global variables. Some simple programs work when compiled to a shared 
library then called from Julia (using `ccall`). It also renames functions, so that 
`julia_myfun_203` is `myfun` in the resulting object file.

The `test/standalone-aot` directory contains tests/examples. `runtests.jl` runs tests.
`IRGen.jl` has code to generate standalone libraries. The main routines are:

* `native = irgen(f, argtypes)` -- Return a native-code representation of function `f`
  with Tuple types `argtypes`.
* `dump_native(native, filename)` -- Dump `native` to the `.o` object file.
* `@jlrun f(args...)` -- Compile `f` to a dynamic library and call it with `ccall`. 
  Uses `clang` to compile the `.o` file to a `.so` shared library (hardcoded for
  Linux for now).

Support for standalone libraries and executables is also possible. 
See the `test/standalone-aot/standalone-exe` for two examples. 
This hasn't been tested a lot.

A major problem area is dynamic code that uses `invoke()`. That currently doesn't work
at all. That is used in IO code, so there's no "hello world", yet.

Right now, the testing code just targets Linux.

## Next steps

- Continue to work on initialization.
- Fix exporting, so only the methods passed to `create_native` get exported.
- Don't export intrinsics as globals.
- Work out how to initialize type pointers: should be part of `jl_init`.
- Work out initialization and calls from other code. What about multiple library invocations?
- Work out stdin, stdout, etc.
- Apply `ExternalLinkage` for code in libjulia (finish this).
- Come up with a strategy for `invoke`.

Help would be appreciated in any of the above plus code reviews and testing out what types 
of code compiles and what doesn't. 

## Other ideas

- Maybe return an object that has information on what functions are exported. 
  This could be used to generate C headers or interfaces to other languages like R or Python.

## Relevant issues / repos

* https://github.com/JuliaLang/julia/pull/25984 -- Jameson's codegen restructuring 
  branch that can compile recursive functions using the CUDAnative approach
  (jn/codegen-norecursion branch).
* https://github.com/Keno/julia-wasm -- Scripts to compile the wasm version of Julia.
* https://github.com/Keno/julia-wasm/issues/5 -- Discussion of static compilation for wasm.
