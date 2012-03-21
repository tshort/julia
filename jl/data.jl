## definitions for "Data" types which can contain NAs
## Inspirations:
## R's NAs
## Panda's discussion of NAs: http://pandas.pydata.org/pandas-docs/stable/missing_data.html
## NumPy's analysis of the issue: https://github.com/numpy/numpy/blob/master/doc/neps/missing-data.rst

## Abstract type is Data, which is a parameterized type that wraps an array of a type and a bit array
## for the mask. 

bitstype 64 Mask

type Data{T}
    dat::Vector{T}
    mask::Vector{Mask}
    
    # constructor enforces requirement that the mask have the right number of bits
end

function bool2mask(x::Vector{Bool})
    # convert a vector of booleans to a bit-vector of Mask-sized elements
    # split the vector up into chunks of size 64
    # convert each to a 
    masklen = convert(Int, ceil(length(x) / 64.0))
    []
end

convert(::Type{Mask}, x::Any) = boxui64(0)

function _bool2mask(x::Vector{Bool})
    # convert a 64-vector to a single Mask
    m = empty

function Data(x::Vector{T}, m::Vector{Bool})
    @assert length(x) == length(m)
    
    
end

# ways to construct a Data object...
# Constructors should exist that take a data vector and a mask vector of booleans,
# which gets converted to the bitmask.
# That will work fine for things like file input.
# But that doesn't work for interactive input!
# One option would be promote mixed arrays to a union type, which gets reconverted
# to the Data type:
# Data([1, 2, NA, 4])
# Another option would be to use cell arrays and specify the data type, ala:
# IntData({1, 2, NA, 4})
# Either should be ok for efficiency, because manual input will only be applicable
# for very small arrays. Will try the former first.

type _NA
end
const NA = _NA()
show(x::_NA) = print("NA")

IntNA = Union(Int64, _NA)
FloatNA = Union(Float, _NA)
BoolNA = Union(Bool, _NA)

convert(::Type{Int64}, ::Type{_NA}) = typemin(Int64)
convert(::Type{Float64}, ::Type{_NA}) = NaN
convert(::Type{Bool}, ::Type{_NA}) = false

promote_rule{T<:Int}(::Type{T}, ::Type{_NA}) = IntNA
promote_rule{T<:Int}(::Type{T}, ::Type{IntNA}) = IntNA

function D(v::Vector{IntNA})
    Data(map(x->(typeof(x)==_NA ? 0 : convert(Int,x)), v),
         map(x->(typeof(x)==_NA), v))
end

# ## Core data types
# ## IntData -- Int64 + mask for NA
# ## FloatData -- Float64 + mask for NA
# ## StringData -- CharString + mask for NA
# ## BoolData -- Bool + payload for NA?
# ## DateData -- TBD
# ## FactorData -- TBD
# 
# abstract NAData <: Number
# 
# type _NA <: NAData
# end
# const NA = _NA()
# 
# type NAException <: Exception
#     msg::String
# end
# 
# type IntData <: NAData
#     value::Int64
#     mask::Bool
# end
# IntData(x::Int) = IntData(x, false)
# 
# # naData(x::Int) = IntData(x)
# # naData(x::Int, m::Bool) = IntData(x, m)
# 
# convert(::Type{IntData}, x::Int) = IntData(x)
# convert(::Type{IntData}, x::_NA) = IntData(0,true)
# # can only convert non-NA IntData to Int
# convert(::Type{Int}, x::IntData) = x.mask ? throw(NAException("Can't convert NA to base type")) : x.value
# 
# promote_rule(::Type{IntData}, ::Type{_NA}) = IntData
# promote_rule{I<:Int}(::Type{I}, ::Type{_NA}) = IntData
# # promote_rule(::Type{Int64}, ::Type{_NA}) = IntData
# # promote_rule(::Type{Int32}, ::Type{_NA}) = IntData
# promote_rule{I<:Int}(::Type{IntData}, ::Type{I}) = IntData
# #promote_rule(::Type{IntData}, ::Type{Int64}) = IntData
# #promote_rule(::Type{IntData}, ::Type{Int32}) = IntData
# 
# 
# +(a::IntData, b::IntData) = IntData(a.value + b.value, a.mask || b.mask)
# -(a::IntData, b::IntData) = +(a, -b)
# -(a::IntData) = IntData(-a.value, a.mask)
# *(a::IntData, b::IntData) = IntData(a.value * b.value, a.mask || b.mask)
# ==(a::IntData, b::IntData) = (a.value == b.value && a.mask == b.mask)
# 
# # this needs FloatData
# #/(a::IntData, b::IntData)
# 
# # this needs BoolData
# #<(a::IntData, b::IntData) = (a.mask || b.mask) ? NA : a.value < b.value
#  
# 
# isna(x::IntData) = x.mask
# isna(x::Int) = isna(convert(IntData,x))
# isna(x::_NA) = true
# @vectorize_1arg NAData isna
# 
# show(x::IntData) = x.mask ? show(NA) : show(x.value)
# show(x::_NA) = print("NA")
# 
# 
# ## DataTable - a list of heterogeneous Data vectors with row and col names
# 
# 
# 

