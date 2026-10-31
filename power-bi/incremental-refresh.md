# Incremental refresh in Power BI — the parts nobody warns you about

Incremental refresh sounds like a checkbox: set `RangeStart` and `RangeEnd`,
pick an archive period and a refresh period, publish, done. In practice most
of the work is in the details below, and most of the failures I've seen came
from one of them.

## The setup that actually matters

- **The parameters must be named exactly `RangeStart` and `RangeEnd`**, typed
  as Date/Time. Close-but-not-exact names fail silently — the filter just
  never applies and every refresh is a full refresh.
- **The filter goes on the fact table's date column in Power Query**, using
  those two parameters. If the filter step gets folded away or edited later,
  incremental refresh quietly degrades.
- **Only the first refresh is slow.** It builds every partition. Judging
  incremental refresh by the first run is how it gets switched off in week
  one — the second run is the honest measurement.

## Gotchas from real models

1. **Date/timezone mismatches.** If your source stores UTC and your date
   dimension is local time, the boundary partitions are where rows get
   double-counted or dropped. Align everything to one convention before
   turning incremental refresh on, not after.
2. **"Detect data changes" is not free.** It polls a timestamp column on
   every refresh. On a wide fact table without an index on that column, the
   poll can cost more than the refresh saves. Use it when late-arriving
   updates are common, not by default.
3. **Partitions hide bad data.** A full refresh surfaces source problems
   everywhere; an incremental one only touches recent partitions, so a
   broken historical load can sit unnoticed for months. I keep a row-count
   reconciliation check against the source for the archive range — cheap,
   and it has caught real problems.
4. **DirectQuery hybrid tables change the conversation.** If the business
   wants today's data live *and* years of history, a hybrid table
   (incremental refresh with a DirectQuery tail partition) usually beats
   shrinking the import window. Model it deliberately; don't stumble into
   it.

## My default configuration

- Archive: full history the business actually queries (not "everything,
  forever" — every extra year is refresh time and model size).
- Refresh window: 10–14 days, because late corrections in operational
  systems rarely reach back further than that. If they do in your world,
  widen the window — this number should come from how the source system
  behaves, not from a template.
- Refresh the dimension tables fully; they're small and they change shape,
  not just content.

The point of incremental refresh isn't the refresh. It's that a model the
business trusts with five years of history stays fast enough that nobody
asks for an Excel extract instead.
