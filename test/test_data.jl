test_context("Data types and NAs")

test_group("IntData")
id3 = IntData(3)
id4 = IntData(4)

@test id3 == IntData(3, false)
@test id3 + id4 == IntData(7, false)
@test id3 + 1 == id4

@test id3 + NA == IntData(3, true)
@test NA + id4 == IntData(4, true)

@test id3 * 1 == id3
@test id3 * id4 == IntData(12)

@test isna(NA) == true
@test isna(3) == false

@test isna(id3 + NA) == true
@test isna(id3 * NA) == true

test_group("IntData vectors")
ida = [1, NA, 4]
@test all(ida == [IntData(1, false), IntData(0, true), IntData(4, false)])
@test (ida+1)[2] == IntData(1, true)
@test all(isna(ida) == [false, true, false])

# TODO: these don't work, although show() mostly works. what is start(IntData) supposed to mean?!
@test prints(show, (ida[1]), "1")
@test prints(show, (ida[2]), "NA")
@test prints(show, ([IntData(0,false), IntData(1,false)]), "[1, 1]")
@test prints(show, (ida), "[1, NA, 4]")