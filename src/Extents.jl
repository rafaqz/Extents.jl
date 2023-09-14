module Extents

export Extent, extent, bounds

## DO NOT export anything else ##

"""
    Extent

    Extent(; kw...)
    Extent(bounds::NamedTuple)

A wrapper for a `NamedTuple` of tuples holding
the lower and upper bounds for each dimension of the object.

`keys(extent)` will return the dimension name Symbols,
in the order the dimensions are used in the object.

`values(extent)` will return a tuple of tuples: `(lowerbound, upperbound)` for each
dimension.

# Examples
```julia-repl
julia> ext = Extent(X = (1.0, 2.0), Y = (3.0, 4.0))
Extent(X = (1.0, 2.0), Y = (3.0, 4.0))

julia> keys(ext)
(:X, :Y)

julia> values(ext)
((1.0, 2.0), (3.0, 4.0))
```
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

function Base.isapprox(a::Extent{K1}, b::Extent{K2}; kw...) where {K1,K2}
    _keys_match(a, b) || return false
    values_match = map(K1) do k
        bounds_a = a[k]
        bounds_b = b[k]
        if isnothing(bounds_a) && isnothing(bounds_b) 
            true
        else
            map(bounds_a, bounds_b) do val_a, val_b
                isapprox(val_a, val_b; kw...)
            end |> all
        end
    end
    return all(values_match)
end

function Base.:(==)(a::Extent{K1}, b::Extent{K2}) where {K1,K2}
    _keys_match(a, b) || return false
    values_match = map(K1) do k
        bounds_a = a[k]
        bounds_b = b[k]
        isnothing(bounds_a) && isnothing(bounds_b) || bounds_a == bounds_b
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
    intersects(ext1::Extent, ext2::Extent; strict=false)

Check if two `Extent` objects intersect.

Returns `true` if the extents of all common dimensions share some values
including just the edge values of their range.

Dimensions that are not shared are ignored by default, with `strict=false`.
When `strict=true`, any unshared dimensions cause the function to return `false`.

The order of dimensions is ignored in both cases.

If there are no common dimensions, `false` is returned.
"""
function intersects(ext1::Extent, ext2::Extent; strict=false)
    _maybe_keys_match(ext1, ext2, strict) || return false
    keys = _shared_keys(ext1, ext2)
    if length(keys) == 0
        return false # Otherwise `all` returns `true` for empty tuples
    else
        dimintersections = map(keys) do k
            _bounds_intersect(ext1[_unwrap(k)], ext2[_unwrap(k)])
        end
        return all(dimintersections)
    end
end
intersects(obj1, obj2) = intersects(extent(obj1), extent(obj2))
intersects(obj1::Extent, obj2::Nothing) = false
intersects(obj1::Nothing, obj2::Extent) = false
intersects(obj1::Nothing, obj2::Nothing) = false

"""
    union(ext1::Extent, ext2::Extent; strict=false)

Get the union of two extents, e.g. the combined extent of both objects
for all dimensions.

Dimensions that are not shared are ignored by default, with `strict=false`.
When `strict=true`, any unshared dimensions cause the function to return `nothing`.
"""
function union(ext1::Extent, ext2::Extent; strict=false)
    _maybe_keys_match(ext1, ext2, strict) || return nothing
    keys = _shared_keys(ext1, ext2)
    if length(keys) == 0
        return nothing
    else
        values = map(keys) do k
            k = _unwrap(k)
            k_exts = (ext1[k], ext2[k])
            a = min(map(first, k_exts)...)
            b = max(map(last, k_exts)...)
            (a, b)
        end
        return Extent{map(_unwrap, keys)}(values)
    end
end
union(obj1::Extent, ::Nothing) = obj1
union(::Nothing, obj2::Extent) = obj2
union(::Nothing, ::Nothing) = nothing
union(obj1, obj2) = union(extent(obj1), extent(obj2))
union(obj1, obj2, obj3, objs...) = union(union(obj1, obj2), obj3, objs...)

"""
    intersection(ext1::Extent, ext2::Extent; strict=false)

Get the intersection of two extents as another `Extent`, e.g.
the area covered by the shared dimensions for both extents.

If there is no intersection for any shared dimension, `nothing` will be returned.
When `strict=true`, any unshared dimensions cause the function to return `nothing`.
"""
function intersection(ext1::Extent, ext2::Extent; strict=false)
    _maybe_keys_match(ext1, ext2, strict) || return nothing
    intersects(ext1, ext2) || return nothing
    keys = _shared_keys(ext1, ext2)
    values = map(keys) do k
        k = _unwrap(k)
        k_exts = (ext1[k], ext2[k])
        a = max(map(first, k_exts)...)
        b = min(map(last, k_exts)...)
        (a, b)
    end
    return Extent{map(_unwrap, keys)}(values)
end
intersection(obj1::Extent, obj2::Nothing) = nothing
intersection(obj1::Nothing, obj2::Extent) = nothing
intersection(obj1::Nothing, obj2::Nothing) = nothing
intersection(obj1, obj2) = intersection(extent(obj1), extent(obj2))
intersection(obj1, obj2, obj3, objs...) = intersection(intersection(obj1, obj2), obj3, objs...)

@deprecate inersect instersection

# Internal utils

_maybe_keys_match(ext1, ext2, strict) = !strict || _keys_match(ext1, ext2)

function _keys_match(::Extent{K1}, ::Extent{K2}) where {K1,K2}
    length(K1) == length(K2) || return false
    keys_match = map(K2) do k
        k in K1
    end |> all
end

function _bounds_intersect(b1::Tuple, b2::Tuple)
    (b1[1] <= b2[2] && b1[2] >= b2[1])
end

# _shared_keys uses a static `Val{k}` instead of a `Symbol` to
# represent keys, because constant propagation fails through `reduce`
# meaning most of the time of `union` or `intersect` is doing the `Symbol` lookup.
# So we help the compiler out a little by doing manual constant propagation.
# We know K1 and K2 at compile time, and wrapping them in `Val{k}() maintains
# that through reduce. This makes union/intersect 15x faster, at ~10ns.
function _shared_keys(ext1::Extent{K1}, ext2::Extent{K2}) where {K1,K2}
    reduce(K1; init=()) do acc, k
        k in K2 ? (acc..., Val{k}()) : acc
    end
end

_unwrap(::Val{X}) where {X} = X

end
