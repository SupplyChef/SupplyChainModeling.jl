
const zero1 = [0]

"""
A transportation lane between two or more nodes of the supply chain.
"""
struct Lane <: Transport
    id::Union{Missing, String}
    origin::Node
    destinations::Array{<: Node, 1}
    fixed_cost::Float64
    unit_cost::Float64
    minimum_quantity::Float64
    times::Array{Int, 1}
    initial_arrivals::Union{Nothing, Dict{Product, Array{Array{Int64, 1}, 1}}} # for each time, for each destination the amount arriving
    can_ship::Union{Nothing, Array{Bool, 1}}

    function Lane(origin, destination::Node; id::Union{Missing, String}=missing,
                                             fixed_cost=0.0, 
                                             unit_cost=0.0, 
                                             minimum_quantity=0.0, 
                                             time::Int=0, 
                                             initial_arrivals=nothing::Union{Nothing, Dict{Product, Array{Int, 1}}}, 
                                             can_ship=nothing::Union{Nothing, Array{Bool, 1}})
        return new(id,
                   origin, 
                   [destination], 
                   fixed_cost, 
                   unit_cost, 
                   minimum_quantity, 
                   (time == 0) ? zero1 : [time], 
                   isnothing(initial_arrivals) ? initial_arrivals : Dict([p => [[ia[t]] for t in eachindex(ia)] for (p, ia) in initial_arrivals]), 
                   can_ship)
    end

    function Lane(origin, destinations::Array{N, 1}; id::Union{Missing, String}=missing,
                                                     fixed_cost=0.0, 
                                                     unit_cost=0.0, 
                                                     minimum_quantity=0.0, 
                                                     times=nothing::Union{Nothing, Array{Int, 1}}, 
                                                     initial_arrivals=nothing::Union{Nothing, Dict{Product, Array{Array{Int, 1}, 1}}}, 
                                                     can_ship=nothing::Union{Nothing, Array{Bool, 1}}) where N <: Node
        return new(id,
                   origin, 
                   destinations, 
                   fixed_cost, 
                   unit_cost, 
                   minimum_quantity, 
                   isnothing(times) ? zeros(Int, length(destinations)) : times, 
                   initial_arrivals, 
                   can_ship)
    end
end

Base.:(==)(x::Lane, y::Lane) = begin
                                if !ismissing(x.id) && !ismissing(y.id)
                                    return x.id == y.id
                                else
                                    if (ismissing(x.id) && !ismissing(y.id)) || (!ismissing(x.id) && ismissing(y.id))
                                        return false
                                    else
                                        return (x.origin == y.origin) && length(x.destinations) == length(y.destinations) && all([x.destinations[i] == y.destinations[i] for i in 1:length(x.destinations)]) && all([x.times[i] == y.times[i] for i in 1:length(x.destinations)])
                                    end
                                end
                               end
Base.hash(x::Lane, h::UInt64) = begin
                                 if !ismissing(x.id)
                                    return hash(x.id, h)
                                 else
                                    return hash(x.origin, sum(hash(x.destinations[i], h) for i in 1:length(x.destinations)) + sum(hash(x.times[i], h) for i in 1:length(x.times)))
                                 end
                                end
Base.show(io::IO, x::Lane) = print(io, "$(x.origin) $(x.destinations)")

"""
    get_destinations(lane::Lane)

Gets the destinations of a lane.
"""
function get_destinations(lane::Lane)
    return lane.destinations
end

"""
    is_destination(location, lane::Lane)::bool

Checks if a location is a destination of a lane.
"""
function is_destination(location, lane::Lane)::Bool
    return location ∈ get_destinations(lane)
end

function get_leadtime(lane::Lane, destination::Int64)
    return lane.times[destination]
end

"""
    get_leadtime(lane::Lane, destination::Node)

Gets the lead time to reach a destination using a lane.
"""
function get_leadtime(lane::Lane, destination::Node)
    return lane.times[findfirst(d -> d == destination, lane.destinations)]
end

"""
    get_fixed_cost(lane::Lane)

Gets the fixed cost of using a lane.
"""
function get_fixed_cost(lane::Lane)
    return lane.fixed_cost
end

"""
    get_arrivals(lane::Lane, destination, time::Int)

Gets the known inventory arrivals on a lane for a given time.
"""
function get_arrivals(product::Product, lane::Lane, destination, time::Int)
    index = findfirst(d -> d == destination, lane.destinations)
    if isnothing(lane.initial_arrivals) || !haskey(lane.initial_arrivals, product) || isnothing(index)
        return 0
    else
        return lane.initial_arrivals[product][time][index]
    end
end

"""
    can_ship(lane::Lane, time::Int)

Checks if inventory can be send on a lane at a given time.
"""
function can_ship(lane::Lane, time::Int)
    return isnothing(lane.can_ship) || isempty(lane.can_ship) || lane.can_ship[time]
end