"""
A supplier.
"""
struct Supplier <: Node
    name::String

    unit_cost::Dict{Product, Float64}

    maximum_throughput::Dict{Product, Float64}

    location::Union{Location, Missing}

    # hash(name), precomputed once at construction - see Product.name_hash.
    name_hash::UInt64

    """
    Creates a new supplier.
    """
    function Supplier(name::String, location::Union{Location, Missing}=missing)
        return new(name, Dict{Product, Float64}(), Dict{Product, Float64}(), location, hash(name))
    end
end

@name_identity Supplier

"""
    add_product!(supplier::Supplier, product::Product; unit_cost::Float64, maximum_throughput::Float64)

Indicates that a supplier can provide a product.

The keyword arguments are:
 - `unit_cost`: the cost per unit of the product from this supplier.
 - `maximum_throughput`: the maximum number of units that can be provided in each time period.

"""
function add_product!(supplier::Supplier, product; unit_cost::Real, maximum_throughput::Real=Inf)
    _require_nonnegative(unit_cost, "unit_cost")
    _require_nonnegative(maximum_throughput, "maximum_throughput")
    supplier.unit_cost[product] = unit_cost
    supplier.maximum_throughput[product] = maximum_throughput
end