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

    # Set through set_payment_terms! (a Ref so the struct itself stays immutable).
    payment_terms::Base.RefValue{PaymentTerms}

    # hash(name), precomputed once at construction - see Product.name_hash.
    name_hash::UInt64

    """
    Creates a new supplier. See [`PaymentTerms`](@ref) for the `payment_terms` keyword argument.
    """
    function Supplier(name::String, location::Union{Location, Missing}=missing; payment_terms::PaymentTerms=PaymentTerms())
        return new(name, Dict{Product, Float64}(), Dict{Product, Float64}(),
                   Dict{Product, Float64}(), Dict{Product, Float64}(), location, Ref(payment_terms), hash(name))
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

"""
    get_payment_terms(node)

Gets the [`PaymentTerms`](@ref) of a node: those of a `Supplier`, or the default (everything paid when the
order is placed) for any other node.
"""
get_payment_terms(node) = PaymentTerms()
get_payment_terms(supplier::Supplier) = supplier.payment_terms[]

"""
    set_payment_terms!(supplier::Supplier, payment_terms::PaymentTerms)

Sets when the `supplier` is paid, e.g. `set_payment_terms!(s, PaymentTerms(deposit_share=0.3, balance_offset=-1))`
for a 30% deposit at order and the balance one period before shipment.
"""
function set_payment_terms!(supplier::Supplier, payment_terms::PaymentTerms)
    supplier.payment_terms[] = payment_terms
    return nothing
end
