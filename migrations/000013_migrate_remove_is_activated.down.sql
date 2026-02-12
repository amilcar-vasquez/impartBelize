-- Restore `is_activated` column (best-effort)
BEGIN;

ALTER TABLE users ADD COLUMN IF NOT EXISTS is_activated BOOLEAN DEFAULT FALSE;

-- We can't reliably restore prior separate state; set to false by default.
UPDATE users SET is_activated = FALSE WHERE is_activated IS NULL;

COMMIT;
