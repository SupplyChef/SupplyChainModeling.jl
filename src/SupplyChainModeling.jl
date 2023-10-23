module SupplyChainModeling

export Product

export Node
export Location
export Customer
export Supplier
export Storage
export Plant
export Lane


abstract type Node end

abstract type Product end

"""
The geographical location of a node of the supply chain. 
The location is defined by its latitude and longitude.
"""
struct Location
    latitude::Float64
    longitude::Float64
    name

    function Location(latitude, longitude)
        return new(latitude, longitude, nothing)
    end

    function Location(latitude, longitude, name)
        return new(latitude, longitude, name)
    end
end

"""
A customer.
"""
struct Customer <: Node
    name::String

    location::Union{Missing, Location}

    function Customer(name::String, location::Location)
        return new(name, location)
    end

    function Customer(name::String)
        return new(name, missing)
    end
end

Base.:(==)(x::Customer, y::Customer) = x.name == y.name 
Base.hash(x::Customer, h::UInt64) = hash(x.name, h)
Base.show(io::IO, x::Customer) = print(io, x.name)


"""
A supplier.
"""
struct Supplier <: Node
    name::String

    unit_cost::Dict{Product, Float64}

    maximum_throughput::Dict{Product, Float64}

    location::Location

    """
    Creates a new supplier.
    """
    function Supplier(name::String, location::Location)
        return new(name, Dict{Product, Float64}(), Dict{Product, Float64}(), location)
    end
end

Base.:(==)(x::Supplier, y::Supplier) = x.name == y.name 
Base.hash(x::Supplier, h::UInt64) = hash(x.name, h)
Base.show(io::IO, x::Supplier) = print(io, x.name)

"""
A storage location.
"""
struct Storage <: Node
    name::String

    fixed_cost::Float64
    
    opening_cost::Float64
    closing_cost::Float64

    initial_opened::Bool
    initial_inventory::Dict{Product, Float64}

    must_be_opened_at_end::Bool
    must_be_closed_at_end::Bool

    unit_handling_cost::Dict{Product, Float64}
    maximum_throughput::Dict{Product, Float64}
    maximum_overall_throughput::Float64
    maximum_units::Dict{Product, Float64}
    additional_stock_cover::Dict{Product, Float64}

    location::Location

    """
    Creates a new storage location.
    """
    function Storage(name::String, location::Location; fixed_cost::Real=0.0, opening_cost::Real=0.0, closing_cost::Real=Inf, 
                     initial_opened::Bool=true, maximum_overall_throughput::Float64=Inf)
                     #, must_be_opened_at_end::Bool=false, must_be_closed_at_end::Bool=false, maximum_overall_throughput::Float64=Inf)
        return new(name,
                   fixed_cost, opening_cost, closing_cost, 
                   initial_opened, 
                   Dict{Product, Float64}(),
                   false,#must_be_opened_at_end,
                   false,#must_be_closed_at_end, 
                   Dict{Product, Float64}(), 
                   Dict{Product, Float64}(), 
                   maximum_overall_throughput, 
                   Dict{Product, Float64}(), 
                   Dict{Product, Float64}(), 
                   location)
    end
end

function add_product!(storage::Storage, product; initial_inventory::Union{Real, Nothing}=0, unit_handling_cost::Real=0, maximum_throughput::Float64=Inf, additional_stock_cover::Real=0.0)
    if !isnothing(initial_inventory)
        storage.initial_inventory[product] = initial_inventory
    end
    if unit_handling_cost > 0
        storage.unit_handling_cost[product] = unit_handling_cost
    end
    if !isinf(maximum_throughput)
        storage.maximum_throughput[product] = maximum_throughput
    end
    storage.additional_stock_cover[product] = additional_stock_cover
end

Base.:(==)(x::Storage, y::Storage) = x.name == y.name 
Base.hash(x::Storage, h::UInt64) = hash(x.name, h)
Base.show(io::IO, x::Storage) = print(io, x.name)

"""
A plant.
"""
struct Plant <: Node
    name::String

    fixed_cost::Float64

    opening_cost::Float64
    closing_cost::Float64

    initial_opened::Bool
    must_be_opened_at_end::Bool
    must_be_closed_at_end::Bool

    bill_of_material::Dict{Product, Dict{Product, Float64}}
    unit_cost::Dict{Product, Float64}
    time::Dict{Product, Int}

    maximum_throughput::Dict{Product, Float64}
    
    location::Location

    """
    Creates a new plant.
    """
    function Plant(name::String, location::Location; fixed_cost::Real=0.0, opening_cost::Real=0.0, closing_cost::Real=Inf, initial_opened::Bool=true, must_be_opened_at_end::Bool=false, must_be_closed_at_end::Bool=false)
        return new(name, fixed_cost, opening_cost, closing_cost, initial_opened, must_be_opened_at_end, must_be_closed_at_end, 
            Dict{Product, Dict{Product, Float64}}(), Dict{Product, Float64}(), Dict{Product, Float64}(), Dict{Product, Float64}(), 
            location)
    end
end

"""
    add_product!(plant::Plant, product::Product; bill_of_material::Dict{Product, Float64}, unit_cost, maximum_throughput)

Indicates that a plant can produce a product.

The keyword arguments are:
 - `bill_of_material`: the amount of other product needed to produce one unit of the product. This dictionary can be empty if there are no other products needed.
 - `unit_cost`: the cost of producing one unit of product.
 - `maximum_throughput`: the maximum amount of product that can be produced in a time period.
 - `time`: the production lead time.

"""
function add_product!(plant::Plant, product; bill_of_material::Dict{Product, Float64}, unit_cost=0.0, maximum_throughput::Real=Inf, time::Int=0)
    plant.bill_of_material[product] = bill_of_material
    plant.unit_cost[product] = unit_cost
    plant.maximum_throughput[product] = maximum_throughput
    plant.time[product] = time
end

Base.:(==)(x::Plant, y::Plant) = x.name == y.name 
Base.hash(x::Plant, h::UInt64) = hash(x.name, h)
Base.show(io::IO, x::Plant) = print(io, x.name)

struct Lane
    origin::Union{Supplier, Storage, Customer}
    destination::Union{Supplier, Storage, Customer}

    fixed_cost::Float64
    unit_cost::Float64

    lead_time::Int64

    can_ship::Array{Bool, 1}

    function Lane(;origin, destination, fixed_cost=0, unit_cost=0, lead_time=0, can_ship::Array{Bool, 1}=Bool[])
        return new(origin, destination, fixed_cost, unit_cost, lead_time, can_ship)
    end
end

end