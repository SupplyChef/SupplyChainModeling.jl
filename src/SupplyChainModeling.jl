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

export get_destinations
export is_destination
export get_leadtime
export get_fixed_cost

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

    lanes_in::Dict{Node, Set{Int32}}
    lanes_out::Dict{Node, Set{Int32}}

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
                 Dict{Node, Set{Int32}}(), 
                 Dict{Node, Set{Int32}}(),
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


end