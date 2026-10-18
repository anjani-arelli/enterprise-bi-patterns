# Power BI performance tuning checklist

When a report is slow, I work this list top to bottom. Nine times out of ten
the fix is in the first three items — the rest are for when it isn't.

1. **Check the model first, not the visuals.** Run Performance Analyzer in
   Power BI Desktop and sort by DAX query duration. If one visual dominates,
   the problem is usually its measure, not the report.
2. **Kill bi-directional relationships.** Almost every slow model I've
   inherited had bi-di filters turned on "to make a slicer work." Replace
   with single-direction + `CROSSFILTER` inside the specific measure that
   needs it.
3. **Star schema, always.** Snowflaked dimensions and flattened fact tables
   are the usual suspects. If the fact has 40 columns, half of them belong
   in a dimension.
4. **Push filters to the source.** A Power Query step that filters rows
   *after* loading 10M rows is just a slow report with extra steps. Filter
   in the SQL, fold the query, check the native query in the applied steps.
5. **Calculated columns vs measures.** If it's computed once per row and
   never changes with slicers, it can be a column (or better, done in the
   ETL). If it must respond to filters, it's a measure. Getting this wrong
   is the most expensive beginner mistake in DAX.
6. **Date table discipline.** Mark it as a date table, keep it continuous,
   generate it in Power Query. Broken time intelligence is a correctness
   bug that looks like a performance bug.
7. **Reduce cardinality where it doesn't matter.** High-cardinality text
   columns (free-text notes, GUIDs as text) in the model bloat memory and
   slow everything. Split them out or drop them from the import.
8. **Aggregations for the big tables.** For fact tables past ~50M rows, an
   aggregation table at month/product grain with automatic aggregation
   management beats buying a bigger capacity.
9. **Scheduled refresh reality check.** Incremental refresh on the fact
   table, and the refresh window should match how far back data actually
   changes — not "everything, every night, just in case."
