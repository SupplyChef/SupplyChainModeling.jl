"""
A single-batch production source whose product's value is a function of how long it has been
held (see [`get_maturity_value`](@ref)) - the batch's *age-value curve*. This generalizes two
families of problems that the operations-research literature usually treats separately:

 - **Perishable/deteriorating inventory** (Nahmias, 1982; Goyal and Giri, 2001): value is
   typically flat, then drops to zero at a fixed shelf life, or decays continuously from the
   moment of production.
 - **Harvest/maturity scheduling** (e.g. sugarcane or wine-grape harvest scheduling: fields/grapes
   ripen toward a peak, must be harvested within a window, and the mill/winery has a periodic
   intake capacity): value *rises* toward an ideal window before falling off if held too long.

Both are the same underlying object - a batch whose eligibility and value for shipment is
`age_value_curve(duration)` - differing only in the curve's shape. [`add_product!`](@ref) has a
convenient linear-growth-with-percentage-bands form for the common (harvest-scheduling-style)
case, and a fully custom form accepting arbitrary `value`/`feasible`/`penalty` functions for
anything else, including classical shelf-life curves.

A `MaturationSource` holds at most one batch per planning horizon ("all-in-all-out"): once a
batch is started, the source cannot start another until that batch has shipped and, optionally,
a `changeover_periods`-long turnaround has elapsed.
"""
struct MaturationSource <: Node
    name::String

    location::Location

    capacity::Float64

    changeover_periods::Int64
    unavailable_periods::Int64

    value_function::Dict{Product, Function}
    feasible_duration::Dict{Product, Function}
    duration_penalty::Dict{Product, Function}

    initial_inventory::Dict{Product, Float64}

    # hash(name), precomputed once at construction - see Product.name_hash.
    name_hash::UInt64

    """
    Creates a new maturation source.

    The keyword arguments are:
     - `capacity`: the batch size processed per cycle (all-in-all-out: a source is either empty or holds exactly one batch of this size).
     - `changeover_periods`: the mandatory turnaround (e.g. sanitation/cleaning) duration, in periods, after a batch ships before a new one can start.
     - `unavailable_periods`: how many periods from the start of the planning horizon this source remains unavailable to start a new batch (e.g. it is already mid-turnaround when the horizon begins).
    """
    function MaturationSource(name::String, location::Location; capacity::Real=Inf, changeover_periods::Int=0, unavailable_periods::Int=0)
        _require_nonnegative(capacity, "capacity")
        _require_nonnegative(changeover_periods, "changeover_periods")
        _require_nonnegative(unavailable_periods, "unavailable_periods")
        return new(name, location, capacity, changeover_periods, unavailable_periods,
                   Dict{Product, Function}(), Dict{Product, Function}(), Dict{Product, Function}(),
                   Dict{Product, Float64}(),
                   hash(name))
    end
end

@name_identity MaturationSource

"""
    add_product!(source::MaturationSource, product, value_function, feasible_duration, duration_penalty; initial_inventory=0.0)

Advanced form of `add_product!`: registers `product` on `source` with a fully custom age-value
curve, instead of the linear-growth-with-percentage-bands convenience form below. Useful for
anything that form can't express - for example, a classical shelf-life curve (constant value,
infeasible to ship past a fixed age):

```julia
add_product!(source, product,
             duration -> 1.0,               # value_function: constant per-unit value
             duration -> duration <= 5,      # feasible_duration: sellable for 5 periods
             duration -> 0.0)                # duration_penalty: no partial-quality penalty
```

 - `value_function(duration)`: the batch's value after being held `duration` periods.
 - `feasible_duration(duration)`: whether a batch may ship after being held `duration` periods.
 - `duration_penalty(duration)`: the per-unit cost of shipping after `duration` periods (zero within the curve's ideal range).
 - `initial_inventory`: if greater than zero, this source already holds a batch of this size at the start of the planning horizon (with current value `value_function(0)`), which must ship during the horizon rather than being a free scheduling choice.
"""
function add_product!(source::MaturationSource, product, value_function::Function, feasible_duration::Function, duration_penalty::Function; initial_inventory::Real=0.0)
    _require_nonnegative(initial_inventory, "initial_inventory")
    source.value_function[product] = value_function
    source.feasible_duration[product] = feasible_duration
    source.duration_penalty[product] = duration_penalty
    source.initial_inventory[product] = initial_inventory
