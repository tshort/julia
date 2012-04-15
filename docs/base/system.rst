System
======

.. function:: system("command")

   Run a shell command.

.. function:: gethostname()

   Get the local machine's host name.

.. function:: getipaddr()

   Get the IP address of the local machine, as a string of the form "x.x.x.x".

.. function:: getcwd()

   Get the current working directory.

.. function:: setcwd("dir")

   Set the current working directory. Returns the new current directory.

.. function:: getpid()

   Get julia's process ID.

.. function:: time()

   Get the time in seconds since the epoch, with fairly high resolution.

.. function:: tic()

   Set a timer to be read by the next call to `toc` or `toq`. The macro call `@time expr` can also be used to time evaluation.

.. function:: toc()

   Print and return the time elapsed since the last `tic`

.. function:: toq()

   Return, but do not print, the time elapsed since the last `tic`

.. function:: EnvHash()

   A singleton of this type, `ENV`, provides a hash table interface to environment variables.

.. function:: dlopen(libfile)

   Load a shared library, returning an opaque handle

.. function:: dlsym(handle, sym)

   Look up a symbol from a shared library handle

