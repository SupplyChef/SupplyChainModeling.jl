using Test

using SupplyChainModeling

@test begin
    customer = Customer("customer")
    retailer = Storage("retailer")
    wholesaler = Storage("wholesaler")

    l1 = Lane(retailer, customer; unit_cost=0)
    l2 = Lane(retailer, customer; unit_cost=0)
    l3 = Lane(retailer, customer; id="foo", unit_cost=0)

    l4 = Lane(wholesaler, retailer)

    (l1 == l2) && (l1 != l3) && (l1 != l4) 
end

@test begin
    customer = Customer("customer")
    retailer = Storage("retailer")
    wholesaler = Storage("wholesaler")

    l1 = Lane(retailer, customer; unit_cost=0)

    is_destination(customer, l1) && !is_destination(retailer, l1)
end

@test begin
    product = Product("product")

    customer = Customer("customer")
    retailer = Storage("retailer")
    add_product!(retailer, product; unit_holding_cost=0.1, initial_inventory=20)
    wholesaler = Storage("wholesaler")
    add_product!(wholesaler, product; unit_holding_cost=0.1, initial_inventory=20)
    factory = Storage("factory")
    add_product!(factory, product; unit_holding_cost=0.1, initial_inventory=20)
    supplier = Supplier("supplier")

    horizon = 20
    
    l = Lane(retailer, customer; unit_cost=0)
    l2 = Lane(wholesaler, retailer; unit_cost=0, time=2)
    l3 = Lane(factory, wholesaler; unit_cost=0, time= 2)
    l4 = Lane(supplier, factory; unit_cost=0, time=4)

    network = SupplyChain(horizon)
    
    add_supplier!(network, supplier)
    add_storage!(network, retailer)
    add_storage!(network, wholesaler)
    add_storage!(network, factory)
    add_customer!(network, customer)
    add_product!(network, product)
    add_lane!(network, l)
    add_lane!(network, l2)
    add_lane!(network, l3)
    add_lane!(network, l4)

    add_demand!(network, customer, product, repeat([10], horizon); service_level=1.0)

    true
end