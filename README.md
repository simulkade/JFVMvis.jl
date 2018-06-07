# JFVMvis.jl
This is a visualization package for the [JFVM.jl](https://github.com/simulkade/JFVMv.jl) advection-diffusion solver based on [PyPlot](https://github.com/JuliaPy/PyPlot.jl). It was previously a part of JFVM itself, but I decided to move it here to make the JFVM.jl load faster.

## Installation
It is not registered yet, so clone it in Julia prompt by:
```
Pkg.clone("https://github.com/simulkade/JFVMvis.jl")
```
Then you are able to use the `visualizeCells` function to visualize the cell values created by JFVM.jl package.