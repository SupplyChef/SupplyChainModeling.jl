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
    unit_holding_cost::Dict{Product, Float64}

    maximum_throughput::Dict{Product, Float64}
    maximum_overall_throughput::Float64
    maximum_units::Dict{Product, Float64}
    
    additional_stock_cover::Dict{Product, Float64}

    location::Union{Location, Missing}

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
                   Dict{Product, Float64}(), 
                   maximum_overall_throughput, 
                   Dict{Product, Float64}(), 
                   Dict{Product, Float64}(), 
                   location)
    end

    """
    Creates a new storage location.
    """
    function Storage(name::String; fixed_cost::Real=0.0, opening_cost::Real=0.0, closing_cost::Real=Inf, 
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
                   Dict{Product, Float64}(), 
                   maximum_overall_throughput, 
                   Dict{Product, Float64}(), 
                   Dict{Product, Float64}(), 
                   missing)
    end
end

Base.:(==)(x::Storage, y::Storage) = x.name == y.name 
Base.hash(x::Storage, h::UInt64) = hash(x.name, h)
Base.show(io::IO, x::Storage) = print(io, x.name)

function add_product!(storage::Storage, product; initial_inventory::Real=0, 
                                                 unit_handling_cost::Real=0,
                                                 unit_holding_cost::Real=0, 
                                                 maximum_throughput::Float64=Inf, 
                                                 additional_stock_cover::Real=0.0)
    storage.initial_inventory[product] = initial_inventory
    storage.unit_handling_cost[product] = unit_handling_cost
    storage.unit_holding_cost[product] = unit_holding_cost
    if !isinf(maximum_throughput)
        storage.maximum_throughput[product] = maximum_throughput
    else
        delete!(storage.maximum_throughput, product)
    end
    storage.additional_stock_cover[product] = additional_stock_cover
end

function get_initial_inventory(storage, product)
    return get(storage.initial_inventory, product, 0)
end

function get_maximum_storage(node, product)
    if(haskey(node.maximum_units, product))
        return node.maximum_units[product]
    else
        return Inf
    end
end