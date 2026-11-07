/* ============================================================
   Slowly Changing Dimension — Type 2 template (T-SQL)
   The pattern I use when a dimension needs history: a customer
   changes segment, region, or tier, and last month's reports must
   still show what was true last month. Type 1 overwrites the past;
   Type 2 keeps it.

   Shape: one row per version of a business key, with
   EffectiveFrom / EffectiveTo dates and an IsCurrent flag.
   Change detection uses a hash so a 30-column dimension doesn't
   need a 30-column comparison.
   ============================================================ */

-- 1. The dimension. Surrogate key is the identity; the business key
--    (customer_id) repeats across versions. A fact joins on the
--    surrogate key, never on the business key.
CREATE TABLE dbo.dim_customer
(
    customer_key    INT IDENTITY(1,1) NOT NULL,
    customer_id     INT               NOT NULL,  -- business key
    customer_name   NVARCHAR(200)     NOT NULL,
    segment         NVARCHAR(50)      NULL,
    region          NVARCHAR(50)      NULL,
    tier            NVARCHAR(20)      NULL,
    row_hash        VARBINARY(32)     NOT NULL,  -- change-detection hash
    effective_from  DATE              NOT NULL,
    effective_to    DATE              NULL,      -- NULL = open-ended
    is_current      BIT               NOT NULL,
    CONSTRAINT PK_dim_customer PRIMARY KEY (customer_key)
);

-- 2. Stage the incoming source rows exactly as they arrive, then
--    hash the tracked attributes. Only hash what history actually
--    needs — hashing a last-login timestamp turns every load into
--    a "change".
SELECT
    customer_id,
    customer_name,
    segment,
    region,
    tier,
    HASHBYTES('SHA2_256',
        CONCAT_WS('|',
            customer_name,
            ISNULL(segment, ''),
            ISNULL(region, ''),
            ISNULL(tier, ''))) AS row_hash
INTO #stg_customer
FROM dbo.stg_customer_source;

-- 3. Expire the current version where something actually changed.
--    effective_to is the day before the new version starts, so
--    point-in-time joins (order_date BETWEEN effective_from
--    AND ISNULL(effective_to, '9999-12-31')) never overlap.
UPDATE d
SET d.effective_to = DATEADD(DAY, -1, CAST(GETDATE() AS DATE)),
    d.is_current   = 0
FROM dbo.dim_customer d
JOIN #stg_customer s
  ON s.customer_id = d.customer_id
 AND d.is_current  = 1
 AND s.row_hash   <> d.row_hash;

-- 4. Insert a new version for every changed row, and for every
--    genuinely new business key.
INSERT INTO dbo.dim_customer
    (customer_id, customer_name, segment, region, tier,
     row_hash, effective_from, effective_to, is_current)
SELECT
    s.customer_id, s.customer_name, s.segment, s.region, s.tier,
    s.row_hash, CAST(GETDATE() AS DATE), NULL, 1
FROM #stg_customer s
LEFT JOIN dbo.dim_customer d
  ON d.customer_id = s.customer_id
 AND d.is_current  = 1
WHERE d.customer_key IS NULL        -- brand-new customer
   OR s.row_hash <> d.row_hash;     -- changed since current version

-- 5. Log the load: how many new, how many changed. If "changed"
--    suddenly spikes, stop and look at the source before the next
--    load — a source-system re-key or a bad extract looks exactly
--    like mass churn.
SELECT
    (SELECT COUNT(*) FROM #stg_customer) AS staged_rows,
    (SELECT COUNT(*) FROM dbo.dim_customer
      WHERE effective_from = CAST(GETDATE() AS DATE)) AS new_versions;

/* What this template deliberately leaves out:
   - Deletes: a deleted source row usually means "no longer in
     scope", not "never existed". Expire it like a change, don't
     remove it — unless the business explicitly wants hard deletes.
   - Late-arriving dimensions: a fact dated before the dimension
     version exists needs an "unknown" member or a backdated
     effective_from. Decide per project; don't improvise per load.
   - Type 2 on a huge dimension: hash and compare in the staging
     layer (or in the ETL tool) rather than in a single MERGE —
     MERGE is convenient until the plan goes sideways at 10M rows,
     and debugging a MERGE at 2 AM is nobody's idea of fun.
   - Type 1 attributes (e.g. a corrected spelling) belong in a
     separate column set, updated in place — mixing Type 1 and
     Type 2 in one statement is how history quietly gets rewritten.
*/
