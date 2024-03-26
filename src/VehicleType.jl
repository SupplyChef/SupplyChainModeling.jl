struct VehicleType
    name::String
    count::Int64

    fixed_cost::Float64
    maximum_capacity::Array{Float64, 1}
    maximum_time::Float64

    function VehicleType(name, count; maximum_capacity=[Inf], maximum_time=Inf, fixed_cost=0.0)
        return new(name, count, fixed_cost, maximum_capacity, maximum_time)
    end
end