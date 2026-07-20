module SupplyChainModeling

export SupplyChain
export IndexedCollection
export get_storage_index
export get_product_index
export get_location_index

export Product

export Demand

export Node
export ConcreteNode
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

"""
    ConcreteNode

The closed set of built-in `Node` subtypes. Hot-path type signatures use
this instead of the bare abstract `Node` so Julia can compile dispatch as a
handful of concrete branches (union-splitting) instead of a fully dynamic
call - `Node` itself stays open for extension, but anything typed
`ConcreteNode` needs updating (here) if a new `Node` subtype is added and
should participate in those dispatch-efficient paths.
"""
const ConcreteNode = Union{Storage, Customer, Supplier, Plant}

include("Lane.jl")
include("SupplyChain.jl")

end