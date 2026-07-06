module JFVMvis

using JFVM, Makie

# Coordinate-system singletons we dispatch on. The refactored JFVM replaced the
# old float `dimension` code with these concrete types on `MeshStructure`.
using JFVM: AbstractCoordinateSystem,
            Cartesian1D, Cylindrical1D,
            Cartesian2D, Cylindrical2D, Radial2D,
            Cartesian3D, Cylindrical3D,
            CellValue, CellVector

export visualizecells, visualizecells!,
       visualizecellvectors, visualizecellvectors!

include("boundaries.jl")
include("recipes.jl")
include("deprecated.jl")

end # module
