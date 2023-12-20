"""
The demand a customer has for a product.
"""
struct Demand
    customer::Customer
    product::Product
    demand::Array{R, 1} where R <: Real
    sales_price::Float64 # the revenue of a sale
    lost_sales_cost::Float64 # the total cost of a lost sales; including loss of overall business
    service_level::Float64 # the desired service level

    function Demand(customer::Customer, product::Product, demand::Array{R, 1}; sales_price=0.0, lost_sales_cost=0.0, service_level=1.0) where R <: Real
        return new(customer, product, demand, sales_price, lost_sales_cost, service_level)
    end
end
