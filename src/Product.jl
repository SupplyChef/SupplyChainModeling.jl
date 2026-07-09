"""
A product in the supply chain.
"""
struct Product
    name::String
    id::Int

    zones::Array{Float64, 1}

    function Product(name, zones=[1.0])
        return new(name, _next_id!(), zones)
    end
end

Base.:(==)(x::Product, y::Product) = x.id == y.id
Base.hash(x::Product, h::UInt64) = hash(x.id, h)
Base.show(io::IO, x::Product) = print(io, x.name)
