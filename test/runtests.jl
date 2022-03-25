using Extents
using Test

@testset "Extents.jl" begin
    ex_nt1 = Extent(X=(1, 2), Y=(3, 4)) 
    ex_nt2 = Extent(Y=(3, 4), X=(1, 2))
    ex_nt3 = Extent(X=(1, 2), Y=(3, 4), Z=(5.0, 6.0)) 
    ex_tuple1 = Extent((1, 2), (3, 4))

    @testset "bounds" begin
        @test bounds(ex_tuple1) == ((1, 2), (3, 4)) 
        @test bounds(ex_nt1) === (X=(1, 2), Y=(3, 4))
        @test bounds(ex_nt2) === (Y=(3, 4), X=(1, 2))
        @test bounds(ex_nt3) === (X=(1, 2), Y=(3, 4), Z=(5.0, 6.0)) 
    end

    @testset "extent" begin
        @test extent(ex_nt1) === ex_nt1
    end

    @testset "equality" begin
        @test ex_nt1 == ex_nt2
        @test ex_nt1 != ex_nt3
    end

    @testset "properties" begin
        @test keys(ex_nt1) == (:X, :Y)
        @test_throws ArgumentError keys(ex_tuple1)
        @test values(ex_nt1) == ((1, 2), (3, 4))
        @test values(ex_tuple1) == ((1, 2), (3, 4))
    end
end
