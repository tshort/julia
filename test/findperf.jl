
# build a 10M array, then time various find operations on it
x = [zeros(10000), 1]
x = [x, x] # 20K
x = [x, x] # 40K
x = [x, x] # 80K
x = [x, x] # 160K
x = [x, x] # 320K
x = [x, x] # 640K
x = [x, x] # 1.2M
x = [x, x] # 2.4M
x = [x, x] # 4.8M
x = [x, x] # 9.6M

function f1(x)
    for i=1:10
        y = find(x)
    end
end
function f2(x)
    for i = 1:10
        y = find(x, 1.0)
    end
end
function f3(x)
    for i = 1:10
        y = find(x, y->y==1)
    end
end
function ff1(x)
    for i = 1:10
        y = findfirst(x)
    end
end
function ff2(x)
    for i = 1:10
        y = findfirst(x,1.0)
    end
end
function ff3(x)
    for i = 1:10
        y = findfirst(x,y->y==1)
    end
end
@time f1(x)
@time f1(x)
@time f2(x)
@time f2(x)
@time f3(x)
@time f3(x)
@time ff1(x)
@time ff1(x)
@time ff2(x)
@time ff2(x)
@time ff3(x)
@time ff3(x)
