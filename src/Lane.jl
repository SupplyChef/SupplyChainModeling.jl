
const zero1 = [0]

# Hash matching Lane's Base.:(==) (below): the id alone when present,
# otherwise origin/destinations/times. `lead_times` is never part of a lane's
# identity. Written as loops rather than
# sum-over-generator to avoid allocating a closure per call.
function _lane_hash(id::Union{Missing, String}, origin, destinations, times)::UInt64
    if !ismissing(id)
        return hash(id)
    end
    acc = zero(UInt64)
    for destination in destinations
        acc += hash(destination)
    end
    for time in times
        acc += hash(time)
    end
    return hash(origin, acc)
end

"""
A transportation lane between two or more nodes of the supply chain.
"""
struct Lane <: Transport
    id::Union{Missing, String}
    # ConcreteNode (not the open abstract Node): lets dispatch on
    # origin/destinations union-split into a handful of concrete branches
    # instead of a fully dynamic call - see SupplyChainModeling.ConcreteNode.
    origin::ConcreteNode
    # Concretely Vector{ConcreteNode} (not `Array{<:Node, 1}`, a UnionAll):
    # the latter made the field itself abstractly typed, forcing dynamic
    # dispatch on every access - see Env.sorted_locations for the same fix.
    destinations::Vector{ConcreteNode}
    fixed_cost::Float64
    unit_cost::Float64
    minimum_quantity::Float64
    times::Array{Int, 1}
    initial_arrivals::Union{Nothing, Dict{Product, Array{Array{Int64, 1}, 1}}} # for each time, for each destination the amount arriving
    can_ship::Union{Nothing, Array{Bool, 1}}

    # Realized lead time by departure period, per destination:
    # lead_times[i][t] is the lead time of a shipment to destinations[i]
    # that departs in period t (one entry per period of the supply chain's
    # horizon, checked by add_lane!). `nothing` means every shipment takes
    # `times[i]`, which stays the nominal lead time (planning, customer due
    # dates, the optimizer). Not part of the lane's identity - see
    # Base.:(==) below - so scenarios of one network can differ here.
    lead_times::Union{Nothing, Vector{Vector{Int}}}

    # Precomputed hash over the same fields Base.:(==) compares (id if
    # present, else origin/destinations/times). Lanes key the policy and
    # departure dicts consulted throughout a simulation, and every field is
    # immutable, so hash once at construction instead of walking origin +
    # every destination + every time on each lookup.
    lane_hash::UInt64

    function Lane(origin, destination::ConcreteNode; id::Union{Missing, String}=missing,
                                             fixed_cost=0.0,
                                             unit_cost=0.0,
                                             minimum_quantity=0.0,
                                             time::Int=0,
                                             initial_arrivals=nothing::Union{Nothing, Dict{Product, Array{Int, 1}}},
                                             can_ship=nothing::Union{Nothing, Array{Bool, 1}},
                                             lead_times=nothing)
        _require_nonnegative(fixed_cost, "fixed_cost")
        _require_nonnegative(unit_cost, "unit_cost")
        _require_nonnegative(minimum_quantity, "minimum_quantity")
        destinations = ConcreteNode[destination]
        times = (time == 0) ? zero1 : [time]
        return new(id,
                   origin,
                   destinations,
                   fixed_cost,
                   unit_cost,
                   minimum_quantity,
                   times,
                   isnothing(initial_arrivals) ? initial_arrivals : Dict([p => [[ia[t]] for t in eachindex(ia)] for (p, ia) in initial_arrivals]),
                   can_ship,
                   _normalize_lead_times(lead_times, 1),
                   _lane_hash(id, origin, destinations, times))
    end

    function Lane(origin, destinations::Array{N, 1}; id::Union{Missing, String}=missing,
                                                     fixed_cost=0.0,
                                                     unit_cost=0.0,
                                                     minimum_quantity=0.0,
                                                     times=nothing::Union{Nothing, Array{Int, 1}},
                                                     initial_arrivals=nothing::Union{Nothing, Dict{Product, Array{Array{Int, 1}, 1}}},
                                                     can_ship=nothing::Union{Nothing, Array{Bool, 1}},
                                                     lead_times=nothing) where N <: ConcreteNode
        _require_nonnegative(fixed_cost, "fixed_cost")
        _require_nonnegative(unit_cost, "unit_cost")
        _require_nonnegative(minimum_quantity, "minimum_quantity")
        lane_times = isnothing(times) ? zeros(Int, length(destinations)) : times
        node_destinations = convert(Vector{ConcreteNode}, destinations)
        return new(id,
                   origin,
                   node_destinations,
                   fixed_cost,
                   unit_cost,
                   minimum_quantity,
                   lane_times,
                   initial_arrivals,
                   can_ship,
                   _normalize_lead_times(lead_times, length(node_destinations)),
                   _lane_hash(id, origin, node_destinations, lane_times))
    end

    """
        Lane(lane::Lane; kwargs...)

    Copies a lane, keeping its `id`, with any of the constructor's keyword arguments replaced.
    Typically used to build scenarios, e.g. `Lane(lane; lead_times=...)`.
    """
    function Lane(lane::Lane; id=lane.id,
                              fixed_cost=lane.fixed_cost,
                              unit_cost=lane.unit_cost,
                              minimum_quantity=lane.minimum_quantity,
                              times=lane.times,
                              initial_arrivals=lane.initial_arrivals,
                              can_ship=lane.can_ship,
                              lead_times=lane.lead_times)
        return Lane(lane.origin, lane.destinations; id=id,
                                                    fixed_cost=fixed_cost,
                                                    unit_cost=unit_cost,
                                                    minimum_quantity=minimum_quantity,
                                                    times=collect(Int, times),
                                                    initial_arrivals=initial_arrivals,
                                                    can_ship=can_ship,
                                                    lead_times=lead_times)
    end
