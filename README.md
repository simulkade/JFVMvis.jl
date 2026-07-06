# JFVMvis.jl

This is a visualization package for the [JFVM.jl](https://github.com/simulkade/JFVM.jl)
finite-volume advection-diffusion solver, built on
[Makie](https://docs.makie.org). It was previously part of JFVM itself, but was
moved here to keep JFVM.jl fast to load.

The plot type is chosen automatically from the mesh's coordinate system: a line
for 1D meshes, a heatmap for 2D Cartesian/cylindrical meshes, a polar surface
for `Radial2D`, and volume slices for 3D meshes.

## Installation

Not registered yet, so add it by URL from the Julia REPL package mode (`]`):

```julia
pkg> add https://github.com/simulkade/JFVMvis.jl
```

## Usage

Load a Makie backend alongside JFVMvis — `GLMakie` for interactive windows, or
`CairoMakie` for publication-quality vector/PNG output — then call
`visualizecells` on a `CellValue` or `visualizecellvectors` on a `CellVector`:

```julia
using JFVM, JFVMvis
using GLMakie            # or: using CairoMakie

m   = createMesh2D(50, 50, 1.0, 1.0)
phi = createCellVariable(m, 0.0)
visualizecells(phi)                      # heatmap
visualizecells(phi; colormap = :magma)   # keyword args are forwarded to Makie

u = createCellVector(m, 1.0)
visualizecellvectors(u)                  # quiver / arrows
```

Both functions return a Makie `Figure`, so you can `save("field.png", fig)` or
compose it into a larger layout. Makie [recipes](https://docs.makie.org/stable/documentation/recipes/)
`visualizecells!` / `visualizecellvectors!` are also available for plotting into
an existing axis.
