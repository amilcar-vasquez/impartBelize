-- Create education table
CREATE TABLE IF NOT EXISTS education (
    education_id SERIAL PRIMARY KEY,
    teacher_id INT REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    institution VARCHAR(150) NOT NULL,
    level VARCHAR(50),
    program VARCHAR(150),
    degree VARCHAR(150),
    year_obtained INT,
    institution_id INT REFERENCES institutions(institution_id)
);
