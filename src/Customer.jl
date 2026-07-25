
"""
A customer.
"""
struct Customer <: Node
    name::String

    location::Union{Missing, Location}

    # hash(name), precomputed once at construction - see Product.name_hash.
    name_hash::UInt64

    function Customer(name::String, location::Union{Location, Missing}=missing)
        return new(name, location, hash(name))
    end
end

@name_identity Customer
