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

Base.getindex(ext::Extent, keys::NTuple{<:Any,Symbol}) = Extent{keys}(bounds(ext)[keys])
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
    _check_keys_match(a, b) || return false
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

const STRICT_DOC = """
Dimensions that are not shared are ignored by default with `strict=false`.
When `strict=true`, any unshared dimensions cause the function to return `nothng`.
"""

const ORDER_DOC = """
The order of dimensions is ignored in all cases.
"""

"""
    contains(ext1::Extent, ext2::Extent; strict=false)

Returns `true` if the extents of all common dimensions 
of `ext1` contain `ext2`.

$STRICT_DOC

If there are no common dimensions, `false` is returned.

$ORDER_DOC
"""
function contains(ext1::Extent, ext2::Extent; strict=false)
    _bounds_comparisons(_bounds_contain, ext1, ext2, strict)
end
contains(obj1, obj2) = contains(extent(obj1), extent(obj2))
contains(obj1::Extent, obj2::Nothing) = false
contains(obj1::Nothing, obj2::Extent) = false
contains(obj1::Nothing, obj2::Nothing) = false

"""
    within(ext1::Extent, ext2::Extent; strict=false)

Returns `true` if the extents of all common dimensions 
of `ext1` are within `ext2`. 

$STRICT_DOC

If there are no common dimensions, `false` is returned.

$ORDER_DOC
"""
within(ext1, ext2; kw...) = contains(ext2, ext1; kw...)

"""
    intersects(ext1::Extent, ext2::Extent; strict=false)

Check if two `Extent` objects intersect.

Returns `true` if the extents of all common dimensions share some 
values, including just the edges of their range.

$STRICT_DOC

If there are no common dimensions with `strict=false`, `false` is returned.

$ORDER_DOC
"""
function intersects(ext1::Extent, ext2::Extent; strict=false)
    _bounds_comparisons(_bounds_intersect, ext1, ext2, strict)
end
intersects(obj1, obj2) = intersects(extent(obj1), extent(obj2))
intersects(obj1::Extent, obj2::Nothing) = false
intersects(obj1::Nothing, obj2::Extent) = false
intersects(obj1::Nothing, obj2::Nothing) = false

"""
    distjoint(ext1::Extent, ext2::Extent; strict=false)

Check if two `Extent` objects are disjoint - the inverse of `intersects`.

Returns `false` if the extents of all common dimensions share some values,
including just the edge values of their range.

$STRICT_DOC

If there are no common dimensions when `strict=false`, `true` is returned.

$ORDER_DOC
"""
function disjoint(obj1, obj2)
    s = intersects(obj1, obj2)
    return isnothing(x) ? nothing : !x
end

"""
    touches(ext1::Extent, ext2::Extent; strict=false)

Check if two `Extent` objects touch.

Returns `true` if the extents of any common dimensions share boundaries.

$STRICT_DOC

If there are no common dimensions with `strict=false`, `false` is returned.

$ORDER_DOC
"""
function touches(ext1::Extent, ext2::Extent; strict=false)
    _bounds_comparisons(_bounds_touch, ext1, ext2, strict)
end
touches(obj1, obj2) = touches(extent(obj1), extent(obj2))
touches(obj1::Extent, obj2::Nothing) = false
touches(obj1::Nothing, obj2::Extent) = false
touches(obj1::Nothing, obj2::Nothing) = false

"""
    overlaps(ext1::Extent, ext2::Extent; strict=false)

Check if two `Extent` objects touch.

Returns `true` if the extents of any common dimensions share boundaries.

$STRICT_DOC

If there are no common dimensions with `strict=false`, `false` is returned.

$ORDER_DOC
"""
function overlaps(ext1::Extent, ext2::Extent; strict=false)
    _bounds_comparisons(_bounds_overlap, ext1, ext2, strict)
end
overlaps(obj1, obj2) = overlaps(extent(obj1), extent(obj2))
overlaps(obj1::Extent, obj2::Nothing) = false
overlaps(obj1::Nothing, obj2::Extent) = false
overlaps(obj1::Nothing, obj2::Nothing) = false

"""
    equals(ext1::Extent, ext2::Extent; strict=false)

Check if two `Extent` are equal.

Returns `true` if the extents of any common dimensions share boundaries.

$STRICT_DOC

If there are no common dimensions with `strict=false`, `false` is returned.

$ORDER_DOC
"""
function equals(ext1::Extent, ext2::Extent; strict=false)
    _bounds_comparisons(_bounds_overlap, ext1, ext2, strict)
