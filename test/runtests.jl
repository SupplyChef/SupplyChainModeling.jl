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

@test begin
    product = Product("product")
    storage = Storage("storage")

    # defaults: unlimited capacity, no overflow cost
    add_product!(storage, product)
    default_ok = get_maximum_storage(storage, product) == Inf && get_overflow_cost(storage, product) == 0.0

    add_product!(storage, product; maximum_units=100, overflow_unit_cost=2.5)
    configured_ok = get_maximum_storage(storage, product) == 100 && get_overflow_cost(storage, product) == 2.5

    default_ok && configured_ok
end

# Negative costs/quantities should be rejected, not silently accepted.
@test_throws DomainError Storage("s"; fixed_cost=-1.0)
@test_throws DomainError Storage("s"; opening_cost=-1.0)
@test_throws DomainError Storage("s"; closing_cost=-1.0)
@test_throws DomainError Plant("p", Location(47.6, -122.3); fixed_cost=-1.0)
@test_throws DomainError Plant("p", Location(47.6, -122.3); opening_cost=-1.0)
@test_throws DomainError Plant("p", Location(47.6, -122.3); closing_cost=-1.0)
@test_throws DomainError Lane(Storage("s1"), Storage("s2"); fixed_cost=-1.0)
@test_throws DomainError Lane(Storage("s1"), Storage("s2"); unit_cost=-1.0)
@test_throws DomainError Lane(Storage("s1"), Storage("s2"); minimum_quantity=-1.0)
@test_throws DomainError Lane(Storage("s1"), [Storage("s2"), Storage("s3")]; fixed_cost=-1.0)

@test begin
    storage = Storage("s")
    product = Product("product")
    try
        add_product!(storage, product; unit_holding_cost=-0.1)
        false
    catch e
        e isa DomainError
    end
end

@test begin
    supplier = Supplier("supplier")
    product = Product("product")
    try
        add_product!(supplier, product; unit_cost=-1.0)
        false
    catch e
        e isa DomainError
    end
end

@test begin
    plant = Plant("plant", Location(47.6, -122.3))
    product = Product("product")
    try
        add_product!(plant, product; bill_of_material=Dict{Product, Float64}(), unit_cost=-1.0)
        false
    catch e
        e isa DomainError
    end
end

@test begin
    network = SupplyChain(10)
    customer = Customer("customer")
    product = Product("product")
    add_customer!(network, customer)
    try
        add_demand!(network, customer, product, repeat([10.0], 10); sales_price=-1.0)
        false
    catch e
        e isa DomainError
    end
end

# Adding a second, distinct node with an already-used name must error rather than
# silently vanish into the Set (nodes are compared/hashed by name alone).
@test begin
    network = SupplyChain(10)
    add_storage!(network, Storage("DC1"))
    try
        add_storage!(network, Storage("DC1"))
        false
    catch e
        e isa ArgumentError
    end
end

@test begin
    network = SupplyChain(10)
    add_customer!(network, Customer("c1"))
    try
        add_customer!(network, Customer("c1"))
        false
    catch e
        e isa ArgumentError
    end
end

@test begin
    network = SupplyChain(10)
    add_supplier!(network, Supplier("s1"))
    try
        add_supplier!(network, Supplier("s1"))
        false
    catch e
        e isa ArgumentError
    end
end

@test begin
    network = SupplyChain(10)
    add_plant!(network, Plant("p1", Location(47.6, -122.3)))
    try
        add_plant!(network, Plant("p1", Location(47.6, -122.3)))
        false
    catch e
        e isa ArgumentError
    end
end

@test begin
    network = SupplyChain(10)
    add_product!(network, Product("widget"))
    try
        add_product!(network, Product("widget"))
        false
    catch e
        e isa ArgumentError
    end
end

# Re-adding a node with an already-used name errors even if it's literally the
# same instance: nodes are compared by name alone, so there's no reliable way
# to distinguish "the same node again" from "a different node, same name" -
# treating both as a mistake is the safe default.
@test begin
    network = SupplyChain(10)
    storage = Storage("DC1")
    add_storage!(network, storage)
    try
        add_storage!(network, storage)
        false
    catch e
        e isa ArgumentError
    end
end

# The get_*_index caches must reflect what's currently in the SupplyChain,
# including after nodes/products/lanes are added (the caches are reset to
# nothing by add_storage!/add_product!/add_customer!/add_supplier!/add_lane!).
@test begin
    network = SupplyChain(10)
    s1 = Storage("s1")
    add_storage!(network, s1)

    idx1 = get_storage_index(network)
    ok1 = idx1.items == [s1] && idx1.index[s1] == 1

    s2 = Storage("s2")
    add_storage!(network, s2)
    idx2 = get_storage_index(network)
    ok2 = Set(idx2.items) == Set([s1, s2]) && idx2.index[s1] in (1, 2) && idx2.index[s2] in (1, 2)

    ok1 && ok2
end

@test begin
    network = SupplyChain(10)
    p = Product("p")
    add_product!(network, p)
    idx = get_product_index(network)
    idx.items == [p] && idx.index[p] == 1
end

@test begin
    network = SupplyChain(10)
    storage = Storage("s")
    customer = Customer("c")
    supplier = Supplier("sup")
    add_storage!(network, storage)
    add_customer!(network, customer)
    add_supplier!(network, supplier)
    idx = get_location_index(network)
    Set(idx.items) == Set([storage, customer, supplier]) && length(idx.index) == 3
end

@test begin
    network = SupplyChain(10)
    s1 = Storage("s1")
    s2 = Storage("s2")
    add_storage!(network, s1)
    add_storage!(network, s2)
    l = Lane(s1, s2; unit_cost=0)
    add_lane!(network, l)
    idx = get_lane_index(network)
    idx.items == [l] && idx.index[l] == 1
end

# The "must be opened/closed by the end of the horizon" flags are plain
# constructor kwargs on both Plant and Storage (see Optimization.jl's
# create_network_model, which enforces them).
@test begin
    plant = Plant("plant", Location(47.6, -122.3); must_be_opened_at_end=true, must_be_closed_at_end=false)
    storage = Storage("storage"; must_be_opened_at_end=false, must_be_closed_at_end=true)
    plant.must_be_opened_at_end && !plant.must_be_closed_at_end && !storage.must_be_opened_at_end && storage.must_be_closed_at_end
end

@test begin
    vt = VehicleType("truck", 5; maximum_capacity=[100.0], maximum_time=8.0, fixed_cost=50.0)
    vt.name == "truck" && vt.count == 5 && vt.maximum_capacity == [100.0] && vt.maximum_time == 8.0 && vt.fixed_cost == 50.0
end
