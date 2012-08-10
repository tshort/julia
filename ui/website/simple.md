# This is a test of Julia MD pages

## Basic code blocks

Here is a basic [Julia](http://www.julialang.org) input section. When the page is
calculated (hit the `calculate` button), the output of each Julia
section will appear below the input. Here's some example Markdown:

```julia  
randn(1)
```
Another:

```julia  output=markdown
println("## This is a second-level heading")
println("This is a normal paragraph with *emphasis*.")
println()
println("* bullet 1")
println("  * bullet 1a")
println("* bullet 2")
```

Here's another:

```julia  
plot(sin,0,10)
```
[[[Calculate]]]
