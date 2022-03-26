module Extents

export Extent, extent, bounds

"""
    Extent

    Extent(; kw...)
    Extent(values::Union{Tuple,NamedTuple})

A wrapper for a `NamedTuple` or `Tuple` or tuples holding
the lower and upper bounds for each dimension of the object.

`keys(extent)` will return the dimension name Symbols, if they exist,
in the order the dimensions are used in the object. 

`values` will return a tuple of tuples: `(lowerbound, upperbound)` for each dimension.
"""
struct Extent{T<:Union{Tuple,NamedTuple}}
    bounds::T
end
Extent(; kw...) = Extent(values(kw))
Extent(args...) = Extent(args)

bounds(ext::Extent) = getfield(ext, :bounds)

function Base.getproperty(ext::Extent, key::Symbol) 
    haskey(bounds(ext), key) || throw(ErrorException("Extent has no field $key"))
    getproperty(bounds(ext), key)
end
function Base.getindex(ext::Extent, key::Symbol)
    haskey(bounds(ext), key) || throw(ErrorException("Extent has no field $key"))
    getindex(bounds(ext), key)
end
function Base.getindex(ext::Extent, i::Int)
    haskey(bounds(ext), i) || throw(ErrorException("Extent has no field $i"))
    getindex(bounds(ext), i)
end
Base.keys(ext::Extent{<:NamedTuple}) = keys(bounds(ext))
Base.keys(ext::Extent{<:Tuple}) = throw(ArgumentError("extent has no keys")) # What to do here?
Base.values(ext::Extent) = values(bounds(ext))

function Base.:(==)(a::Extent{<:NamedTuple{K1}}, b::Extent{<:NamedTuple{K2}}) where {K1, K2}
    length(K1) == length(K2) || return false
    all(map(k -> k in K1, K2)) || return false
    return all(map((k -> a[k] == b[k]), K1))
end
function Base.:(==)(a::Extent{<:Tuple}, b::Extent{<:Tuple})
    values(a) == values(b)
end
Base.:(==)(a::Extent, b::Extent) = false

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

end
