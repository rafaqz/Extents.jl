# Extents

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://rafaqz.github.io/Extents.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://rafaqz.github.io/Extents.jl/dev)
[![Build Status](https://github.com/rafaqz/Extents.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/rafaqz/Extents.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/rafaqz/Extents.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/rafaqz/Extents.jl)

Extents.jl is a small package that defines an `Extent` object that can be used by the
different Julia spatial data packages. `Extent` is a wrapper for a NamedTuple of tuples
holding the lower and upper bounds for each dimension of a object. It is used in
[GeoInterface.jl](https://github.com/JuliaGeo/GeoInterface.jl/), as the required return type
for the `extent` function, and in [DimensionalData.jl](https://github.com/rafaqz/DimensionalData.jl)
and [Rasters.jl](https://github.com/rafaqz/Rasters.jl) to subset arrays with named dimensions.

# Quick start

```julia-repl
julia> using Extents

julia> ext1 = Extent(X = (1.0, 2.0), Y = (3.0, 4.0))

julia> ext2 = Extent(X = (1.5, 2.5), Y = (3.0, 4.0))

julia> # find the dimensions

julia> keys(ext1)
(:X, :Y)

julia> # get the extent for a single dimension by name

julia> ext1.X
(1.0, 2.0)

julia> # get the underlying NamedTuple

julia> bounds(ext1)
(X = (1.0, 2.0), Y = (3.0, 4.0))

julia> # compare different extents

julia> Extents.intersects(ext1, ext2)
true

julia> Extents.intersect(ext1, ext2)
Extent(X = (1.5, 2.0), Y = (3.0, 4.0))

julia> Extents.union(ext1, ext2)
Extent(X = (1.0, 2.5), Y = (3.0, 4.0))
```
