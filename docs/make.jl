using Extents
using Documenter
using Documenter.Remotes: GitHub

DocMeta.setdocmeta!(Extents, :DocTestSetup, :(using Extents))

makedocs(;
    modules=[Extents],
    authors="Rafael Schouten <rafaelschouten@gmail.com>",
    repo=GitHub("rafaqz/Extents.jl"),
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
