"""
    PaymentTerms(; deposit_share=1.0, balance_offset=0)

When a buyer pays a `Supplier`. Time is counted in periods of the supply chain, whatever length a
period has been given.

 - `deposit_share`: the share (between 0 and 1) of an order's value paid when the order is placed,
   e.g. `0.3` for the 30% deposit common with overseas suppliers. The remaining share is the balance.
 - `balance_offset`: when the balance is paid, in periods relative to the shipment leaving the
   supplier: negative before shipment (`-1` is one period before), `0` at shipment, positive after
   shipment (credit terms). A balance due before the order itself is paid when the order is placed.

The default pays everything when the order is placed.
"""
struct PaymentTerms
    deposit_share::Float64
    balance_offset::Int

    function PaymentTerms(; deposit_share::Real=1.0, balance_offset::Integer=0)
        if deposit_share < 0 || deposit_share > 1
            throw(DomainError(deposit_share, "deposit_share must be between 0 and 1 inclusive"))
        end
        return new(deposit_share, balance_offset)
    end
end
