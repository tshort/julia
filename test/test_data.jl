test_context("Data types and NAs")

test_group("DataVec creation")
dvint = DataVec[1, 2, NA, 4]
dvint2 = DataVec([5:8])
dvflt = DataVec[1.0, 2, NA, 4]
dvstr = DataVec["one", "two", NA, "four"]

@test typeof(dvint) == DataVec{Int64}
@test typeof(dvint2) == DataVec{Int64}
@test typeof(dvflt) == DataVec{Float64}
@test typeof(dvstr) == DataVec{ASCIIString}
#@test throws(DataVec, ([5:8], falses(2)), Exception)

test_group("DataVec access")
@test dvint[1] == 1
@test dvint[3] == NA
@test dvflt[3:4] == DataVec[NA,4.0]

test_group("DataVec methods")
@test size(dvint) == (4,)
@test length(dvint) == 4
@test sum(isna(dvint)) == 1
@test eltype(dvint) == Int64

test_group("DataVec operations")
@test dvint+1 == DataVec([2,3,4,5], [false, false, true, false])
@test dvint.*2 == DataVec[2,4,NA,8]

test_group("DataVec to something else")
@test nafilter(dvint) == [1,2,4]
@test nareplace(dvint,0) == [1,2,0,4]
@test convert(Int, dvint2) == [5:8]
@test [i+1 | i=dvint2] == [6:9] # iterator test
@test [length(x)::Int | x=dvstr] == [3,3,0,4]
@test print_to_string(show, dvint) == "[1,2,NA,4]"