end
equals(obj1, obj2) = equals(extent(obj1), extent(obj2))
equals(obj1::Extent, obj2::Nothing) = false
equals(obj1::Nothing, obj2::Extent) = false
equals(obj1::Nothing, obj2::Nothing) = false


"""
    union(ext1::Extent, ext2::Extent; strict=false)

Get the union of two extents, e.g. the combined extent of both objects
for all dimensions.

$ORDER_DOC
"""
function union(ext1::Extent, ext2::Extent; strict=false)
    _maybe_check_keys_match(ext1, ext2, strict) || return nothing
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

$ORDER_DOC
"""
function intersection(ext1::Extent, ext2::Extent; strict=false)
    _maybe_check_keys_match(ext1, ext2, strict) || return nothing
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

"""
    buffer(ext::Extent, buff::NamedTuple)

buffer `Extent` by corresponding name-pair values supplied in `buff` NamedTuple.

# Examples
```julia-repl
julia> ext = Extent(X = (1.0, 2.0), Y = (3.0, 4.0))
Extent(X = (1.0, 2.0), Y = (3.0, 4.0))
julia> ext_buffered = Extents.buffer(ext, (X=1, Y=3))
Extent(X = (0.0, 3.0), Y = (0.0, 7.0))
```
"""
function buffer(ext::Extent{K}, buff::NamedTuple) where {K}
    bounds = map(map(Val, K)) do k
        if haskey(buff, _unwrap(k))
            map(+, ext[_unwrap(k)], (-buff[_unwrap(k)], +buff[_unwrap(k)]))
        else
            ext[_unwrap(k)]
        end
    end
    Extent{K}(bounds)
end
buffer(ext::Nothing, buff) = nothing

@deprecate inersect instersection

# Internal utils

_maybe_keys_match(ext1, ext2, strict) = !strict || _keys_match(ext1, ext2)

# Keys

_maybe_check_keys_match(ext1, ext2, strict) = !strict || _check_keys_match(ext1, ext2)

function _check_keys_match(::Extent{K1}, ::Extent{K2}) where {K1,K2}
    length(K1) == length(K2) || return false
    keys_match = map(K2) do k
        k in K1
    end |> all
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


# Bounds

function _bounds_comparisons(f, ext1, ext2, strict)
    _maybe_check_keys_match(ext1, ext2, strict) || return false
    keys = _shared_keys(ext1, ext2)
    if length(keys) == 0
        return false # Otherwise `all` returns `true` for empty tuples
    else
        bounds_comparisons = map(keys) do k
            f(ext1[_unwrap(k)], ext2[_unwrap(k)])
        end
        possible_comparisons = _skipnothing(bounds_comparisons...)
        if length(possible_comparisons) == 0
            return nothing
        else
            return all(possible_comparisons)
        end
    end
end

_bounds_intersect((min_a, max_a)::Tuple, (min_b, max_b)::Tuple) = 
    (min_a <= min_b && max_a >= min_b) || (min_a <= max_b && max_a >= max_b)

_bounds_contain((min_a, max_a)::Tuple, (min_b, max_b)::Tuple) = 
    (min_a <= min_b && max_a >= max_b)

_bounds_touch((min_a, max_a)::Tuple, (min_b, max_b)::Tuple) = 
    (min_a == max_b || max_a == min_b)

_bounds_overlap((min_a, max_a)::Tuple, (min_b, max_b)::Tuple) = 
    ((min_a < min_b && max_a > min_b) || (min_a < max_b && max_a > max_b)) && !(min_a == max_a && min_b == max_b)

_bounds_equal((min_a, max_a)::Tuple, (min_b, max_b)::Tuple) = 
    (min_a == min_b && max_a == max_b)

# Handle `nothing` bounds for all methods
for f in (:_bounds_intersect, :_bounds_contain, :_bounds_touch, :_bounds_overlap, :_bounds_equal)
    @eval begin
        $f(::Nothing, ::Tuple) = nothing 
        $f(::Tuple, ::Tuple) = nothing 
        $f(::Nothing, ::Nothing) = nothing 
    end
end

_skipnothing(v1, vals...) = (v1, _skipnothing(Base.tail(vals)...)
_skipnothing(::Nothing, vals...) = _skipnothing(Base.tail(vals)...)
_skipnothing() = ()

end
