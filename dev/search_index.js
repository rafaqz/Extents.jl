var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = Extents","category":"page"},{"location":"#Extents","page":"Home","title":"Extents","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for Extents.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [Extents]","category":"page"},{"location":"#Extents.Extent","page":"Home","title":"Extents.Extent","text":"Extent\n\nExtent(; kw...)\nExtent(bounds::NamedTuple)\n\nA wrapper for a NamedTuple of tuples holding the lower and upper bounds for each dimension of the object.\n\nkeys(extent) will return the dimension name Symbols, in the order the dimensions are used in the object.\n\nvalues(extent) will return a tuple of tuples: (lowerbound, upperbound) for each dimension.\n\nExamples\n\njulia> ext = Extent(X = (1.0, 2.0), Y = (3.0, 4.0))\nExtent(X = (1.0, 2.0), Y = (3.0, 4.0))\n\njulia> keys(ext)\n(:X, :Y)\n\njulia> values(ext)\n((1.0, 2.0), (3.0, 4.0))\n\n\n\n\n\n","category":"type"},{"location":"#Extents.extent","page":"Home","title":"Extents.extent","text":"extent(x)\n\nReturns an Extent, holding the bounds for each dimension of the object.\n\n\n\n\n\n","category":"function"},{"location":"#Extents.intersect-Tuple{Extent, Extent}","page":"Home","title":"Extents.intersect","text":"intersect(ext1::Extent, ext2::Extent; strict=false)\n\nGet the intersection of two extents as another Extent, e.g. the area covered by the shared dimensions for both extents.\n\nIf there is no intersection for any shared dimension, nothing will be returned. When strict=true, any unshared dimensions cause the function to return nothing.\n\n\n\n\n\n","category":"method"},{"location":"#Extents.intersects-Tuple{Extent, Extent}","page":"Home","title":"Extents.intersects","text":"intersects(ext1::Extent, ext2::Extent; strict=false)\n\nCheck if two Extent objects intersect.\n\nReturns true if the extents of all common dimensions share some values including just the edge values of their range.\n\nDimensions that are not shared are ignored by default, with strict=false. When strict=true, any unshared dimensions cause the function to return false.\n\nThe order of dimensions is ignored in both cases.\n\nIf there are no common dimensions, false is returned.\n\n\n\n\n\n","category":"method"},{"location":"#Extents.union-Tuple{Extent, Extent}","page":"Home","title":"Extents.union","text":"union(ext1::Extent, ext2::Extent; strict=false)\n\nGet the union of two extents, e.g. the combined extent of both objects for all dimensions.\n\nDimensions that are not shared are ignored by default, with strict=false. When strict=true, any unshared dimensions cause the function to return nothing.\n\n\n\n\n\n","category":"method"}]
}