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
export VehicleType

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
export get_maximum_storage
export get_maximum_throughput
export get_maximum_age
export get_overflow_cost
export get_arrivals
export get_lanes_between
export get_lanes_in
export get_lanes_out

export get_demand

import Base.isequal

"""
A node of the supply chain.
"""
abstract type Node end

abstract type Transport end

# Monotonically increasing id assigned to each Product/Node on construction.
# `hash`/`==` for these types are defined in terms of this id rather than
# their `name::String`, so that Dict/Set operations (which are on the hot
# path for every inventory access) hash a cheap Int instead of re-hashing a
# String on every lookup.
let _id_counter = Ref(0)
    global function _next_id!()::Int
        _id_counter[] += 1
        return _id_counter[]
    
function _require_nonnegative(value, argname)
    if value < 0
        throw(DomainError(value, "$argname must be non-negative"))
    end
end

function _check_not_duplicate(collection, item, type_name)
    if item in collection
        throw(ArgumentError("$type_name \"$(item.name)\" already exists in the supply chain"))
    end
end

include("VehicleType.jl")
include("Product.jl")
include("Location.jl")
include("Customer.jl")
include("Demand.jl")
include("Plant.jl")
include("Storage.jl")
include("Supplier.jl")
include("Lane.jl")
include("SupplyChain.jl")

end