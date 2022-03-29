using Extents
using Test

@testset "Extents.jl" begin
    ex1 = Extent(X=(1, 2), Y=(3, 4)) 
    ex2 = Extent(Y=(3, 4), X=(1, 2))
    ex3 = Extent(X=(1, 2), Y=(3, 4), Z=(5.0, 6.0)) 

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
end
