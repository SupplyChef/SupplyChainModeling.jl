"""
A supplier.
"""
struct Supplier <: Node
    name::String

    unit_cost::Dict{Product, Float64}

    maximum_throughput::Dict{Product, Float64}

    location::Union{Location, Missing}

    """
    Creates a new supplier.
    """
    function Supplier(name::String, location::Location)
        return new(name, Dict{Product, Float64}(), Dict{Product, Float64}(), location)
    end

    """
    Creates a new supplier.
    """
    function Supplier(name::String)
        return new(name, Dict{Product, Float64}(), Dict{Product, Float64}(), missing)
    end
end

Base.:(==)(x::Supplier, y::Supplier) = x.name == y.name 
Base.hash(x::Supplier, h::UInt64) = hash(x.name, h)
Base.show(io::IO, x::Supplier) = print(io, x.name)

"""
    add_product!(supplier::Supplier, product::Product; unit_cost::Float64, maximum_throughput::Float64)

Indicates that a supplier can provide a product.

The keyword arguments are:
 - `unit_cost`: the cost per unit of the product from this supplier.
 - `maximum_throughput`: the maximum number of units that can be provided in each time period.

"""
function add_product!(supplier::Supplier, product; unit_cost::Real, maximum_throughput::Real=Inf)
    supplier.unit_cost[product] = unit_cost
    supplier.maximum_throughput[product] = maximum_throughput
end