"""
A type of vehicle available to move product between nodes of the supply chain.
"""
struct VehicleType
    name::String
    count::Int64

    fixed_cost::Float64
    maximum_capacity::Array{Float64, 1}
    maximum_time::Float64

    """
    Creates a new vehicle type.

    The keyword arguments are:
     - `maximum_capacity`: the maximum amount of each product a single vehicle can carry.
     - `maximum_time`: the maximum time a single vehicle can be in use for.
     - `fixed_cost`: the cost of using a vehicle of this type.
    """
    function VehicleType(name, count; maximum_capacity=[Inf], maximum_time=Inf, fixed_cost=0.0)
        return new(name, count, fixed_cost, maximum_capacity, maximum_time)
    end
end