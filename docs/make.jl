using bearingDistributions
using Documenter

makedocs(;
    modules=[bearingDistributions],
    authors="Alex Buck <alexjbuck@gmail.com> and contributors",
    repo="https://github.com/alexjbuck/bearingDistributions.jl/blob/{commit}{path}#L{line}",
    sitename="bearingDistributions.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://alexjbuck.github.io/bearingDistributions.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/alexjbuck/bearingDistributions.jl",
)
