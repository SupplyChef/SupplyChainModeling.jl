
"""
A customer.
"""
struct Customer <: Node
    name::String

    location::Union{Missing, Location}

    # hash(name), precomputed once at construction - see Product.name_hash.
    name_hash::UInt64

    function Customer(name::String, location::Location)
        return new(name, location, hash(name))
    end

    function Customer(name::String)
        return new(name, missing, hash(name))
    end
end

Base.:(==)(x::Customer, y::Customer) = x.name == y.name
Base.hash(x::Customer, h::UInt64) = hash(x.name_hash, h)
Base.show(io::IO, x::Customer) = print(io, x.name)
