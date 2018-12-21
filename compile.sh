
EMCC_DEBUG=2 emcc -Isrc/support \
-Lproducts/lib \
-lLLVMAnalysis -lLLVMAsmParser -lLLVMAsmPrinter -lLLVMBinaryFormat -lLLVMBitReader \
-lLLVMBitWriter -lLLVMCodeGen -lLLVMCore -lLLVMCoroutines -lLLVMCoverage \
-lLLVMDebugInfoCodeView -lLLVMDebugInfoDWARF -lLLVMDebugInfoMSF -lLLVMDebugInfoPDB \
-lLLVMDemangle -lLLVMDlltoolDriver -lLLVMExecutionEngine -lLLVMFuzzMutate \
-lLLVMGlobalISel -lLLVMIRReader -lLLVMInstCombine -lLLVMInstrumentation \
-lLLVMInterpreter -lLLVMLTO -lLLVMLibDriver -lLLVMLineEditor -lLLVMLinker \
-lLLVMMC -lLLVMMCDisassembler -lLLVMMCJIT -lLLVMMCParser -lLLVMMIRParser \
-lLLVMObjCARCOpts -lLLVMObject -lLLVMObjectYAML -lLLVMOption -lLLVMOrcJIT \
-lLLVMPasses -lLLVMProfileData -lLLVMRuntimeDyld -lLLVMScalarOpts -lLLVMSelectionDAG \
-lLLVMSupport -lLLVMSymbolize -lLLVMTableGen -lLLVMTarget -lLLVMTransformUtils \
-lLLVMVectorize -lLLVMWebAssemblyAsmPrinter -lLLVMWebAssemblyCodeGen \
-lLLVMWebAssemblyDesc -lLLVMWebAssemblyDisassembler -lLLVMWebAssemblyInfo \
-lLLVMWindowsManifest -lLLVMXRay -lLLVMipo \
-Lusr/lib -ljulia ui/repl-wasm.c \
--preload-file base/boot.jl --no-heap-copy --source-map-base $url \
-g4 -s WASM=1 -s ASSERTIONS=1 -s ALLOW_MEMORY_GROWTH=1 \
-s ERROR_ON_UNDEFINED_SYMBOLS=0 -v -o hello.html

