module SupplyChainModeling

export Product

export Node
export Location
export Customer
export Supplier
export Storage
export Plant

export Transport
export Lane

export add_product!

export get_destinations
export is_destination
export get_leadtime

import Base.isequal

"""
A node of the supply chain.
"""
abstract type Node end

abstract type Transport end

abstract type Product end

include("Location.jl")
include("Customer.jl")
include("Plant.jl")
include("Storage.jl")
include("Supplier.jl")

const zero1 = [0]

"""
A transportation lane between two nodes of the supply chain.
"""
struct Lane <: Transport
    origin::Node
    destinations::Array{Any, 1} #where N <: Node
    fixed_cost::Float64
    unit_cost::Float64
    minimum_quantity::Float64
    times::Array{Int, 1}
    initial_arrivals::Union{Nothing, Dict{Product, Array{Array{Int64, 1}}}} # for each time, for each destination the amount arriving
    can_ship::Union{Nothing, Array{Bool, 1}}

    function Lane(origin, destination::Node; fixed_cost=0.0, 
                                             unit_cost=0.0, 
                                             minimum_quantity=0.0, 
                                             time::Int=0, 
                                             initial_arrivals=nothing::Union{Nothing, Dict{Product, Array{Int, 1}}}, 
                                             can_ship=nothing::Union{Nothing, Array{Bool, 1}})
        return new(origin, 
                   [destination], 
                   fixed_cost, 
                   unit_cost, 
                   minimum_quantity, 
                   (time == 0) ? zero1 : [time], 
                   isnothing(initial_arrivals) ? initial_arrivals : Dict([p => [[ia[t]] for t in 1:length(ia)] for (p, ia) in initial_arrivals]), 
                   can_ship)
    end

    function Lane(origin, destinations::Array{N, 1}; fixed_cost=0.0, 
                                                     unit_cost=0.0, 
                                                     minimum_quantity=0.0, 
                                                     times=nothing::Union{Nothing, Array{Int, 1}}, 
                                                     initial_arrivals=nothing::Union{Nothing, Dict{Product, Array{Array{Int, 1}}}}, 
                                                     can_ship=nothing::Union{Nothing, Array{Bool, 1}}) where N <: Node
        return new(origin, 
                   destinations, 
                   fixed_cost, 
                   unit_cost, 
                   minimum_quantity, 
                   isnothing(times) ? zeros(Int, length(destinations)) : times, 
                   initial_arrivals, 
                   can_ship)
    end
end

Base.:(==)(x::Lane, y::Lane) = x.origin == y.origin &&  length(x.destinations) == length(y.destinations) && all([x.destinations[i] == y.destinations[i] for i in 1:length(x.destinations)])
Base.hash(x::Lane, h::UInt64) = hash(x.origin, hash(x.destination, h))
Base.show(io::IO, x::Lane) = print(io, "$(x.origin) $(x.destination)")

function get_destinations(lane::Lane)
    return lane.destinations
end

function is_destination(location, lane::Lane)
    return location ∈ get_destinations(route)
end

function get_leadtime(lane::Lane, destination)
    return route.lead_times[destination]
end

end