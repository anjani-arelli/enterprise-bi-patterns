# Time-intelligence gotchas (learned the hard way)

Every BI team I've worked on has lost at least one afternoon to a
time-intelligence number that looked right and wasn't. The pattern is
usually the same: the measure is fine, the *calendar* is lying to you.
These are the traps I check first now, in order.

## 1. Your date table has gaps and nobody told you

`SAMEPERIODLASTYEAR`, `DATEADD`, `DATESYTD` — all of them quietly assume a
contiguous date table. One missing day (a holiday load that failed, a
dimension built from fact dates instead of a real calendar) and
year-over-year numbers drift by small amounts that nobody notices until
finance does.

My rule: the date table is generated, never derived from facts. Full
years, no gaps, marked as the date table in the model. If a report only
needs three years, I still load five — comparisons reach back further
than you think.

## 2. Fiscal years are not calendar years with a different label

If the business runs an April–March fiscal year, `TOTALYTD` with the
year-end date is the easy part. The bugs hide in the *comparisons*:
prior-year fiscal YTD needs the same fiscal offset applied to the
comparison period, not just "minus 12 months." I've seen dashboards where
fiscal YTD was right and fiscal PYTD was quietly showing calendar-aligned
numbers. Same visual, wrong answer.

## 3. Month-to-date against a partial month

MTD vs. prior MTD is meaningless if the current month has 12 days loaded
and last month has 31. Either compare through the same day-of-month
(`DAY(TODAY())` filter on the comparison period) or show the full prior
month labelled as such. Mixing the two in one visual is how you get a
"sales are down 40%" panic that turns out to be a calendar.

## 4. `DATESYTD` resets — slicers don't care

Put a month slicer on the page and a YTD measure will happily compute
YTD *within the selected month* depending on how the filter context flows
in. If the number must always be true YTD regardless of page slicers,
that has to be deliberate in the DAX (explicit date handling), not
assumed. Test every time-intelligence measure with a month selected —
that's the state your users actually live in.

## 5. The refresh finished. The dates didn't.

A fact table refreshed to yesterday and a date table whose "IsToday" /
relative-period flags were calculated at a different time will disagree
about what "last 30 days" means. Dynamic flags belong in the query or in
DAX (`TODAY()` / `NOW()`), not in a static column someone loaded in March.

---

None of this is exotic. It's the unglamorous calendar work underneath
every "simple" growth number — and it's most of what decides whether the
number survives a meeting with finance.
