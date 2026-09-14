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

@test begin
    product = Product("product")
    other_product = Product("other_product")

    network = SupplyChain()
    add_product!(network, product)
    add_product!(network, other_product)

    # No tariff registered between CN and US yet.
    no_tariff_yet = get_tariff_rate(network, "CN", "US", product) == 0.0

    add_tariff!(network, Tariff("CN", "US", 0.25))
    matches_registered_pair = get_tariff_rate(network, "CN", "US", product) == 0.25
    # A product-specific rate for the same pair takes priority over the "every product" one.
    add_tariff!(network, Tariff("CN", "US", 0.10; product=other_product))
    wildcard_still_applies_to_product = get_tariff_rate(network, "CN", "US", product) == 0.25
    product_specific_overrides_wildcard = get_tariff_rate(network, "CN", "US", other_product) == 0.10

    # No rate registered for this pair/direction.
    unregistered_pair_is_zero = get_tariff_rate(network, "US", "CN", product) == 0.0
    # Same origin/destination country never incurs a tariff, even with a rate on file for it.
    add_tariff!(network, Tariff("US", "US", 0.5))
    same_country_is_zero = get_tariff_rate(network, "US", "US", product) == 0.0
    # A location without a country assigned never incurs a tariff either.
    missing_country_is_zero = get_tariff_rate(network, nothing, "US", product) == 0.0

    no_tariff_yet && matches_registered_pair && wildcard_still_applies_to_product &&
        product_specific_overrides_wildcard && unregistered_pair_is_zero &&
        same_country_is_zero && missing_country_is_zero
end

@test begin
    location = Location(47.6, -122.3; country="US")
    location.country == "US"
end

# Negative costs/quantities should be rejected, not silently accepted.
@test_throws DomainError Tariff("CN", "US", -0.1)
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

# MaturationSource: linear maturation, penalty-free product registration, and the
# all-in-all-out "at most one batch, must ship if already stocked" state captured by
# initial_inventory/unavailable_periods (see the CIRRELT-2026-10 IPPDP use case this
# generalizes: chick breeding -> slaughter weight).
@test begin
    product = Product("bird")
    source = MaturationSource("farm1", Location(47.6, -122.3); capacity=10000, changeover_periods=3, unavailable_periods=0)
    add_product!(source, product; initial_value=45.0, maturation_rate=25.0, target_value=2250.0,
                                  acceptable_deviation_under=0.1, acceptable_deviation_over=0.1,
                                  extended_deviation_under=0.05, extended_deviation_over=0.05)

    has_product(source, product) &&
        get_maturity_value(source, product, 0) == 45.0 &&
        get_maturity_value(source, product, 10) == 45.0 + 25.0 * 10 &&
        source.capacity == 10000 &&
        source.changeover_periods == 3 &&
        source.initial_inventory[product] == 0.0
end

@test begin
    product = Product("bird")
    other_product = Product("other")
    source = MaturationSource("farm1", Location(47.6, -122.3); capacity=10000)
    add_product!(source, product; initial_value=45.0, maturation_rate=25.0, target_value=2250.0,
                                  acceptable_deviation_under=0.1, acceptable_deviation_over=0.1)
    !has_product(source, other_product)
end

@test_throws DomainError MaturationSource("farm1", Location(47.6, -122.3); capacity=-1.0)
@test_throws DomainError MaturationSource("farm1", Location(47.6, -122.3); changeover_periods=-1)
@test_throws DomainError MaturationSource("farm1", Location(47.6, -122.3); unavailable_periods=-1)

@test begin
    product = Product("bird")
    source = MaturationSource("farm1", Location(47.6, -122.3))
    try
        add_product!(source, product; initial_value=-1.0, maturation_rate=25.0, target_value=2250.0,
                                      acceptable_deviation_under=0.1, acceptable_deviation_over=0.1)
        false
    catch e
        e isa DomainError
    end
end

# A source that already holds a batch (initial_inventory > 0) at the start of the
# horizon: initial_value stands in for the batch's *current* value (not a day-old
# value), consistent with how the IPPDP formulation reuses phi_b for both cases.
@test begin
    product = Product("bird")
    source = MaturationSource("farm1", Location(47.6, -122.3); capacity=10000)
    add_product!(source, product; initial_value=1800.0, maturation_rate=25.0, target_value=2250.0,
                                  acceptable_deviation_under=0.1, acceptable_deviation_over=0.1,
                                  initial_inventory=10000.0)
    source.initial_inventory[product] == 10000.0 && get_maturity_value(source, product, 0) == 1800.0
end

# The advanced add_product! form accepts an arbitrary age-value curve, not just linear growth
# toward a target - e.g. a classical shelf-life curve (constant value, unsellable past a fixed
# age), proving MaturationSource generalizes beyond the harvest-scheduling shape.
@test begin
    product = Product("cheese")
    source = MaturationSource("cave1", Location(45.4, 5.6); capacity=200)
    add_product!(source, product,
                 duration -> 1.0,           # value_function: constant per-unit value once ready
                 duration -> 2 <= duration <= 5,  # feasible_duration: sellable only from day 2 to day 5
                 duration -> 0.0)           # duration_penalty: no partial-quality penalty

    has_product(source, product) &&
        get_maturity_value(source, product, 0) == 1.0 &&
        !source.feasible_duration[product](1) &&
        source.feasible_duration[product](2) &&
        source.feasible_duration[product](5) &&
        !source.feasible_duration[product](6) &&
        source.duration_penalty[product](3) == 0.0
end

# QuotaSink: a soft periodic target, not a hard cap - deviations are penalized, not forbidden.
@test begin
    product = Product("bird")
    sink = QuotaSink("slaughterhouse1", Location(46.8, -71.2))
    add_product!(sink, product; quota=50000, underproduction_unit_penalty=1.0, overproduction_unit_penalty=1.0)

    has_product(sink, product) &&
        sink.quota[product] == 50000 &&
        sink.underproduction_unit_penalty[product] == 1.0 &&
        sink.overproduction_unit_penalty[product] == 1.0
end

@test begin
    product = Product("bird")
    sink = QuotaSink("slaughterhouse1", Location(46.8, -71.2))
    try
        add_product!(sink, product; quota=-1.0)
        false
    catch e
        e isa DomainError
    end
end

@test begin
    network = SupplyChain(10)
    source = MaturationSource("farm1", Location(47.6, -122.3))
    sink = QuotaSink("slaughterhouse1", Location(46.8, -71.2))
    add_maturation_source!(network, source)
    add_quota_sink!(network, sink)
    (source in network.maturation_sources) && (sink in network.quota_sinks)
end

@test begin
    network = SupplyChain(10)
    add_maturation_source!(network, MaturationSource("farm1", Location(47.6, -122.3)))
    try
        add_maturation_source!(network, MaturationSource("farm1", Location(47.6, -122.3)))
        false
    catch e
        e isa ArgumentError
    end
end

@test begin
    network = SupplyChain(10)
    add_quota_sink!(network, QuotaSink("slaughterhouse1", Location(46.8, -71.2)))
    try
        add_quota_sink!(network, QuotaSink("slaughterhouse1", Location(46.8, -71.2)))
        false
    catch e
        e isa ArgumentError
    end
end
