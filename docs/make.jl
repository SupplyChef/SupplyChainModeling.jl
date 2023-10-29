import Pkg;

using Documenter
using SupplyChainModeling

makedocs(
    sitename = "SupplyChainModeling",
    format = Documenter.HTML(),
    modules = [SupplyChainModeling],
    pages = ["index.md"]
)

deploydocs(;
    repo="https://github.com/SupplyChef/SupplyChainModeling.jl",
    devbranch = "main"
)