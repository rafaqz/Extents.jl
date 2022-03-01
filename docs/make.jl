using Extents
using Documenter

DocMeta.setdocmeta!(Extents, :DocTestSetup, :(using Extents); recursive=true)

makedocs(;
    modules=[Extents],
    authors="Rafael Schouten <rafaelschouten@gmail.com>",
    repo="https://github.com/rafaqz/Extents.jl/blob/{commit}{path}#{line}",
    sitename="Extents.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://rafaqz.github.io/Extents.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/rafaqz/Extents.jl",
    devbranch="main",
)
