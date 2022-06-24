using Extents
using Test

ex1 = Extent(X=(1, 2), Y=(3, 4))
ex2 = Extent(Y=(3, 4), X=(1, 2))
ex3 = Extent(X=(1, 2), Y=(3, 4), Z=(5.0, 6.0))

@testset "constructors" begin
    # extent per dimension is promoted to a common type
    x = Extent(X=(1, 2.0))
    @test x isa Extent{(:X,), Tuple{NTuple{2, Float64}}}
    # but different types per dimension are kept
    x = Extent(X=(1, 2), Y=(3, 4.0))
    @test x isa Extent{(:X, :Y), Tuple{NTuple{2, Int64}, NTuple{2, Float64}}}
    # each dimension needs a size two Tuple
    @test_throws ErrorException Extent()
    @test_throws MethodError Extent(X=(2,))
    @test_throws MethodError Extent(X=(2,3,4))
    # with Real components
    @test_throws MethodError Extent(X=(Complex(1), Complex(2)))
    @test_throws MethodError Extent(X=([1], [2]))
    # extents are sorted
    x = Extent(X=(2.0, 1), Y=(4,3))
    @test x.X === (1.0, 2.0)
    @test x.Y === (3, 4)
end

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
    @test ex1 == ex2
    @test ex1 != ex3
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
end

@testset "intersect/intersects" begin
    a = Extent(X=(0.1, 0.5), Y=(1.0, 2.0))
    b = Extent(X=(2.1, 2.5), Y=(3.0, 4.0), Z=(0.0, 1.0))
    c = Extent(X=(0.4, 2.5), Y=(1.5, 4.0), Z=(0.0, 1.0))
    d = Extent(A=(0.0, 1.0))
    @test Extents.intersects(a, b) == false
    @test Extents.intersect(a, b) === nothing
    @test Extents.intersects(a, c) == true
    @test Extents.intersects(a, c; strict=true) == false
    @test Extents.intersect(a, c) == Extent(X=(0.4, 0.5), Y=(1.5, 2.0))
    @test Extents.intersect(a, d) === nothing
    @test Extents.intersect(a, c; strict=true) === nothing
end
