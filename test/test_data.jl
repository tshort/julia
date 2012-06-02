test_context("Data types and NAs")

test_group("NAs")
@test length(NA) == 1
@test size(NA) == ()
#@test (3 == NA) == NA Ironically not testable!
#@test (NA == 3) == NA
#@test (NA == NA) == NA

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
@test throws_exception(DataVec[[5:8], falses(2)], Exception) 

@test DataVec(dvint) == dvint 

test_group("PooledDataVec creation")
pdvstr = PooledDataVec["one", "one", "two", "two", NA, "one", "one"]
@test typeof(pdvstr) == PooledDataVec{ASCIIString}
@test throws_exception(PooledDataVec["one", "one", 9], Exception)
@test PooledDataVec(pdvstr) == pdvstr

test_group("DataVec access")
@test dvint[1] == 1
@test isna(dvint[3])
@test dvflt[3:4] == DataVec[NA,4.0]
@test dvint[[true, false, true, false]] == DataVec[1,NA]
@test dvstr[[1,2,1,4]] == DataVec["one", "two", "one", "four"]
@test dvstr[[1,2,1,3]] == DataVec["one", "two", "one", NA] 

test_group("PooledDataVec access")
@test pdvstr[1] == "one"
@test isna(pdvstr[5])
@test pdvstr[1:3] == DataVec["one", "one", "two"]
@test pdvstr[[true, false, true, false, true, false, true]] == DataVec["one", "two", NA, "one"]
@test pdvstr[[1,3,1,2]] == DataVec["one", "two", "one", "one"]

test_group("DataVec methods")
@test size(dvint) == (4,)
@test length(dvint) == 4
@test sum(isna(dvint)) == 1
@test eltype(dvint) == Int64

test_group("PooledDataVec methods")
@test size(pdvstr) == (7,)
@test length(pdvstr) == 7
@test sum(isna(pdvstr)) == 1
@test eltype(pdvstr) == ASCIIString

test_group("DataVec operations")
@test dvint+1 == DataVec([2,3,4,5], [false, false, true, false])
@test dvint.*2 == DataVec[2,4,NA,8]
@test (dvint .== 2) == DataVec[false, true, NA, false]

test_group("PooledDataVec operations")
@test (pdvstr .== "two") == PooledDataVec[false, false, true, true, NA, false, false]

test_group("DataVec to something else")
@test all(nafilter(dvint) == [1,2,4]) # TODO: test.jl should grok all(a == b)
@test all(nareplace(dvint,0) == [1,2,0,4])
@test all(convert(Int, dvint2) == [5:8])
@test all([i+1 for i=dvint2] == [6:9]) # iterator test
@test all([length(x)::Int for x=dvstr] == [3,3,1,4])
@test sshow(dvint) == "[1,2,NA,4]"

test_group("PooledDataVec to something else")
#@test all(nafilter(pdvstr) == ["one", "one", "two", "two", "one", "one"])
#@test all(nareplace(pdvstr, "nine") == ["one", "one", "two", "two", "nine", "one", "one"])
@test all([length(i)::Int for i in pdvstr] == [3, 3, 3, 3, 1, 3, 3])
@test string(pdvstr[1:3]) == "[\"one\",\"one\",\"two\"]"

test_group("DataVec Filter and Replace")
@test naFilter(dvint) == dvint
@test naReplace(dvint,7) == dvint
@test sum(naFilter(dvint)) == 7
@test sum(naReplace(dvint,7)) == 14

test_group("PooledDataVec Filter and Replace")
@test reduce(strcat, "", naFilter(pdvstr)) == "oneonetwotwooneone"
@test reduce(strcat, "", naReplace(pdvstr,"!")) == "oneonetwotwo!oneone"

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

test_group("PooledDataVec assignment")
@test (pdvstr[2] = "three") == "three" 
@test pdvstr[2] == "three"
@test (pdvstr[[1,2]] = "two") == "two"
@test pdvstr[2] == "two"
pdvstr2 = PooledDataVec["one", "one", "two", "two"]
@test (pdvstr2[[true, false, true, false]] = "three") == "three"
@test pdvstr2[1] == "three"
@test (pdvstr2[[false, true, false, true]] = ["four", "five"]) == ["four", "five"]
@test pdvstr2[3:4] == DataVec["three", "five"]
pdvstr2 = PooledDataVec["one", "one", "two", "two"]
@test (pdvstr2[2:3] = "three") == "three"
@test pdvstr2[3:4] == DataVec["three", "two"]
@test (pdvstr2[2:3] = ["four", "five"]) == ["four", "five"]
@test pdvstr2[1:2] == DataVec["one", "four"]
pdvstr2 = PooledDataVec["one", "one", "two", "two", "three"]
@test isna(begin pdvstr2[1] = NA end)
@test all(isna(begin pdvstr2[[1,2]] = NA end))
@test all(isna(begin pdvstr2[[false, false, true, false, false]] = NA end))
@test all(isna(begin pdvstr2[4:5] = NA end))
@test all(isna(pdvstr2))

test_group("PooledDataVec replace!")
pdvstr2 = PooledDataVec["one", "one", "two", "two", "three"]
@test replace!(pdvstr2, "two", "four") == "four"
@test replace!(pdvstr2, "three", "four") == "four"
@test isna(replace!(pdvstr2, "one", NA))
@test replace!(pdvstr2, NA, "five") == "five"
@test pdvstr2 == DataVec["five", "five", "four", "four", "four"]

test_context("DataFrames")

test_group("constructors")
df1 = DataFrame({dvint, dvstr}, ["a","b","c","d"], ["Ints", "Strs"])
df2 = DataFrame({dvint, dvstr})
df3 = DataFrame({dvint})
df4 = DataFrame([1:4 1:4])
df5 = DataFrame({DataVec[1,2,3,4], dvstr})
df6 = DataFrame({dvint, dvint, dvstr}, ["a","b","c","d"], ["A", "B", "C"])

test_group("description functions")
@test nrow(df6) == 4
@test ncol(df6) == 3
@test all(names(df6) == ["A", "B", "C"])
@test all(names(df2) == [nothing, nothing])

test_group("ref")
@test df6[2,3] == "two"
@test isna(df6["c",3])
@test df6["b", "C"] == "two"
@test df6["B"] == dvint
@test ncol(df6[[2,3]]) == 2
@test nrow(df6[2,:]) == 1
@test size(df6[[1,3], [1,3]]) == (2,2)
@test size(df6[1:2, 1:2]) == (2,2)
@test size(head(df6,2)) == (2,3)
# lots more to do

test_group("show")
@test sshow(df1) == "   Ints Strs\na     1  one\nb     2  two\nc    NA   NA\nd     4 four\n"

