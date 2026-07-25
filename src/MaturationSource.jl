"""
A single-batch production source whose product matures at a deterministic, linear rate over
time: a batch's value (e.g. weight) after being held for `duration` periods is
`initial_value + maturation_rate * duration` (see [`get_maturity_value`](@ref)).

A `MaturationSource` holds at most one batch per planning horizon ("all-in-all-out"): once a
batch is started, the source cannot start another until that batch has shipped and, optionally,
a `changeover_periods`-long turnaround has elapsed. This generalizes livestock finishing
(e.g. raising chicks to a target slaughter weight), aging/curing processes (cheese, wine), and
any other grow/cure-then-ship operation where the holding duration is itself a decision that
trades off against a quality target.
"""
struct MaturationSource <: Node
    name::String

    location::Location

    capacity::Float64

    changeover_periods::Int64
    unavailable_periods::Int64

    initial_value::Dict{Product, Float64}
    maturation_rate::Dict{Product, Float64}
    target_value::Dict{Product, Float64}
    acceptable_deviation_under::Dict{Product, Float64}
    acceptable_deviation_over::Dict{Product, Float64}
    extended_deviation_under::Dict{Product, Float64}
    extended_deviation_over::Dict{Product, Float64}
    underrun_unit_penalty::Dict{Product, Float64}
    overrun_unit_penalty::Dict{Product, Float64}

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
                   Dict{Product, Float64}(), Dict{Product, Float64}(), Dict{Product, Float64}(),
                   Dict{Product, Float64}(), Dict{Product, Float64}(), Dict{Product, Float64}(), Dict{Product, Float64}(),
                   Dict{Product, Float64}(), Dict{Product, Float64}(),
                   Dict{Product, Float64}(),
                   hash(name))
    end
end

@name_identity MaturationSource

"""
    add_product!(source::MaturationSource, product; initial_value, maturation_rate, target_value,
                                                    acceptable_deviation_under, acceptable_deviation_over,
                                                    extended_deviation_under=0.0, extended_deviation_over=0.0,
                                                    underrun_unit_penalty=0.0, overrun_unit_penalty=0.0,
                                                    initial_inventory=0.0)

Indicates that a `MaturationSource` can hold a batch of `product`.

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
    _require_nonnegative(initial_inventory, "initial_inventory")
    source.initial_value[product] = initial_value
    source.maturation_rate[product] = maturation_rate
    source.target_value[product] = target_value
    source.acceptable_deviation_under[product] = acceptable_deviation_under
    source.acceptable_deviation_over[product] = acceptable_deviation_over
    source.extended_deviation_under[product] = extended_deviation_under
    source.extended_deviation_over[product] = extended_deviation_over
    source.underrun_unit_penalty[product] = underrun_unit_penalty
    source.overrun_unit_penalty[product] = overrun_unit_penalty
    source.initial_inventory[product] = initial_inventory
end

"""
    get_maturity_value(source::MaturationSource, product, duration)

Gets the expected batch value (e.g. weight) of `product` at `source` after being held for
`duration` periods, given the source's `initial_value` and linear `maturation_rate`.
"""
function get_maturity_value(source::MaturationSource, product, duration)
    return source.initial_value[product] + source.maturation_rate[product] * duration
end

"""
    has_product(source::MaturationSource, product)

Checks whether a `MaturationSource` is configured to hold batches of `product` (see [`add_product!`](@ref)).
"""
function has_product(source::MaturationSource, product)
    return haskey(source.initial_value, product)
end
