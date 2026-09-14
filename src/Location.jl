
"""
The geographical location of a node of the supply chain.
The location is defined by its latitude and longitude, and an optional name.

`country` is the ISO 3166-1 alpha-2 country code (e.g. `"US"`, `"CN"`) used to
look up tariff rates between locations (see `Tariff`); it defaults to
`nothing`, meaning the location isn't assigned to a customs territory and
never triggers a tariff.
"""
struct Location
    latitude::Float64
    longitude::Float64
    name::Union{Nothing, String}
    country::Union{Nothing, String}

    function Location(latitude, longitude, name=nothing; country=nothing)
        return new(latitude, longitude, name, country)
    end
end