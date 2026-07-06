# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

JFVMvis.jl is a small **Makie-based** visualization package for
[JFVM.jl](https://github.com/simulkade/JFVM.jl), a finite-volume
advection-diffusion solver. It renders `CellValue` (scalar) and `CellVector`
(vector) fields. It was split out of JFVM so that JFVM loads faster.

Targets **Julia 1.10+**. `Makie` is a hard dependency (its recipes register on
load); the user additionally loads a backend — `GLMakie` (interactive) or
`CairoMakie` (vector/PNG, also used in tests).

## Commands

- Run tests: `julia --project -e 'using Pkg; Pkg.test()'` (or `] test` in the REPL).
- Parse-check a file without installing deps: `julia -e 'Meta.parseall(read(ARGS[1],String))' src/recipes.jl`.

## Architecture: dispatch on the coordinate-system type

The refactored JFVM replaced its old float `dimension` code with a type on the
mesh: `MeshStructure{CS<:AbstractCoordinateSystem,T}` carries a
`coordinatesystem::CS` field, where `CS` is one of seven **singleton types**:
`Cartesian1D`, `Cylindrical1D`, `Cartesian2D`, `Cylindrical2D`, `Radial2D`,
`Cartesian3D`, `Cylindrical3D`. All plotting dispatches on that type via multiple
dispatch — there are no `if dimension == …` branches anymore.

Source files (all under `src/`, included by `JFVMvis.jl` in this order):

- **`boundaries.jl`** — ghost-cell helpers. JFVM stores fields with a one-cell
  halo (`phi.value` is `Nx+2 × …`). `augmentedaxis`/`axis_x/y/z` build coordinate
  vectors running face-centre → cell-centres → face-centre. `boundaryvalues` has
  one method per array rank (vector/matrix/3-array) that replaces the halo cells
  with boundary-face averages. Shared by every geometry.
- **`recipes.jl`** — the core. Two Makie recipes, `VisualizeCells` and
  `VisualizeCellVectors` (generating `visualizecells(!)` /
  `visualizecellvectors(!)`). Each recipe's `Makie.plot!` reads
  `phi.domain.coordinatesystem` and forwards to a `drawcells!` / `drawvectors!`
  method — **one method per coordinate type**. That fan-out is where geometry
  behavior lives; add or change a geometry there.
- **`deprecated.jl`** — `@deprecate` aliases mapping the old CamelCase
  `visualizeCells` / `visualizeCellVectors` to the new lowercase names.

## Two things to know before editing

- **A recipe cannot choose its parent axis.** So the non-mutating
  `visualizecells` / `visualizecellvectors` entry points build the right axis
  first via `makeaxis(pos, coordsys)` — `Axis` for Cartesian/cylindrical,
  `PolarAxis` for `Radial2D`, `LScene` for 3D — then plot into it. If you add a
  geometry that needs a special axis, add a `makeaxis` method too.
- **The `Radial2D` and both 3D paths are the least battle-tested.** They use
  Makie APIs (`PolarAxis` + `surface!`, `volumeslices!`, Cartesian coordinate
  transforms) that this dev environment cannot execute (JFVM and a Makie backend
  aren't installed here — only parse-checking is possible). Verify them against a
  live backend with `] test` before trusting changes. `Cylindrical3D` currently
  renders only the outer lateral shell; full six-face rendering is a known
  follow-up.

## History

Everything used to be two monolithic PyPlot functions in `src/VisualizePDE.jl`
that branched on a float `dimension` code and contained large blocks of dead
Mayavi (`mayavis.*`) code. That file and the PyPlot/Mayavi approach are gone; see
`REFACTOR.md` for the migration plan and remaining open items.
