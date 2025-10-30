-- Drop auth_tokens table
DROP INDEX IF EXISTS idx_auth_tokens_user_id;
DROP TABLE IF EXISTS auth_tokens CASCADE;
