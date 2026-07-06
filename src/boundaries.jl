# Ghost-cell handling shared across geometries.
#
# JFVM stores cell fields with a one-cell boundary halo, so `phi.value` has size
# `Nx+2` (× `Ny+2` × `Nz+2`). For plotting we want:
#   * coordinate vectors that run from the first face centre, through the cell
#     centres, to the last face centre (length `Nx+2`), and
#   * a value array whose halo cells hold the *boundary face* values (the mean of
#     the ghost cell and its neighbour) rather than the raw ghost values.
#
# These helpers replace the inline, hand-unrolled averaging that the PyPlot
# version repeated in every branch.

"""Augmented coordinate vector: first face centre, cell centres, last face centre."""
augmentedaxis(centers::AbstractVector, faces::AbstractVector) =
    vcat(faces[begin], centers, faces[end])

axis_x(phi) = augmentedaxis(phi.domain.cellcenters.x, phi.domain.facecenters.x)
axis_y(phi) = augmentedaxis(phi.domain.cellcenters.y, phi.domain.facecenters.y)
axis_z(phi) = augmentedaxis(phi.domain.cellcenters.z, phi.domain.facecenters.z)

# --- boundary values: replace halo cells with boundary-face averages ----------

"""1D: average each end ghost cell with its interior neighbour."""
function boundaryvalues(v::AbstractVector)
    out = collect(float.(v))
    out[begin] = 0.5 * (v[begin] + v[begin+1])
    out[end]   = 0.5 * (v[end]   + v[end-1])
    return out
end

"""2D: average the four edge halos, then fill corners from their neighbours."""
function boundaryvalues(v::AbstractMatrix)
    out = collect(float.(v))
    @views out[:, begin] .= 0.5 .* (v[:, begin] .+ v[:, begin+1])
    @views out[:, end]   .= 0.5 .* (v[:, end]   .+ v[:, end-1])
    @views out[begin, :] .= 0.5 .* (v[begin, :] .+ v[begin+1, :])
    @views out[end, :]   .= 0.5 .* (v[end, :]   .+ v[end-1, :])
    out[begin, begin] = out[begin, begin+1]
    out[begin, end]   = out[begin, end-1]
    out[end, begin]   = out[end, begin+1]
    out[end, end]     = out[end, end-1]
    return out
end

"""3D: average the six face halos of the volume."""
function boundaryvalues(v::AbstractArray{<:Any,3})
    out = collect(float.(v))
    @views out[begin, :, :] .= 0.5 .* (v[begin, :, :] .+ v[begin+1, :, :])
    @views out[end, :, :]   .= 0.5 .* (v[end, :, :]   .+ v[end-1, :, :])
    @views out[:, begin, :] .= 0.5 .* (v[:, begin, :] .+ v[:, begin+1, :])
    @views out[:, end, :]   .= 0.5 .* (v[:, end, :]   .+ v[:, end-1, :])
    @views out[:, :, begin] .= 0.5 .* (v[:, :, begin] .+ v[:, :, begin+1])
    @views out[:, :, end]   .= 0.5 .* (v[:, :, end]   .+ v[:, :, end-1])
    return out
end
