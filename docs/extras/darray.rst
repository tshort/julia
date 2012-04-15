Distributed Arrays
==================

.. function:: darray(init, type, dims[, distdim, procs, dist])

   Construct a distributed array. `init` is a function of three arguments that will run on each processor, and should return an `Array` holding the local data for the current processor. Its arguments are `(T,d,da)` where `T` is the element type, `d` is the dimensions of the needed local piece, and `da` is the new `DArray` being constructed (though, of course, it is not fully initialized). `type` is the element type. `dims` is the dimensions of the entire `DArray`. `distdim` is the dimension to distribute in. `procs` is a vector of processor ids to use. `dist` is a vector giving the first index of each contiguous distributed piece, such that the nth piece consists of indexes `dist[n]` through `dist[n+1]-1`. If you have a vector `v` of the sizes of the pieces, `dist` can be computed as `cumsum([1,v])`. Fortunately, all arguments after `dims` are optional.

.. function:: darray(f, A)

   Transform `DArray` `A` to another of the same type and distribution by applying function `f` to each block of `A`.

.. function:: dzeros([type, ]dims, ...)

   Construct a distrbuted array of zeros. Trailing arguments are the same as those accepted by `darray`.

.. function:: dones([type, ]dims, ...)

   Construct a distrbuted array of ones. Trailing arguments are the same as those accepted by `darray`.

.. function:: dfill(x, dims, ...)

   Construct a distrbuted array filled with value `x`. Trailing arguments are the same as those accepted by `darray`.

.. function:: drand(dims, ...)

   Construct a distrbuted uniform random array. Trailing arguments are the same as those accepted by `darray`.

.. function:: drandn(dims, ...)

   Construct a distrbuted normal random array. Trailing arguments are the same as those accepted by `darray`.

.. function:: dcell(dims, ...)

   Construct a distrbuted cell array. Trailing arguments are the same as those accepted by `darray`.

.. function:: distribute(a[, distdim])

   Convert a local array to distributed

.. function:: localize(d)

   Get the local piece of a distributed array

.. function:: changedist(d, distdim)

   Change the distributed dimension of a `DArray`

.. function:: myindexes(d)

   A tuple describing the indexes owned by the local processor

.. function:: owner(d, i)

   Get the id of the processor holding index `i` in the distributed dimension

.. function:: procs(d)

   Get the vector of processors storing pieces of `d`

.. function:: distdim(d)

   Get the distributed dimension of `d`

