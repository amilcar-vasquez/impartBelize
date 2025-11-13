-- Create auth_tokens table
CREATE TABLE IF NOT EXISTS auth_tokens (
    token_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    token bytea UNIQUE NOT NULL,
    expires_at TIMESTAMP(0) WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP(0) WITH TIME ZONE DEFAULT NOW(),
    revoked BOOLEAN DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS idx_auth_tokens_user_id ON auth_tokens(user_id);
