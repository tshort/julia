# Julia Markdown pages (Julia MD or JLMD)

Julia Markdown pages are meant to be an easy way to make simple web
interfaces or workbooks using [Julia](http://www.julialang.org).
Markdown is an easy way to make web pages, and Julia already works
well through the web using the web REPL. Julia code blocks become
"live" when Julia Markdown pages are served through the Julia
webserver. Form elements entered using a Markdown extension for forms
are also converted to Julia variables.

Here is an example of a Julia code input section. When the page is
calculated (hit the `calculate` button), the output of each Julia
section will appear below the input. Here's some example Markdown:

    ```julia
    a = randn(12)
    ```

Here is that code block; it can be evaluated when run
from the Julia webserver.

```julia
a = randn(12)
```

In the Julia block header, you can also specify the result type as
`markdown` for Markdown output (also useful for HTML, since Markdown
files can contain HTML). Here is an example:

    ```julia  output=markdown
    println("## This is a second-level heading")
    println("This is a normal paragraph with a word *emphasized*.")
    println()
    println("* bullet 1")
    println("  * bullet 1a")
    println("* bullet 2")
    ```

This will produce something like:

## This is a second-level heading
This is a normal paragraph with a word *emphasized*.

* bullet 1
  * bullet 1a
* bullet 2

This code block is not included here for live use. (It will look funny
on github because the output=markdown part messes things up.)

Since this readme file is Markdown, this file can be used as a Julia
MD page. Here is a form element (entered as `name` = `___`):

name = ___

```julia
name
```

You add a `calculate` button to a Markdown file by inserting
[[[`Calculate`]]].

[[[Calculate]]]

The URL to read a Julia MD file is as follows:

    http://localhost:2000/jlmd.htm?jlmd-filename.md

Adjust the `jlmd-filename.md` part for different files. These files
must all be in the julia/usr/lib/julia/website/ directory (possibly
linked from julia/ui/website/).



## Examples

* example1.md --
  [live local link](http://localhost:2000/jlmd.htm?example1.md),
  [normal link](example1.md)


## Inspiration / Ideas

* [Rpad](http://cran.r-project.org/web/packages/Rpad/index.html), [live link](http://144.58.243.47/Rpad/)

* [R Markdown](http://rstudio.org/docs/authoring/using_markdown),
  [Rpubs hosting](http://rpubs.com/)

* [IPython notebook](http://ipython.org/ipython-doc/dev/interactive/htmlnotebook.html)


## How it works

Most of the infrastructure for this was already in place for the web
REPL. 

*Markdown conversion* -- The Markdown is converted to HTML using a
modified version of Showdown. The modifications combine a github
version of [Showdown](https://github.com/coreyti/showdown/) with an
[extension for form elements](https://github.com/brikis98/wmd) and
some small additions to support the Julia MD extensions like
`[[[Calculate]]]`. Each Julia code block is wrapped with a `DIV` that
has a placeholder for results. 

*Server connection and Javascript processing* -- Communication with
the server is handled using the same infrastructure as the web REPL
(which looks like it's mostly thanks to Stephan Boyer). The file that
does most of the work is `julia/ui/website/jlmd.js`. This is adapted
from `julia/ui/website/repl.js`. Plotting is handled with D3, just
like the web REPL. One difference is that results from Julia need to
be plugged into appropriate places in the HTML file. That's done by
making a separate user\_name (and user\_id) for each Julia code block.
That way, when the appropriate evaluated results are returned from the
server, the results are plugged into the right spot.

## Current status

Currently, things are a bit rough, but pages calculate okay. The web
page collects three main types of output from the webserver:
`MSG_OUTPUT_OTHER`, `MSG_OUTPUT_EVAL_RESULT`, and `MSG_OUTPUT_PLOT`.
Of these, only `MSG_OUTPUT_EVAL_RESULT` has an indicator of the
calling location. For the others, the active location is tracked. It
mostly seems to work, but it might be fragile.

## To-Do list

Lots of things could be done. Here's a list of short-term items:

* Get a new session for each web page. (It's nice the way it is for
  debugging--you can use a web REPL to watch what the web page is
  doing.)

* Add options for Julia blocks to hide the input and/or the output.
  Maybe use global options for these.

* Add an option for a Julia block to do calculations on page load,
  normal calculation, or all (page load and normal).

* For plain output, use a fixed-point font by default.

* Find a place to output errors from the server.

* Spruce up the CSS.
