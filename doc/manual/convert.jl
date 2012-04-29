#
# Convert github manual to reStructuredText
#
# $ julia convert.jl /path/to/julialang.github.com/manual
#

manual = ARGS[1]

chapters = [
    "arrays",
    "calling-c-and-fortran-code",
    "complex-and-rational-numbers",
    "constructors",
    "control-flow",
    "conversion-and-promotion",
    "functions",
    "getting-started",
    "integers-and-floating-point-numbers",
    "introduction",
    "mathematical-operations",
    "metaprogramming",
    "methods",
    "parallel-computing",
    "performance-tips",
    "potential-features",
    "running-external-programs",
    "strings",
    "types",
    "variables-and-scoping",
]

for name in chapters
    run(`pandoc -o $name.rst $manual/$name/index.md`)
    run(`perl -pi -e '$_ = "" if ( $. < 3 );' $name.rst`)
    run(`perl -pi -e 's/^\| title:(.+) \|$/\1/ if ( $. == 2 );' $name.rst`)
    run(`perl -pi -e 's/^\+----------// if ( $. == 1 || $. == 3 );' $name.rst`)
    run(`perl -pi -e 'y/\-\+/\*/ if ( $. == 1 || $. == 3 );' $name.rst`)
    x = "print \".. _man-$name:\n\" if ( \$. == 1 )"
    run(`perl -pi -le $x $name.rst`)
end
