CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,   -- bcrypt/argon2 hash
    role_id INT REFERENCES roles(role_id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_activated BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    created_by INT REFERENCES users(user_id) ON DELETE SET NULL,
    updated_at TIMESTAMP DEFAULT NOW(),
    updated_by INT REFERENCES users(user_id) ON DELETE SET NULL
);