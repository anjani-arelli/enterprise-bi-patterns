# Dynamic customer segmentation in DAX

Every stakeholder meeting eventually lands on the same question: "which
customers actually matter?" I keep a segmentation measure pattern I can drop
into any model. The point isn't the segment names — it's that the logic lives
in **one measure**, so every visual agrees on who counts as what.

```dax
Customer Segment =
VAR Orders12M =
    CALCULATE (
        COUNTROWS ( fact_orders ),
        DATESINPERIOD ( dim_date[full_date], MAX ( dim_date[full_date] ), -12, MONTH )
    )
VAR Revenue12M =
    CALCULATE (
        [Total Revenue],
        DATESINPERIOD ( dim_date[full_date], MAX ( dim_date[full_date] ), -12, MONTH )
    )
RETURN
    SWITCH (
        TRUE (),
        Orders12M >= 12 && Revenue12M >= 5000, "Champions",
        Orders12M >= 6,                        "Regulars",
        Orders12M >= 1,                        "Occasional",
        "Dormant"
    )
```

Three things I always do with this:

1. **The segment is a measure, not a calculated column.** Calculated
   columns are static — the moment someone slices by a different date range,
   they're wrong. A measure re-evaluates in filter context, so "Dormant"
   means dormant *for the period you're looking at*.
2. **Thresholds are parameters, not hardcoded.** In production I'd pull the
   cutoffs from a disconnected parameter table so the business can tune them
   without me editing DAX.
3. **Pair it with a "why" measure.** A segment label alone invites arguments.
   I always put the underlying numbers next to it — orders, revenue,
   last-order date — so the label is a summary, not a black box.
