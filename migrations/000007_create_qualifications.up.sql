-- Create qualifications table
CREATE TABLE IF NOT EXISTS qualifications (
    qualification_id SERIAL PRIMARY KEY,
    teacher_id INT REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    institution VARCHAR(150),
    specialization VARCHAR(150),
    certification VARCHAR(150),
    year_obtained INT,
    institution_id INT REFERENCES institutions(institution_id)
);
