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
export get_fixed_cost

import Base.isequal

"""
A node of the supply chain.
"""
abstract type Node end

abstract type Transport end

struct Product
    name::String

    function Product(name)
        return new(name)
    end
end

Base.:(==)(x::Product, y::Product) = x.name == y.name 
Base.hash(x::Product, h::UInt64) = hash(x.name, h)
Base.show(io::IO, x::Product) = print(io, x.name)

include("Location.jl")
include("Customer.jl")
include("Plant.jl")
include("Storage.jl")
include("Supplier.jl")
include("Lane.jl")

end