end

# Normalizes the `lead_times` keyword to one Vector{Int} per destination
# (a flat vector is accepted for a single destination) and checks it holds
# nonnegative values. The length of each vector is checked against the
# horizon by add_lane!, which is where the horizon is known.
function _normalize_lead_times(lead_times, destination_count::Int)
    isnothing(lead_times) && return nothing
    per_destination = lead_times isa AbstractVector{<:Integer} ? [collect(Int, lead_times)] : [collect(Int, v) for v in lead_times]
    if length(per_destination) != destination_count
        throw(ArgumentError("lead_times must have one vector per destination ($destination_count), got $(length(per_destination))"))
    end
    for v in per_destination
        _require_nonnegative(minimum(v; init=0), "lead_times")
    end
    return per_destination
end

Base.:(==)(x::Lane, y::Lane) = begin
                                if !ismissing(x.id) && !ismissing(y.id)
                                    return x.id == y.id
                                else
                                    if (ismissing(x.id) && !ismissing(y.id)) || (!ismissing(x.id) && ismissing(y.id))
                                        return false
                                    else
                                        # Cheap mismatches first (precomputed hash, lengths) before
                                        # element-by-element comparison; the loops replace the previous
                                        # comprehensions, which allocated a temporary Bool array per call.
                                        return x.lane_hash == y.lane_hash &&
                                               (x.origin == y.origin) &&
                                               length(x.destinations) == length(y.destinations) &&
                                               all(i -> x.destinations[i] == y.destinations[i], 1:length(x.destinations)) &&
                                               all(i -> x.times[i] == y.times[i], 1:length(x.destinations))
                                    end
                                end
                               end
Base.hash(x::Lane, h::UInt64) = hash(x.lane_hash, h)
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

"""
    get_leadtime(lane::Lane, destination::Int64)

Gets the lead time to reach the destination at the given index in `lane.destinations`.
Prefer the `ConcreteNode`-based overload below when you have the destination itself
rather than its index.
"""
function get_leadtime(lane::Lane, destination::Int64)
    return lane.times[destination]
end

"""
    get_leadtime(lane::Lane, destination::ConcreteNode)

Gets the lead time to reach a destination using a lane.
"""
function get_leadtime(lane::Lane, destination::ConcreteNode)
    return lane.times[findfirst(d -> d == destination, lane.destinations)]
end

"""
    get_leadtime(lane::Lane, destination::Int64, departure::Int64)
    get_leadtime(lane::Lane, destination::ConcreteNode, departure::Int64)

Gets the lead time of a shipment to a destination that departs in period `departure`: the
realized `lead_times` entry if the lane has them, otherwise the nominal lead time.
"""
function get_leadtime(lane::Lane, destination::Int64, departure::Int64)
    lead_times = lane.lead_times
    return isnothing(lead_times) ? lane.times[destination] : lead_times[destination][departure]
end

function get_leadtime(lane::Lane, destination::ConcreteNode, departure::Int64)
    return get_leadtime(lane, findfirst(d -> d == destination, lane.destinations), departure)
end

"""
    get_fixed_cost(lane::Lane)

Gets the fixed cost of using a lane.
"""
function get_fixed_cost(lane::Lane)
    return lane.fixed_cost
end

"""
    get_arrivals(product::Product, lane::Lane, destination, time::Int)

Gets the known inventory arrivals of a product on a lane for a given time.
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