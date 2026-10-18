# Row-level security at enterprise scale

RLS demos always show one role filtering one table. Production RLS is a
mapping problem, not a DAX problem. Here's how I actually wire it.

## The shape

Three pieces, kept separate:

1. **The fact/dimension model** — untouched by security logic.
2. **A security mapping table** — `UserPrincipalName → Region` (or cost
   center, store, whatever the grain is). Maintained by the business, not
   by me editing a role every time someone joins.
3. **The role** — one DAX filter on the dimension:

```dax
-- Role: Regional Viewers, applied to dim_region
[RegionCode] IN SELECTCOLUMNS (
    FILTER (
        SecurityMapping,
        SecurityMapping[UserPrincipalName] = USERPRINCIPALNAME ()
    ),
    "Region", SecurityMapping[RegionCode]
)
```

## What I've learned doing this for real

- **Test as every role before publishing.** "View as" in Desktop lies by
  omission — it doesn't catch the manager who belongs to two regions or the
  service account the scheduled refresh runs under. I keep a test matrix.
- **The mapping table is the product.** If HR can't update it without a
  developer, the security model rots within a quarter. Give it an owner and
  a refresh schedule like any other dimension.
- **RLS and aggregations interact.** If you use aggregation tables, the RLS
  filter has to reach them too, or users see numbers they shouldn't. Test
  the aggregated path specifically.
- **Document who sees what.** A one-page matrix (role → filter → owner)
  saves more audit pain than any amount of clever DAX.
