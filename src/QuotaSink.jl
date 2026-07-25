"""
A demand point with a soft periodic quota: deliveries of a product are not capped, but any
shortfall or excess relative to the quota is penalized per unit rather than forbidden. This
generalizes supply-managed quota systems (e.g. Canadian poultry/egg/dairy production quotas)
and any other contractual periodic delivery target that a business would rather miss (at a
cost) than treat as a hard constraint.
"""
struct QuotaSink <: Node
    name::String

    location::Location

    quota::Dict{Product, Float64}
    underproduction_unit_penalty::Dict{Product, Float64}
    overproduction_unit_penalty::Dict{Product, Float64}

    # hash(name), precomputed once at construction - see Product.name_hash.
    name_hash::UInt64

    function QuotaSink(name::String, location::Location)
        return new(name, location, Dict{Product, Float64}(), Dict{Product, Float64}(), Dict{Product, Float64}(), hash(name))
    end
end

@name_identity QuotaSink

"""
    add_product!(sink::QuotaSink, product; quota, underproduction_unit_penalty=0.0, overproduction_unit_penalty=0.0)

Indicates that a `QuotaSink` has a periodic delivery quota for `product`.

The keyword arguments are:
 - `quota`: the target quantity of `product` to be delivered in each period.
 - `underproduction_unit_penalty`: the cost per unit delivered below `quota` in a period.
 - `overproduction_unit_penalty`: the cost per unit delivered above `quota` in a period.
"""
function add_product!(sink::QuotaSink, product; quota::Real, underproduction_unit_penalty::Real=0.0, overproduction_unit_penalty::Real=0.0)
    _require_nonnegative(quota, "quota")
    _require_nonnegative(underproduction_unit_penalty, "underproduction_unit_penalty")
    _require_nonnegative(overproduction_unit_penalty, "overproduction_unit_penalty")
    sink.quota[product] = quota
    sink.underproduction_unit_penalty[product] = underproduction_unit_penalty
    sink.overproduction_unit_penalty[product] = overproduction_unit_penalty
end

"""
    has_product(sink::QuotaSink, product)

Checks whether a `QuotaSink` has a quota configured for `product` (see [`add_product!`](@ref)).
"""
function has_product(sink::QuotaSink, product)
    return haskey(sink.quota, product)
end
