"""
A supplier.
"""
struct Supplier <: Node
    name::String

    unit_cost::Dict{Product, Float64}

    maximum_throughput::Dict{Product, Float64}

    # Per-product ordering constraints, set through add_product!. Absent key
    # means no constraint (see get_minimum_order_quantity/get_order_multiple).
    minimum_order_quantity::Dict{Product, Float64}

    order_multiple::Dict{Product, Float64}

    location::Union{Location, Missing}

    # hash(name), precomputed once at construction - see Product.name_hash.
    name_hash::UInt64

    """
    Creates a new supplier.
    """
    function Supplier(name::String, location::Union{Location, Missing}=missing)
        return new(name, Dict{Product, Float64}(), Dict{Product, Float64}(),
                   Dict{Product, Float64}(), Dict{Product, Float64}(), location, hash(name))
    end
end

@name_identity Supplier

"""
    add_product!(supplier::Supplier, product::Product; unit_cost::Float64, maximum_throughput::Float64,
                 minimum_order_quantity::Float64, order_multiple::Float64)

Indicates that a supplier can provide a product.

The keyword arguments are:
 - `unit_cost`: the cost per unit of the product from this supplier.
 - `maximum_throughput`: the maximum number of units that can be provided in each time period.
 - `minimum_order_quantity`: the smallest quantity of this product the supplier accepts in a single order (default 0, no minimum).
   This is specific to the product and combines with `Lane`'s `minimum_quantity` (see there): an order must satisfy both.
 - `order_multiple`: orders of this product must be a whole multiple of this quantity, e.g. a case pack
   (default 1, any whole quantity). Must be a positive whole number.

"""
function add_product!(supplier::Supplier, product; unit_cost::Real, maximum_throughput::Real=Inf,
                      minimum_order_quantity::Real=0.0, order_multiple::Real=1.0)
    _require_nonnegative(unit_cost, "unit_cost")
    _require_nonnegative(maximum_throughput, "maximum_throughput")
    _require_nonnegative(minimum_order_quantity, "minimum_order_quantity")
    if order_multiple < 1 || !isinteger(order_multiple)
        throw(DomainError(order_multiple, "order_multiple must be a positive whole number"))
    end
    supplier.unit_cost[product] = unit_cost
    supplier.maximum_throughput[product] = maximum_throughput
    supplier.minimum_order_quantity[product] = minimum_order_quantity
    supplier.order_multiple[product] = order_multiple
    return nothing
end

"""
    get_minimum_order_quantity(node, product)

Gets the minimum order quantity for a product at a given node: the value set on a `Supplier` through
[`add_product!`](@ref), or 0 (no minimum) for any other node or a product without one.
"""
get_minimum_order_quantity(node, product) = 0.0
get_minimum_order_quantity(supplier::Supplier, product) = get(supplier.minimum_order_quantity, product, 0.0)

"""
    get_order_multiple(node, product)

Gets the order multiple (e.g. case pack) for a product at a given node: the value set on a `Supplier` through
[`add_product!`](@ref), or 1 (any whole quantity) for any other node or a product without one.
"""
get_order_multiple(node, product) = 1.0
get_order_multiple(supplier::Supplier, product) = get(supplier.order_multiple, product, 1.0)
