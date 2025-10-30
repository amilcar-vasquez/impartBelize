-- Create districts table
CREATE TABLE IF NOT EXISTS districts (
    district_id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);
