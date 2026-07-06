# JFVMvis.jl — Major Refactoring Plan

## Goal

Move from a Julia-0.6, PyPlot-based package with two monolithic `if/elseif`
functions branching on a float `dimension` code, to a **Julia 1.x, Makie-native**
package built on **recipes** and **multiple dispatch on the coordinate-system
type**.

Decisions (locked in):
- **Plotting ecosystem:** Makie recipes.
- **Coupling:** hard dependency on `Makie` (core). Users load a backend
  (`GLMakie` for interactive, `CairoMakie` for vector output).

## What changed upstream (the forcing function)

`MeshStructure` is now `MeshStructure{CS<:AbstractCoordinateSystem, T<:Real}`
with a `coordinatesystem::CS` field. `CS` is one of seven **singleton types**.
That is what we dispatch on:

| Old float code | New coordinate type | Plot |
|---|---|---|
| `1`   | `Cartesian1D`   | `lines!` |
| `1.5` | `Cylindrical1D` | `lines!` |
| `2`   | `Cartesian2D`   | `heatmap!` / `surface!` |
| `2.5` | `Cylindrical2D` | `heatmap!` (r–z plane) |
| `2.8` | `Radial2D`      | `PolarAxis` + `surface!` |
| `3`   | `Cartesian3D`   | `volume!` / `volumeslices!` |
| `3.2` | `Cylindrical3D` | coord-transform → `surface!`/`volume!` |

`CellValue{T,N,A}` / `CellVector` / `FaceValue` are now array-parametrized, so
we can also dispatch on `N` to distinguish 1D/2D/3D storage.

## Phase 0 — Environment & metadata
- Delete `REQUIRE` (legacy Pkg system).
- Rewrite `Project.toml`: Julia 1.10+, `[deps]` Makie + JFVM, `[compat]`,
  `[extras]`/`[targets]` for Test + CairoMakie. Bump to `0.1.0`.

## Phase 1 — Module skeleton
`src/JFVMvis.jl`: `using JFVM, Makie`, import coordinate types, export
lowercase `visualizecells(!)` / `visualizecellvectors(!)`, include the new files.

## Phase 2 — Recipes (core of the refactor)
`src/recipes.jl`: `@recipe(VisualizeCells, phi)` and
`@recipe(VisualizeCellVectors, phi)`. `Makie.plot!` extracts
`phi.domain.coordinatesystem` and calls `_drawcells!(p, cs, phi)` — one method
per coordinate type, replacing the `if/elseif` chains. Convenience wrappers
build the correct axis (`Axis` | `PolarAxis` | `LScene`) since a recipe can't
force its parent axis type.

## Phase 3 — Ghost-cell handling (`src/boundaries.jl`)
Extract the halo-averaging + augmented-coordinate logic into shared,
dimension-generic helpers. Modernize: `squeeze`→`dropdims`, `cos(A)`→`cos.(A)`,
`repmat`→`repeat`, drop hand-rolled normalization in favor of Makie
`colorrange`. Evaluate whether Makie's native cell-centered handling lets us
delete the padding entirely.

## Phase 4 — 3D via Makie (delete Mayavi)
Remove all `mayavis.*` blocks and the `3.2` hacks. Reimplement `Cartesian3D`
with `volumeslices!`/`volume!`; `Cylindrical3D` via `(r,θ,z)→(x,y,z)` transform.

## Phase 5 — Back-compat & polish
`@deprecate visualizeCells visualizecells`, `@deprecate visualizeCellVectors
visualizecellvectors`; add docstrings.

## Phase 6 — Tests
`test/runtests.jl`: with CairoMakie, build a small mesh of each coordinate type,
call the visualizers, assert `save(io, fig)` succeeds (headless smoke test of
every dispatch branch).

## Phase 7 — Docs
Update `README.md` (new usage, fix `JFVMv.jl` typo link); rewrite `CLAUDE.md`
for the recipe/dispatch architecture.

## Open items
1. Makie core (recommended) vs. bundled backend.
2. 3D style: `volumeslices!` (recommended) vs `volume!`/`contour!`.
3. Reactivity depth: read-once (`to_value`) now; full Observable updates later.

## Verification note
JFVM + a Makie backend are not installed in this dev environment, so end-to-end
rendering can't be exercised here. Files are parse-checked; the polar (`Radial2D`)
and 3D paths in particular should be run against a live Makie backend via
`] test` before release.