end

"""
    add_product!(source::MaturationSource, product; initial_value, maturation_rate, target_value,
                                                    acceptable_deviation_under, acceptable_deviation_over,
                                                    extended_deviation_under=0.0, extended_deviation_over=0.0,
                                                    underrun_unit_penalty=0.0, overrun_unit_penalty=0.0,
                                                    initial_inventory=0.0)

Indicates that a `MaturationSource` can hold a batch of `product`, whose value grows linearly
while held, toward a target with percentage-based tolerance bands - a convenience over the
fully custom `add_product!` method above, for this common case (see `MaturationSource`'s own
docstring for the harvest-scheduling problems this shape fits).

The keyword arguments are:
 - `initial_value`: the value (e.g. weight) of the product when a batch starts, or its current value if `initial_inventory` is greater than zero (i.e. a batch is already in progress at the start of the planning horizon).
 - `maturation_rate`: the value gained per period a batch is held.
 - `target_value`: the ideal value at the time a batch ships.
 - `acceptable_deviation_under`, `acceptable_deviation_over`: the maximum deviation below/above `target_value` (as a fraction of it) still considered on-target.
 - `extended_deviation_under`, `extended_deviation_over`: additional deviation below/above the acceptable range (again as a fraction of `target_value`) that is still sellable, e.g. to an alternative market, subject to `underrun_unit_penalty`/`overrun_unit_penalty`. A batch whose value falls outside even this extended range cannot ship.
 - `underrun_unit_penalty`, `overrun_unit_penalty`: the cost per unit of value deviation from `target_value` for a batch that ships within the extended-but-not-acceptable range.
 - `initial_inventory`: if greater than zero, this source already holds a batch of this size at the start of the planning horizon (with current value `initial_value`), which must ship during the horizon rather than being a free scheduling choice.
"""
function add_product!(source::MaturationSource, product; initial_value::Real, maturation_rate::Real, target_value::Real,
                                                          acceptable_deviation_under::Real, acceptable_deviation_over::Real,
                                                          extended_deviation_under::Real=0.0, extended_deviation_over::Real=0.0,
                                                          underrun_unit_penalty::Real=0.0, overrun_unit_penalty::Real=0.0,
                                                          initial_inventory::Real=0.0)
    _require_nonnegative(initial_value, "initial_value")
    _require_nonnegative(maturation_rate, "maturation_rate")
    _require_nonnegative(target_value, "target_value")
    _require_nonnegative(acceptable_deviation_under, "acceptable_deviation_under")
    _require_nonnegative(acceptable_deviation_over, "acceptable_deviation_over")
    _require_nonnegative(extended_deviation_under, "extended_deviation_under")
    _require_nonnegative(extended_deviation_over, "extended_deviation_over")
    _require_nonnegative(underrun_unit_penalty, "underrun_unit_penalty")
    _require_nonnegative(overrun_unit_penalty, "overrun_unit_penalty")

    lower_extended = (1 - acceptable_deviation_under - extended_deviation_under) * target_value
    lower_acceptable = (1 - acceptable_deviation_under) * target_value
    upper_acceptable = (1 + acceptable_deviation_over) * target_value
    upper_extended = (1 + acceptable_deviation_over + extended_deviation_over) * target_value

    value_function = duration -> initial_value + maturation_rate * duration
    feasible_duration = duration -> (lower_extended <= value_function(duration) <= upper_extended)
    duration_penalty = duration -> begin
        v = value_function(duration)
        if lower_acceptable <= v <= upper_acceptable
            0.0
        elseif v < lower_acceptable
            underrun_unit_penalty * abs(target_value - v)
        else
            overrun_unit_penalty * abs(target_value - v)
        end
    end

    add_product!(source, product, value_function, feasible_duration, duration_penalty; initial_inventory=initial_inventory)
end

"""
    get_maturity_value(source::MaturationSource, product, duration)

Gets the expected batch value (e.g. weight) of `product` at `source` after being held for
`duration` periods, per the source's registered age-value curve (see [`add_product!`](@ref)).
"""
function get_maturity_value(source::MaturationSource, product, duration)
    return source.value_function[product](duration)
end

"""
    has_product(source::MaturationSource, product)

Checks whether a `MaturationSource` is configured to hold batches of `product` (see [`add_product!`](@ref)).
"""
function has_product(source::MaturationSource, product)
    return haskey(source.value_function, product)
end
