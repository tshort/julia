## definitions for "Data" types which can contain NAs
## Inspirations:
## R's NAs
## Panda's discussion of NAs: http://pandas.pydata.org/pandas-docs/stable/missing_data.html
## NumPy's analysis of the issue: https://github.com/numpy/numpy/blob/master/doc/neps/missing-data.rst

## Core data types
## IntData -- Int64 + mask for NA
## FloatData -- Float64 + mask for NA
## StringData -- CharString + mask for NA
## BoolData -- Bool + payload for NA?
## DateData -- TBD
## FactorData -- TBD

abstract NAData <: Number

type _NA
end
const NA = _NA()

type IntData <: NAData
    value::Int64
    mask::Bool
end
IntData(x::Int) = IntData(x, false)

# naData(x::Int) = IntData(x)
# naData(x::Int, m::Bool) = IntData(x, m)

convert(::Type{IntData}, x::Int) = IntData(x)
convert(::Type{IntData}, x::_NA) = IntData(0,true)

promote_rule(::Type{IntData}, ::Type{Int64}) = IntData
promote_rule(::Type{IntData}, ::Type{Int32}) = IntData
promote_rule(::Type{IntData}, ::Type{_NA}) = IntData
promote_rule(::Type{Int64}, ::Type{_NA}) = IntData
promote_rule(::Type{Int32}, ::Type{_NA}) = IntData

+(a::IntData, b::IntData) = IntData(a.value + b.value, a.mask || b.mask)
+(a::IntData, b::_NA) = +(promote(a,b)...)
+(a::_NA, b::IntData) = +(b,a)
+(a::IntData, b::Int) = +(promote(a,b)...)
+(a::Int, b::IntData) = +(b,a)
+(a::Int, b::_NA) = +(promote(a,b)...)
+(a::_NA, b::Int) = +(promote(a,b)...)


 

isna(x::IntData) = x.mask
isna(x::Int) = isna(convert(IntData,x))


## DataTable - a list of heterogeneous Data vectors with row and col names



