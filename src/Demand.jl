"""
The demand a customer has for a product.
"""
struct Demand
    customer::Customer
    product::Product
    demand::Array{Float64, 1}
    sales_price::Float64 # the revenue of a sale
    lost_sales_cost::Float64 # the total cost of a lost sales; including loss of overall business

    function Demand(customer::Customer, product::Product, demand::Array{Float64, 1}; sales_price=0.0, lost_sales_cost=0.0)
        return new(customer, product, demand, sales_price, lost_sales_cost)
    end
end
