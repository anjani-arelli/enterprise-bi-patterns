# RAG status KPIs without the spaghetti

Executive dashboards love red/amber/green. The trap is writing a separate
measure per KPI per status, until you have forty measures nobody dares touch.
I use one status pattern and reuse it.

```dax
-- Core idea: status is a function of (actual, target). Write it once.
KPI Status =
VAR Actual = [Total Revenue]
VAR Target = [Revenue Target]
VAR Ratio  = DIVIDE ( Actual, Target )
RETURN
    SWITCH (
        TRUE (),
        ISBLANK ( Target ), "No target",
        Ratio >= 1,    "Green",
        Ratio >= 0.9,  "Amber",
        "Red"
    )
```

For the conditional formatting itself, I keep a tiny disconnected table
(`StatusColors`: Status → hex code) and drive the formatting with `SELECTEDVALUE`.
Why a table instead of hardcoding colors in the format rules? Because the
business *will* ask to change what counts as amber, and I'd rather they edit
a table than ask me to republish a report.

The discipline that matters: **the target is also a measure** (often pulled
from a targets table at whatever grain the business plans at). The day
someone hardcodes a target into a visual is the day the dashboard starts
lying quietly.
