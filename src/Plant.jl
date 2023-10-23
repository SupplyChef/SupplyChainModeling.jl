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

Base.:(==)(x::Plant, y::Plant) = x.name == y.name 
Base.hash(x::Plant, h::UInt64) = hash(x.name, h)
Base.show(io::IO, x::Plant) = print(io, x.name)

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