using JFVMvis
using JFVM
using CairoMakie
using Test

# A small mesh of every coordinate system, paired with a human-readable name.
scalar_meshes = [
    "Cartesian1D"   => createMesh1D(10, 1.0),
    "Cylindrical1D" => createMeshCylindrical1D(10, 1.0),
    "Cartesian2D"   => createMesh2D(8, 6, 1.0, 1.0),
    "Cylindrical2D" => createMeshCylindrical2D(8, 6, 1.0, 1.0),
    "Radial2D"      => createMeshRadial2D(8, 6, 1.0, 2π),
    "Cartesian3D"   => createMesh3D(5, 4, 3, 1.0, 1.0, 1.0),
    "Cylindrical3D" => createMeshCylindrical3D(5, 4, 3, 1.0, 2π, 1.0),
]

@testset "visualizecells — every coordinate system renders" begin
    for (name, m) in scalar_meshes
        phi = createCellVariable(m, 1.0)
        @testset "$name" begin
            # Building the figure runs the recipe's plot!, exercising the
            # coordinate-system dispatch and the drawing call.
            fig = visualizecells(phi)
            @test fig isa Figure
        end
    end
end

@testset "visualizecellvectors — 2D and 3D" begin
    vector_meshes = filter(p -> !occursin("1D", first(p)), scalar_meshes)
    for (name, m) in vector_meshes
        u = createCellVector(m, 1.0)
        @testset "$name" begin
            fig = visualizecellvectors(u)
            @test fig isa Figure
        end
    end
end

@testset "visualizecellvectors rejects 1D meshes" begin
    u = createCellVector(createMesh1D(10, 1.0), 1.0)
    @test_throws ArgumentError visualizecellvectors(u)
end

@testset "CairoMakie can save a 1D and 2D figure" begin
    mktempdir() do dir
        fig1 = visualizecells(createCellVariable(createMesh1D(10, 1.0), 1.0))
        fig2 = visualizecells(createCellVariable(createMesh2D(8, 6, 1.0, 1.0), 1.0))
        @test (save(joinpath(dir, "line.png"), fig1); true)
        @test (save(joinpath(dir, "heatmap.png"), fig2); true)
    end
end
