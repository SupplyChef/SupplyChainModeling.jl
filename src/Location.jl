
"""
The geographical location of a node of the supply chain. 
The location is defined by its latitude and longitude.
"""
struct Location
    latitude::Float64
    longitude::Float64
    name

    function Location(latitude, longitude)
        return new(latitude, longitude, nothing)
    end

    function Location(latitude, longitude, name)
        return new(latitude, longitude, name)
    end
end