"""
A product in the supply chain.
"""
struct Product
    name::String

    zones::Array{Float64, 1}

    # hash(name), precomputed once at construction. Product is used as (part
    # of) the key of nearly every Dict/Set on the simulation hot path, and
    # rehashing the name string on every lookup dominated those lookups.
    name_hash::UInt64

    function Product(name, zones=[1.0])
        return new(name, zones, hash(name))
    end
end

Base.:(==)(x::Product, y::Product) = x.name == y.name
Base.hash(x::Product, h::UInt64) = hash(x.name_hash, h)
Base.show(io::IO, x::Product) = print(io, x.name)
