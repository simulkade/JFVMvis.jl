# Makie recipes for JFVM fields.
#
# Each recipe defines a plot type plus `visualize*`/`visualize*!` functions.
# `Makie.plot!` reads the mesh's `coordinatesystem` singleton and forwards to a
# `drawcells!`/`drawvectors!` method — one per geometry. That multiple-dispatch
# fan-out is what replaced the old `if phi.domain.dimension == …` chains.
#
# A recipe cannot choose its parent axis, so the non-mutating `visualizecells`
# / `visualizecellvectors` entry points build the correct axis type
# (`Axis` | `PolarAxis` | `LScene`) before plotting.

# ---------------------------------------------------------------------------
# Axis selection
# ---------------------------------------------------------------------------

makeaxis(pos, ::AbstractCoordinateSystem; kwargs...) = Axis(pos; kwargs...)
makeaxis(pos, ::Radial2D; kwargs...)      = PolarAxis(pos; kwargs...)
makeaxis(pos, ::Cartesian3D; kwargs...)   = LScene(pos; kwargs...)
makeaxis(pos, ::Cylindrical3D; kwargs...) = LScene(pos; kwargs...)

# ===========================================================================
# Scalar cell values
# ===========================================================================

"""
    visualizecells(phi::CellValue; figure=(;), axis=(;), kwargs...)

Plot a JFVM scalar cell field. The plot kind is chosen from the mesh's
coordinate system: a line for 1D meshes, a heatmap for 2D Cartesian/cylindrical
meshes, a polar surface for `Radial2D`, and volume slices for 3D meshes.

Load a Makie backend first (e.g. `using GLMakie` or `using CairoMakie`).
Returns the `Figure`.
"""
function visualizecells end

@recipe(VisualizeCells, phi) do scene
    Attributes(
        colormap   = :viridis,
        colorrange = Makie.automatic,
    )
end

function Makie.plot!(plt::VisualizeCells)
    phi = to_value(plt[1])
    drawcells!(plt, phi.domain.coordinatesystem, phi)
    return plt
end

function visualizecells(phi::CellValue; figure = (;), axis = (;), kwargs...)
    fig = Figure(; figure...)
    ax  = makeaxis(fig[1, 1], phi.domain.coordinatesystem; axis...)
    visualizecells!(ax, phi; kwargs...)
    return fig
end

# --- per-geometry scalar drawing -------------------------------------------

drawcells!(plt, ::Union{Cartesian1D,Cylindrical1D}, phi) =
    lines!(plt, axis_x(phi), boundaryvalues(phi.value))

drawcells!(plt, ::Union{Cartesian2D,Cylindrical2D}, phi) =
    heatmap!(plt, axis_x(phi), axis_y(phi), boundaryvalues(phi.value);
             colormap = plt.colormap, colorrange = plt.colorrange)

# Radial (polar) mesh: plotted into a PolarAxis as (θ, r, value).
drawcells!(plt, ::Radial2D, phi) =
    surface!(plt, axis_y(phi), axis_x(phi), boundaryvalues(phi.value);
             colormap = plt.colormap, shading = NoShading)

# 3D Cartesian: interactive orthogonal slices through the volume.
drawcells!(plt, ::Cartesian3D, phi) =
    volumeslices!(plt, axis_x(phi), axis_y(phi), axis_z(phi),
                  boundaryvalues(phi.value); colormap = plt.colormap)

# 3D cylindrical: render the outer lateral shell (largest r) in Cartesian space,
# coloured by the field there. Full six-face rendering is a follow-up.
function drawcells!(plt, ::Cylindrical3D, phi)
    r = axis_x(phi)
    θ = axis_y(phi)
    z = axis_z(phi)
    vals = boundaryvalues(phi.value)
    X = [r[end] * cos(θj) for θj in θ, _ in z]
    Y = [r[end] * sin(θj) for θj in θ, _ in z]
    Z = [zk for _ in θ, zk in z]
    surface!(plt, X, Y, Z; color = vals[end, :, :],
             colormap = plt.colormap, shading = NoShading)
end

# ===========================================================================
# Cell vectors
# ===========================================================================

"""
    visualizecellvectors(phi::CellVector; figure=(;), axis=(;), kwargs...)

Plot a JFVM vector cell field as arrows. Requires a 2D or 3D mesh. Load a Makie
backend first. Returns the `Figure`.
"""
function visualizecellvectors end

@recipe(VisualizeCellVectors, phi) do scene
    Attributes()
end

function Makie.plot!(plt::VisualizeCellVectors)
    phi = to_value(plt[1])
    drawvectors!(plt, phi.domain.coordinatesystem, phi)
    return plt
end

function visualizecellvectors(phi::CellVector; figure = (;), axis = (;), kwargs...)
    fig = Figure(; figure...)
    ax  = makeaxis(fig[1, 1], phi.domain.coordinatesystem; axis...)
    visualizecellvectors!(ax, phi; kwargs...)
    return fig
end

# --- per-geometry vector drawing -------------------------------------------

drawvectors!(plt, ::Union{Cartesian1D,Cylindrical1D}, phi) =
    throw(ArgumentError("Vector visualization requires a 2D or 3D mesh"))

drawvectors!(plt, ::Union{Cartesian2D,Cylindrical2D}, phi) =
    arrows!(plt, phi.domain.cellcenters.x, phi.domain.cellcenters.y,
            phi.xvalue, phi.yvalue)

# Radial mesh: rotate the (r, θ) components into Cartesian for the PolarAxis.
function drawvectors!(plt, ::Radial2D, phi)
    r = phi.domain.cellcenters.x
    θ = phi.domain.cellcenters.y
    u = [phi.xvalue[i, j] * cos(θ[j]) - phi.yvalue[i, j] * sin(θ[j])
         for i in eachindex(r), j in eachindex(θ)]
    v = [phi.xvalue[i, j] * sin(θ[j]) + phi.yvalue[i, j] * cos(θ[j])
         for i in eachindex(r), j in eachindex(θ)]
    arrows!(plt, θ, r, u, v)
end

function drawvectors!(plt, ::Cartesian3D, phi)
    x = phi.domain.cellcenters.x
    y = phi.domain.cellcenters.y
    z = phi.domain.cellcenters.z
    points = vec([Point3f(xi, yj, zk) for xi in x, yj in y, zk in z])
    dirs   = vec([Vec3f(phi.xvalue[i, j, k], phi.yvalue[i, j, k], phi.zvalue[i, j, k])
                  for i in eachindex(x), j in eachindex(y), k in eachindex(z)])
    arrows!(plt, points, dirs)
end

# 3D cylindrical: place arrows at Cartesian cell centres with rotated components.
function drawvectors!(plt, ::Cylindrical3D, phi)
    r = phi.domain.cellcenters.x
    θ = phi.domain.cellcenters.y
    z = phi.domain.cellcenters.z
    points = vec([Point3f(ri * cos(θj), ri * sin(θj), zk)
                  for ri in r, θj in θ, zk in z])
    dirs = vec([Vec3f(
                    phi.xvalue[i, j, k] * cos(θ[j]) - phi.yvalue[i, j, k] * sin(θ[j]),
                    phi.xvalue[i, j, k] * sin(θ[j]) + phi.yvalue[i, j, k] * cos(θ[j]),
                    phi.zvalue[i, j, k])
                for i in eachindex(r), j in eachindex(θ), k in eachindex(z)])
    arrows!(plt, points, dirs)
end
