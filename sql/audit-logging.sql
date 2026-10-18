/* ============================================================
   Audit logging for data modifications (PostgreSQL)
   Lightweight pattern: one audit table, one generic trigger function,
   attached to whichever tables need tracking. Stores the old row as
   JSONB so the schema can evolve without touching the audit code.
   ============================================================ */

CREATE TABLE audit_log (
    audit_id    BIGSERIAL PRIMARY KEY,
    table_name  TEXT        NOT NULL,
    operation   TEXT        NOT NULL,   -- INSERT / UPDATE / DELETE
    changed_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    changed_by  TEXT        NOT NULL DEFAULT CURRENT_USER,
    old_row     JSONB,                 -- NULL on INSERT
    new_row     JSONB                  -- NULL on DELETE
);

CREATE OR REPLACE FUNCTION log_row_change()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, operation, new_row)
        VALUES (TG_TABLE_NAME, 'INSERT', to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, operation, old_row, new_row)
        VALUES (TG_TABLE_NAME, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, operation, old_row)
        VALUES (TG_TABLE_NAME, 'DELETE', to_jsonb(OLD));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Attach to a table:
-- CREATE TRIGGER trg_audit_orders
-- AFTER INSERT OR UPDATE OR DELETE ON fact_orders
-- FOR EACH ROW EXECUTE FUNCTION log_row_change();

-- Housekeeping: the audit table grows forever, so partition or
-- archive it on the same lifecycle policy as everything else.
-- An audit trail nobody maintains is just a second production table.
