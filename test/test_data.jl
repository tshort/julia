test_context("Data types and NAs")

test_group("DataVec creation")
# why can't I put @test before these?
dvint = DataVec[1, 2, NA, 4]
dvint2 = DataVec([5:8])
dvflt = DataVec[1.0, 2, NA, 4]
dvstr = DataVec["one", "two", NA, "four"]

@test typeof(dvint) == DataVec{Int64}
@test typeof(dvint2) == DataVec{Int64}
@test typeof(dvflt) == DataVec{Float64}
@test typeof(dvstr) == DataVec{ASCIIString}
#@test throws(DataVec, ([5:8], falses(2)), Exception) not currently working test type

@test DataVec(dvint) == dvint 

test_group("DataVec access")
@test dvint[1] == 1
@test dvint[3] == NA
@test dvflt[3:4] == DataVec[NA,4.0]
@test dvint[[true, false, true, false]] == DataVec[1,NA]
@test dvstr[[1,2,1,4]] == DataVec["one", "two", "one", "four"]
@test dvstr[[1,2,1,3]] == DataVec["one", "two", "one", NA] 

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

test_group("DataVec Filter and Replace")
@test naFilter(dvint) == dvint
@test naReplace(dvint,7) == dvint
@test sum(naFilter(dvint)) == 7
@test sum(naReplace(dvint,7)) == 14

test_group("DataVec assignment")
assigntest = DataVec[1, 2, NA, 4]
assigntest[1] = 8
@test assigntest == DataVec[8, 2, NA, 4]
assigntest[1:2] = 9
@test assigntest == DataVec[9, 9, NA, 4]
assigntest[[1,3]] = 10
@test assigntest == DataVec[10, 9, 10, 4]
assigntest[[true, false, true, true]] = 11
@test assigntest == DataVec[11, 9, 11, 11]
assigntest[1:2] = [12,13]
@test assigntest == DataVec[12, 13, 11, 11]
assigntest[[1,4]] = [14,15]
@test assigntest == DataVec[14, 13, 11, 15]
assigntest[[true,false,true,false]] = [16,17]
@test assigntest == DataVec[16, 13, 17, 15]
assigntest[1] = NA
@test assigntest == DataVec[NA, 13, 17, 15]
assigntest[[1,2]] = NA
@test assigntest == DataVec[NA, NA, 17, 15]
assigntest[[true,false,true,false]] = NA
@test assigntest == DataVec[NA, NA, NA, 15]
assigntest[1] = 1
assigntest[2:4] = NA
@test assigntest == DataVec[1, NA, NA, NA]

test_context("DataFrames")

test_group("constructors")
df1 = DataFrame({dvint, dvstr}, ["a","b","c","d"], ["Ints", "Strs"])
df2 = DataFrame({dvint, dvstr})
df3 = DataFrame({dvint})
#df4 = DataFrame(1:4)
#df5 = DataFrame({1:4, dvstr})
df6 = DataFrame({dvint, dvint, dvstr}, ["a","b","c","d"], ["A", "B", "C"])

test_group("description functions")

test_group("ref")

test_group("show")

