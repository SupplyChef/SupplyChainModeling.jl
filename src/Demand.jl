"""
The demand a customer has for a product.
"""
struct Demand
    customer::Customer
    product::Product
    probability::Float64
    demand::Array{Float64, 1}
    service_level::Float64

    function Demand(customer::Customer, product::Product, demand::Array{Float64, 1}, service_level)
        return new(customer, product, 1.0, demand, service_level)
    end
end
