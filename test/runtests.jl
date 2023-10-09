using Extents
using Test

ex1 = Extent(X=(1, 2), Y=(3, 4))
ex2 = Extent(Y=(3, 4), X=(1, 2))
ex3 = Extent(X=(1, 2), Y=(3, 4), Z=(5.0, 6.0))

@testset "getindex" begin
    @test ex3[1] == ex3[:X] == (1, 2)
    @test ex3[[:X, :Z]] == ex3[(:X, :Z)] == Extent{(:X, :Z)}(((1, 2), (5.0, 6.0)))
end

@testset "getproperty" begin
    @test ex3.X == (1, 2)
end

@testset "bounds" begin
    @test bounds(ex1) === (X=(1, 2), Y=(3, 4))
    @test bounds(ex2) === (Y=(3, 4), X=(1, 2))
    @test bounds(ex3) === (X=(1, 2), Y=(3, 4), Z=(5.0, 6.0))
end

@testset "extent" begin
    @test extent(ex1) === ex1
end

@testset "equality" begin
    @test ex1 == ex1
    @test ex1 == ex2
    @test ex1 != ex3
end

@testset "isapprox" begin
    ex4 = Extent(X=(1.00000000000001, 2), Y=(3, 4))
    ex5 = Extent(X=(1.1, 2), Y=(3, 4))
    @test ex1 ≈ ex1
    @test ex1 ≈ ex2
    @test ex1 ≈ ex4
    @test isapprox(ex1, ex5; atol=0.11)
end

@testset "properties" begin
    @test keys(ex1) == (:X, :Y)
    @test values(ex1) == ((1, 2), (3, 4))
end

@testset "union" begin
    a = Extent(X=(0.1, 0.5), Y=(1.0, 2.0))
    b = Extent(X=(2.1, 2.5), Y=(3.0, 4.0), Z=(0.0, 1.0))
    c = Extent(Z=(0.2, 2.0))
    @test Extents.union(a, b) == Extent(X=(0.1, 2.5), Y=(1.0, 4.0))
    @test Extents.union(a, b; strict=true) === nothing
    @test Extents.union(a, c) === nothing
    @test Extents.union(a, nothing) === a
    @test Extents.union(nothing, a) === a
    @test Extents.union(nothing, nothing) === nothing
end

@testset "intersection/intersects" begin
    a = Extent(X=(0.1, 0.5), Y=(1.0, 2.0))
    b = Extent(X=(2.1, 2.5), Y=(3.0, 4.0), Z=(0.0, 1.0))
    c = Extent(X=(0.4, 2.5), Y=(1.5, 4.0), Z=(0.0, 1.0))
    d = Extent(A=(0.0, 1.0))
    @test Extents.intersects(a, b) == false
    @test Extents.intersection(a, b) === nothing
    @test Extents.intersects(a, c) == true
    @test Extents.intersects(a, c; strict=true) == false
    @test Extents.intersection(a, c) == Extent(X=(0.4, 0.5), Y=(1.5, 2.0))
    @test Extents.intersection(a, d) === nothing
    @test Extents.intersection(a, c; strict=true) === nothing
    @test Extents.intersection(a, nothing) === nothing
    @test Extents.intersection(nothing, nothing) === nothing
    @test Extents.intersection(nothing, b) === nothing
end

@testset "buffer" begin
    a = Extent(X=(0.1, 0.5), Y=(1.0, 2.0))
    b = Extent(Lat=(0.1, 0.5), Lon=(1.0, 2.0), Elev=(-3, 4))
    @test Extents.buffer(a,(H=0,)) == a
    @test Extents.buffer(a, (X=1, Y=2)) == Extent(X=(-0.9, 1.5), Y=(-1.0, 4.0))
    @test Extents.buffer(b, (Lat=2, Lon=1)) == Extent(Lat=(-1.9, 2.5), Lon=(0.0, 3.0), Elev=(-3, 4))
end
