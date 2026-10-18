# PII masking playbook (Azure Synapse / SQL)

Masking isn't a feature you turn on — it's a small program of work. This is
the pattern I follow; the actual column lists and policies always belong to
the client's data governance team, never to a portfolio repo.

## The layers, in order

1. **Classify first.** You can't mask what you haven't found. Data
   discovery/classification across the warehouse (Synapse has built-in
   classification; Purview does it at catalog scale) produces the column
   inventory. No inventory, no masking — anything else is theater.
2. **Dynamic data masking for the read path.** The standard functions cover
   most cases:
   - Email → `email()` partial mask
   - Phone / national IDs → `partial(0, "XXX-XXX-", 4)` style custom strings
   - Names in non-production → `default()` full mask
   - Applied with `ALTER TABLE ... ALTER COLUMN ... ADD MASKED WITH
     (FUNCTION = '...')`. Unprivileged logins see masks; privileged ones
     don't. That's the whole point — no application changes needed.
3. **Static masking for non-production.** Dev and test environments get
   masked *copies*, not live data with dynamic masks. Dynamic masking
   protects the reader; it does nothing for a developer with db_owner on a
   restored backup.
4. **Exceptions are a process, not a permission.** Someone always needs the
   real values. That goes through a documented exception with an owner and
   an expiry — not a permanent `UNMASK` grant that everyone forgets about.

## The mistakes I watch for

- Masking the warehouse but not the exports. If a masked column lands in a
  CSV on a shared drive, you masked the wrong end.
- Forgetting downstream: Power BI datasets, extracts, and subscribed
  reports inherit whatever the service account can see. The masking has to
  be evaluated at the identity that actually reads the data.
- Treating masking as a one-time project. New columns appear every sprint;
  classification has to run on a schedule or the coverage decays.
