
"""
A customer.
"""
struct Customer <: Node
    name::String

    location::Union{Missing, Location}

    function Customer(name::String, location::Location)
        return new(name, location)
    end

    function Customer(name::String)
        return new(name, missing)
    end
end

Base.:(==)(x::Customer, y::Customer) = x.name == y.name 
Base.hash(x::Customer, h::UInt64) = hash(x.name, h)
Base.show(io::IO, x::Customer) = print(io, x.name)