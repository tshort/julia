Julia Documentation README
==========================

Julia's documentation is written in reStructuredText, a good reference for which
is the [Documenting Python](http://docs.python.org/devguide/documenting.html)
chapter of the Python Developer's Guide.


Building the documentation
--------------------------

The documentation is built using [Sphinx](http://sphinx.pocoo.org/).

    $ make helpdb.jl
    $ make html


File layout
-----------

    conf.py             Sphinx configuration
    helpdb.jl           REPL help database
    sphinx/             Sphinx extensions and plugins
    sphinx/jlhelp.py    Sphinx plugin to build helpdb.jl


