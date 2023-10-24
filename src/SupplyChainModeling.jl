module SupplyChainModeling

export SupplyChain

export Product

export Demand

export Node
export Location
export Customer
export Supplier
export Storage
export Plant

export Transport
export Lane

export add_product!
export add_demand!
export add_customer!
export add_storage!
export add_plant!
export add_supplier!
export add_lane!

export can_ship
export get_destinations
export is_destination
export get_leadtime
export get_fixed_cost

export get_initial_inventory

import Base.isequal

"""
A node of the supply chain.
"""
abstract type Node end

abstract type Transport end

struct Product
    name::String

    function Product(name)
        return new(name)
    end
end

Base.:(==)(x::Product, y::Product) = x.name == y.name 
Base.hash(x::Product, h::UInt64) = hash(x.name, h)
Base.show(io::IO, x::Product) = print(io, x.name)

include("Location.jl")
include("Customer.jl")
include("Plant.jl")
include("Storage.jl")
include("Supplier.jl")
include("Lane.jl")

"""
The demand a customer has for a product.
"""
struct Demand
    customer::Customer
    product::Product
    probability::Float64
    demand::Array{Float64, 1}
    service_level::Float64

    function Demand(customer::Customer, product::Product, demand::Array{Float64, 1}, service_level)
        return new(customer, product, 1.0, demand, service_level)
    end
end

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
    add_demand!(supply_chain, customer, product; demand::Array{Float64, 1}, service_level=1.0)

Adds customer demand for a product. The demand is specified for each time period.

The keyword arguments are:
 - `demand`: the amount of product demanded for each time period.
 - `service_level`: indicates how many lost sales are allowed as a ratio of demand. No demand can be lost if the service level is 1.0 and all demand can be lost if the service level is 0.0. 

"""
function add_demand!(supply_chain, customer, product; demand::Array{Float64, 1}, service_level=1.0)
    if service_level < 0.0 || service_level > 1.0
        throw(DomainError("service_level must be between 0.0 and 1.0 inclusive"))
    end
    add_demand!(supply_chain, Demand(customer, product, demand, service_level))
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
    can_ship(lane::Lane, time::Int)

Checks if units can be send on the lane at a given time.
"""
function can_ship(lane::Lane, time::Int)
    return isnothing(lane.can_ship) || isempty(lane.can_ship) || lane.can_ship[time]
end

end