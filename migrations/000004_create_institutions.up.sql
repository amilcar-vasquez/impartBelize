-- Create institutions table
CREATE TABLE IF NOT EXISTS institutions (
    institution_id SERIAL PRIMARY KEY,
    name VARCHAR(200) UNIQUE NOT NULL,
    district_id INT REFERENCES districts(district_id),
    institution_type VARCHAR(100)
);
