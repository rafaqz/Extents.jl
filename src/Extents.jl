module Extents

export Extent, extent, bounds

"""
    Extent

    Extent(; kw...)
    Extent(values::NamedTuple)

A wrapper for a `NamedTuple` of tuples holding
the lower and upper bounds for each dimension of the object.

`keys(extent)` will return the dimension name Symbols,
in the order the dimensions are used in the object. 

`values` will return a tuple of tuples: `(lowerbound, upperbound)` for each dimension.
"""
struct Extent{K,V}
    bounds::NamedTuple{K,V}
    function Extent{K,V}(bounds::NamedTuple{K,V}) where {K,V}
        bounds = map(b -> promote(b...), bounds)
        new{K,typeof(values(bounds))}(bounds)
    end
end
Extent(; kw...) = Extent(values(kw))
Extent{K}(vals::V) where {K,V} = Extent{K,V}(NamedTuple{K,V}(vals))
Extent{K1}(vals::NamedTuple{K2,V}) where {K1,K2,V} = Extent(NamedTuple{K1}(vals))
Extent(vals::NamedTuple{K,V}) where {K,V} = Extent{K,V}(vals)

bounds(ext::Extent) = getfield(ext, :bounds)

function Base.getproperty(ext::Extent, key::Symbol) 
    haskey(bounds(ext), key) || throw(ErrorException("Extent has no field $key"))
    getproperty(bounds(ext), key)
end

Base.getindex(ext::Extent, keys::NTuple{<:Any,Symbol}) = Extent{keys}(bounds(ext))
Base.getindex(ext::Extent, keys::AbstractVector{Symbol}) = ext[Tuple(keys)]
@inline function Base.getindex(ext::Extent, key::Symbol)
    haskey(bounds(ext), key) || throw(ErrorException("Extent has no field $key"))
    getindex(bounds(ext), key)
end
@inline function Base.getindex(ext::Extent, i::Int)
    haskey(bounds(ext), i) || throw(ErrorException("Extent has no field $i"))
    getindex(bounds(ext), i)
end
Base.haskey(ext::Extent, x) = haskey(bounds(ext), x)
Base.keys(ext::Extent) = keys(bounds(ext))
Base.values(ext::Extent) = values(bounds(ext))
Base.length(ext::Extent) = length(bounds(ext))
Base.iterate(ext::Extent, args...) = iterate(bounds(ext), args...)

function Base.:(==)(a::Extent{K1}, b::Extent{K2}) where {K1, K2}
    length(K1) == length(K2) || return false
    keys_match = map(K2) do k
        k in K1
    end
    all(keys_match) || return false
    values_match = map(K1) do k
        va = a[k] 
        vb = b[k]
        isnothing(va) && isnothing(vb) || va == vb
    end
    return all(values_match)
end

function Base.show(io::IO, ::MIME"text/plain", extent::Extent)
    print(io, "Extent")
    show(io, bounds(extent))
end

"""
    extent(x)

Returns an [`Extent`](@ref), holding the bounds for each dimension of the object.
"""
function extent end

extent(extent) = nothing
extent(extent::Extent) = extent

"""
    intersects(ext1::Extent, ext2::Extent)

Check if two `Extent` objects intersect. 

Returns `true` if the extents of all common dimensions share some values
including just the edge values of thier range. 

Dimensions that are not shared are ignored. The order of dimensions is also ignored.

If there are no common dimensions, `false` is returned.
"""
function intersects(ext1::Extent{K1}, ext2::Extent{K2}) where {K1, K2}
    keys = _shared_keys(ext1, ext2)
    if length(keys) == 0 
        return false # Otherwise `all` returns `true` for empty tuples
    else
        dimintersections = map(k -> _bounds_intersect(ext1[unwrap(k)], ext2[unwrap(k)]), keys)
        return all(dimintersections)
    end
end
intersects(obj1, obj2) = intersects(extent(obj1), extent(obj2))
intersects(obj1::Extent, obj2::Nothing) = false
intersects(obj1::Nothing, obj2::Extent) = false
intersects(obj1::Nothing, obj2::Nothing) = false

"""
    union(ext1::Extent, ext2::Extent)

Get the union of two extents, e.g. the combined extent of both objects
for all dimensions.
"""
function union(ext1::Extent{K1}, ext2::Extent{K2}) where {K1, K2}
    keys = _shared_keys(ext1, ext2)
    map(keys) do k
        k = unwrap(k)
        k_exts = (ext1[k], ext2[k])
        min(map(first, k_exts)...), max(map(last, k_exts)...)
    end |> Extent{map(unwrap, keys)}
end
union(obj1, obj2) = union(extent(obj1), extent(obj2))
union(obj1, obj2, obj3, objs...) = union(union(obj1, obj2), obj3, objs...)

"""
    intersect(ext1::Extent, ext2::Extent)

Get the intersect of two extents as another `Extent`, e.g. the area covered by both dimensions.
If this is empty for any dimension, `nothing` will be returned.
"""
function intersect(ext1::Extent, ext2::Extent)
    intersects(ext1, ext2) || return nothing
    keys = _shared_keys(ext1, ext2)
    values = map(keys) do k
        k = unwrap(k)
        k_exts = (ext1[k], ext2[k])
        a = max(map(first, k_exts)...)
        b = min(map(last, k_exts)...)
        (a, b)
    end
    return Extent{keys}(values)
end
intersect(obj1, obj2) = intersect(extent(obj1), extent(obj2))
intersect(obj1, obj2, obj3, objs...) = intersect(intersect(obj1, obj2), obj3, objs...)

function _bounds_intersect(b1::Tuple, b2::Tuple)
    (b1[1] <= b2[2] && b1[2] >= b2[1])
end

function _shared_keys(ext1::Extent{K1}, ext2::Extent{K2}) where {K1,K2}
    reduce(K1; init=()) do acc, k
        # Use a static Val{k} here instead of a Symbol
        # This makes union/intersect 15x faster
        k in K2 ? (acc..., Val{k}()) : acc
    end
end

unwrap(::Val{X}) where X = X

end
