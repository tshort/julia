<link href="https://raw.github.com/tshort/julia/jlmd/ui/website/jlmd.css" rel="stylesheet" type="text/css" />

# Julia Markdown pages (Julia MD or JLMD)

Julia Markdown pages are meant to be an easy way to make simple web
interfaces or workbooks using [Julia](http://www.julialang.org).
The target audience is someone who knows Julia and wants to make web
applications probably for use on an intranet.

Markdown is an easy way to make web pages, and Julia already works
well through the web using the web REPL. Julia code blocks become
"live" when Julia Markdown pages are served through the Julia
webserver. Form elements entered using a Markdown extension for forms
are also converted to Julia variables.

Here is an example of a Julia code input section. When the page is
calculated (hit the `calculate` button), the output of each Julia
section will appear below the input. Here's some example Markdown:

***

    ## Simple function plotter
    
    alpha = ___(3.0) 
    
    [[[Calculate]]]
    
    ```julia output=markdown 
    println("## Results")
    ```
    
    ```julia
    f(x, k) = 20*sin(k * x) ./ x
    x = linspace(-5.,5,500)
    plot(x, f(x, float(alpha)))
    ```

***

When run, this will look like this:

![jlmd screen capture](https://raw.github.com/tshort/julia/jlmd/ui/website/jlmd_screenshot.png)

In the Julia block header, you can specify the result type as
`markdown` for Markdown output (also useful for HTML, since Markdown
files can contain HTML). `output` can also be `"none"` to suppress
output. 

In the example above, a text entry box is specified with `alpha` =
`___(3.0)`. In Julia, `alpha` is assigned to the value entered in the
text box (a string). The default value is "3.0".

You add a `calculate` button to a Markdown file by inserting
[[[`Calculate`]]].

The URL to read a Julia MD file is as follows:

    http://localhost:2000/jlmd.htm?jlmd-filename.md

Adjust the `jlmd-filename.md` part for different files. These files
must all be in the julia/usr/lib/julia/website/ directory (possibly
linked from julia/ui/website/).



## Examples

* example1.md --
  [live local link](http://localhost:2000/jlmd.htm?example1.md), [raw](https://raw.github.com/tshort/julia/jlmd/ui/website/example1.md),
  [github link](https://github.com/tshort/julia/blob/jlmd/ui/website/example1.md)

* example2.md --
  [live local link](http://localhost:2000/jlmd.htm?example2.md), [raw](https://raw.github.com/tshort/julia/jlmd/ui/website/example2.md),
  [github link](https://github.com/tshort/julia/blob/jlmd/ui/website/example2.md)(may
  be jumbled some on Github)


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
server, the results are plugged into the right spot. Each webpage has
it's own session. 

## Current status

Currently, things are a bit rough, but pages calculate pretty well.
The web page collects three main types of output from the webserver:
`MSG_OUTPUT_OTHER`, `MSG_OUTPUT_EVAL_RESULT`, and `MSG_OUTPUT_PLOT`.
Of these, only `MSG_OUTPUT_EVAL_RESULT` has an indicator of the
calling location. For the others, the active location is tracked. It
mostly seems to work but seems a bit kludgy. Because each webpage has
its own session, the startup time is a bit slow waiting for the Julia
process to load. It would be faster if the Julia web server always had
a spare process ready to hand off to the next session request.

