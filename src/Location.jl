
"""
The geographical location of a node of the supply chain.
The location is defined by its latitude and longitude, and an optional name.
"""
struct Location
    latitude::Float64
    longitude::Float64
    name::Union{Nothing, String}

    function Location(latitude, longitude, name=nothing)
        return new(latitude, longitude, name)
    end
end