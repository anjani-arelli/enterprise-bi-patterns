/* ============================================================
   Archival / purge job template (T-SQL)
   Pattern I use for data lifecycle management: move old rows to an
   archive table first, purge second, log everything. Never delete
   what you haven't archived — restore requests always come on the
   worst possible day.
   ============================================================ */

-- 1. Archive first (same schema, _Archive suffix; created once)
--    Keep the archive table's indexes minimal: date + the PK.

DECLARE @CutoffDate DATE = DATEADD(YEAR, -3, CAST(GETDATE() AS DATE));
DECLARE @BatchSize  INT  = 50000;
DECLARE @RowsMoved  INT  = 1;

-- 2. Move in batches so the transaction log stays sane
WHILE @RowsMoved > 0
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO dbo.fact_orders_Archive
        SELECT TOP (@BatchSize) *
        FROM dbo.fact_orders
        WHERE order_date < @CutoffDate
        ORDER BY order_date;

        SET @RowsMoved = @@ROWCOUNT;

        DELETE TOP (@BatchSize)
        FROM dbo.fact_orders
        WHERE order_date < @CutoffDate;

        -- 3. Log the run: what, when, how many, by whom
        INSERT INTO dbo.etl_job_log (job_name, cutoff_date, rows_moved, run_at, run_by)
        VALUES ('Archive_fact_orders', @CutoffDate, @RowsMoved, GETDATE(), SUSER_SNAME());

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        INSERT INTO dbo.etl_job_log (job_name, cutoff_date, rows_moved, run_at, run_by, error_message)
        VALUES ('Archive_fact_orders', @CutoffDate, 0, GETDATE(), SUSER_SNAME(), ERROR_MESSAGE());
        THROW;
    END CATCH;
END
