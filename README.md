# Enterprise BI Patterns

The techniques I reach for in my day-to-day work as a BI developer, written
up the way I'd explain them to a teammate over coffee. These come from six
years building enterprise reporting (banking, IT services, manufacturing
contexts) — **all employer data, client names, and real numbers removed**.
What remains is the pattern, the reasoning, and the code shape.

If you're a hiring manager reading this: this is how I actually work. If
you're another BI dev: steal anything useful.

## Contents

| Folder | What's in it |
|---|---|
| `dax/` | Reusable DAX patterns — dynamic segmentation, RAG status KPIs, time-intelligence gotchas |
| `sql/` | Operational SQL I keep reusing — archival/purge jobs, audit logging |
| `power-bi/` | The non-obvious stuff: performance tuning checklist, RLS at scale |
| `governance/` | PII masking playbook for Azure Synapse — the pattern, not the policy |

## A note on honesty

Nothing here is a screenshot of anyone's production system or a replica of a
client deliverable. The patterns are real because I've built them more than
once; the specifics are generic because the real ones aren't mine to share.
