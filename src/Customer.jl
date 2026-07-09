
"""
A customer.
"""
struct Customer <: Node
    name::String
    id::Int

    location::Union{Missing, Location}

    function Customer(name::String, location::Location)
        return new(name, _next_id!(), location)
    end

    function Customer(name::String)
        return new(name, _next_id!(), missing)
    end
end

Base.:(==)(x::Customer, y::Customer) = x.id == y.id
Base.hash(x::Customer, h::UInt64) = hash(x.id, h)
Base.show(io::IO, x::Customer) = print(io, x.name)