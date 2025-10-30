-- Create teachers table
CREATE TABLE IF NOT EXISTS teachers (
    teacher_id SERIAL PRIMARY KEY,
    user_id INT UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    gender VARCHAR(20),
    dob DATE,
    ssn VARCHAR(15) UNIQUE,
    marital_status VARCHAR(30),
    email VARCHAR(150) UNIQUE NOT NULL,
    address TEXT,
    district_id INT REFERENCES districts(district_id),
    phone VARCHAR(30),
    profile_status VARCHAR(30) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW()
);
