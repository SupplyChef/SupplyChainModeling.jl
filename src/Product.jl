"""
A product in the supply chain.

`zones` are the shipping zone multipliers applied to lane costs for this
product (see `Lane`'s `unit_cost`); it defaults to `[1.0]`, a single zone
with no adjustment.
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

@name_identity Product
