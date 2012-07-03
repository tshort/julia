# Formulas for representing and working with linear-model-type expressions
# Harlan D. Harris

# we can use Julia's parser and just write them as expressions

type Formula
    lhs::Vector
    rhs::Vector
end

function _dashtree_to_list(ex::Expr)
    # if the head of the expression is a --, return a list of recursive calls to the LHS and RHS
    # otherwise, return what we got as a cell array
    if ex.args[1] == :(--)
        append(_dashtree_to_list(ex.args[2]), _dashtree_to_list(ex.args[3]))
    else
        [ ex ]
    end
end
_dashtree_to_list(ss::Symbol) = [ ss ]

function Formula(ex::Expr) 
    # confirm we've got a call to ~, then recursively build a list out of -- - separated subtrees
    if ex.args[1] != :(~)
        error("Formula must have a ~!")
    else
        lhs = _dashtree_to_list(ex.args[2])
        rhs = _dashtree_to_list(ex.args[3])
        Formula(lhs, rhs)
    end
end

# a ModelFrame is just a wrapper around a DataFrame
# construct with mf::ModelFrame = model_frame(f::Formula, d::DataFrame)
# this unpacks the formula, extracts the columns from the DataFrame, and
# applies the ^, &, *, / operators, and evaluates any other expressions 
# in the context of the df. Note that columns remain DataVecs, and NAs are 
# preserved through this step.

# minimal first version: support y ~ x1 + x2 + log(x3)
type ModelFrame
    df::DataFrame
    y_indexes::Vector{Int}
    formula::Formula 
end

function model_frame(f::Formula, d::DataFrame)
    # for now, assume the lhs and rhs are a simple disjunction/summation of literal clauses,
    # where each literal may be a simple transforming function
    
    cols = {}
    colnames = Array(ASCIIString,0)
    
    # so, foreach element in the lhs, evaluate it in the context of the df
    for ll = 1:length(f.lhs)
        push(cols, with(d, f.lhs[ll]))
        push(colnames, string(f.lhs[ll]))
    end
    y_indexes = [1:length(f.lhs)]
    
    # and foreach element in the rhs, do the same
    
    # if it's a disjunction, get the pieces, otherwise it's just itself
    if f.rhs[1].args[1] == :+
        rhs = f.rhs[1].args[2:end]
    else
        rhs = r.rhs[1]
    end
    for rr = 1:length(rhs)
        push(cols, with(d, rhs[rr]))
        push(colnames, string(rhs[rr]))
    end
    
    # bind together and return
    ModelFrame(DataFrame(cols, colnames), y_indexes, f)
end

# a ModelMatrix is a wrapper around a matrix, with column names.
# construct with mm::ModelMatrix = model_matrix(mf::ModelFrame, ...)
# this converts any non-numeric types to contrasts, deals with NAs, etc.

# minimal first version: allow numbers and strings only, complete cases only

