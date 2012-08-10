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
    dump(a)
    ```

Here is that code block; it can be evaluated when run
from the Julia webserver.

```julia
a = randn(12)
```

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

* [example1.md](http://localhost:2000/jlmd.htm?example1.md)


## Inspiration / Ideas

* [Rpad](http://cran.r-project.org/web/packages/Rpad/index.html), [live link](http://144.58.243.47/Rpad/)

* [R Markdown](http://rstudio.org/docs/authoring/using_markdown),
  [Rpubs hosting](http://rpubs.com/)

* [IPython notebook](http://ipython.org/ipython-doc/dev/interactive/htmlnotebook.html)


## How it works

*Markdown conversion* -- The Markdown is converted to HTML using a
modified version of Showdown. The modifications combine a github
version of [Showdown](https://github.com/coreyti/showdown/) with an
[extension for form elements](https://github.com/brikis98/wmd) and
some small additions to support the Julia MD extensions like
`[[[Calculate]]]`. Each Julia code block is wrapped with a `DIV` that
has a placeholder for results. 

*Server connection* -- Communication with the server is handled using
the same infrastructure as the web REPL. One difference is that
results from Julia need to be plugged into appropriate places in the
HTML file. That's done by making a separate user_name (and user_id)
for each Julia code block. That way, when the appropriate evaluated
results are returned from the server, the results are plugged into the
right spot.


## Current status

Currently, things are partly working. The main issues are:

* *Intermittent output* -- Sometimes, commands don't get through, and
   sometimes, results are lost.

* *`MSG_OUTPUT_OTHER`* -- Evaluated results should be sent back to the
        browser with type `MSG_OUTPUT_EVAL_RESULT`, but much of the
        time, they come through with `MSG_OUTPUT_OTHER`. The problem
        with that is that `MSG_OUTPUT_OTHER` doesn't have the `user_id`,
        so the results can't be put into the right spot.

* *Plotting* -- The current plot messages don't pass along the
   `user_id` associated with the caller. That means, we don't know
   where to plot something.
