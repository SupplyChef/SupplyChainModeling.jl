"""
The supply chain.
"""
mutable struct SupplyChain
    horizon::Int
    products::Set{Product}
    storages::Set{Storage}
    suppliers::Set{Supplier}
    customers::Set{Customer}
    plants::Set{Plant}
    lanes::Array{Lane, 1}
    demand::Set{Demand}

    lanes_in::Dict{Node, Set{Lane}}
    lanes_out::Dict{Node, Set{Lane}}

    optimization_model
    discount_factor

    """
    Creates a new supply chain.
    """
    function SupplyChain(horizon=1; discount_factor=1.0)
        sc = new(horizon, 
                 Set{Product}(), 
                 Set{Storage}(),
                 Set{Supplier}(),
                 Set{Customer}(), 
                 Set{Plant}(), 
                 Lane[], 
                 Set{Demand}(),
                 Dict{Node, Set{Lane}}(), 
                 Dict{Node, Set{Lane}}(),
                 nothing,
                 discount_factor)
        return sc
    end
end

"""
    add_demand!(supply_chain, customer, product, demand::Array{Float64, 1}; service_level=1.0)

Adds customer demand for a product. The demand is specified for each time period.

The keyword arguments are:
 - `service_level`: indicates how many lost sales are allowed as a ratio of demand. No demand can be lost if the service level is 1.0 and all demand can be lost if the service level is 0.0.
 - `sales_price`: the sales price of a unit of product.
 - `lost_sales_cost`: the cost of losing the sales of a unit of product.

"""
function add_demand!(supply_chain, customer, product, demand::Array{R, 1}; sales_price=0.0, lost_sales_cost=0.0, service_level=1.0) where R <: Real
    if service_level < 0.0 || service_level > 1.0
        throw(DomainError("service_level must be between 0.0 and 1.0 inclusive"))
    end
    add_demand!(supply_chain, Demand(customer, product, demand; sales_price=sales_price, lost_sales_cost=lost_sales_cost, service_level=service_level))
end

"""
    add_demand!(supply_chain, demand)

Adds demand to the supply chain.
"""
function add_demand!(supply_chain::SupplyChain, demand)
    push!(supply_chain.demand, demand)
end

"""
    add_product!(supply_chain, product)

Adds a product to the supply chain.
"""
function add_product!(supply_chain::SupplyChain, product)
    push!(supply_chain.products, product)
    return product
end


"""
    add_customer!(supply_chain, customer)

Adds a customer to the supply chain.
"""
function add_customer!(supply_chain::SupplyChain, customer)
    push!(supply_chain.customers, customer)
    return customer
end

"""
    add_supplier!(supply_chain, supplier)

Adds a supplier to the supply chain.
"""
function add_supplier!(supply_chain::SupplyChain, supplier)
    push!(supply_chain.suppliers, supplier)
    return supplier
end

"""
    add_storage!(supply_chain, storage)

Adds a storage location to the supply chain.
"""
function add_storage!(supply_chain::SupplyChain, storage)
    push!(supply_chain.storages, storage)
    return storage
end

"""
    add_plant!(supply_chain, plant)

Adds a plant to the supply chain.
"""
function add_plant!(supply_chain::SupplyChain, plant)
    push!(supply_chain.plants, plant)
    return plant
end

"""
    add_lane!(supply_chain, lane)

Adds a transportation lane to the supply chain.
"""
function add_lane!(supply_chain::SupplyChain, lane::Lane)
    push!(supply_chain.lanes, lane)

    for destination in lane.destinations
        if !haskey(supply_chain.lanes_in, destination)
            supply_chain.lanes_in[destination] = Set{Lane}()
        end
        push!(supply_chain.lanes_in[destination], lane)
    end

    if !haskey(supply_chain.lanes_out, lane.origin)
        supply_chain.lanes_out[lane.origin] = Set{Lane}()
    end
    push!(supply_chain.lanes_out[lane.origin], lane)
    return lane
end

"""
    get_lanes_between(supply_chain, from, to)::Set{Lane}()

Gets the lanes between two locations in the supply chain.
"""
function get_lanes_between(supply_chain, from, to)
    if(haskey(supply_chain.lanes_out, from) && haskey(supply_chain.lanes_in, to))
        return intersect(supply_chain.lanes_out[from], supply_chain.lanes_in[to])
    end
    return Set{Lane}()
end

"""
    get_lanes_in(supply_chain, node)::Set{Lane}()

Gets the lanes going into a node in the supply chain.
"""
function get_lanes_in(supply_chain, node)
    if(haskey(supply_chain.lanes_in, node))
        return supply_chain.lanes_in[node]
    else
        return Set{Lane}()
    end
end

"""
    get_lanes_out(supply_chain, node)::Set{Lane}()

Gets the lanes coming out of a node in the supply chain.
"""
function get_lanes_out(supply_chain, node)
    if(haskey(supply_chain.lanes_out, node))
        return supply_chain.lanes_out[node]
    end
    return Set{Lane}()
end