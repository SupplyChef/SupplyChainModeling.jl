"""
An ad-valorem tariff applied to a product moving from one customs territory
to another.

`rate` is the fraction (e.g. `0.25` for 25%) applied to the product's
declared value when a unit crosses from `origin_country` into
`destination_country`. `product` is `nothing` to mean "every product" moving
between the two countries.

Countries are matched against `Location.country`; a `Lane` whose origin and
destination resolve to the same country (or where either side has no
country set) never incurs a tariff.
"""
struct Tariff
    origin_country::String
    destination_country::String
    product::Union{Nothing, Product}
    rate::Float64

    function Tariff(origin_country::String, destination_country::String, rate::Real; product::Union{Nothing, Product}=nothing)
        _require_nonnegative(rate, "rate")
        return new(origin_country, destination_country, product, rate)
    end
end
