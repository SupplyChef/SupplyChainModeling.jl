"""
A product in the supply chain.
"""
struct Product
    name::String

    zones::Array{Float64, 1}

    function Product(name, zones=[1.0])
        return new(name, zones)
    end
end

Base.:(==)(x::Product, y::Product) = x.name == y.name 
Base.hash(x::Product, h::UInt64) = hash(x.name, h)
Base.show(io::IO, x::Product) = print(io, x.name)
