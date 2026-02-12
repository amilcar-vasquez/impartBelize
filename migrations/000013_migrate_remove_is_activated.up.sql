-- Migrate activation state into `is_active` and remove `is_activated` column
BEGIN;

-- Ensure any user marked activated is also active
UPDATE users SET is_active = COALESCE(is_active, false) OR COALESCE(is_activated, false);

-- Drop the deprecated column
ALTER TABLE users DROP COLUMN IF EXISTS is_activated;

COMMIT;
