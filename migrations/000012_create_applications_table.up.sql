-- Create applications table
CREATE TABLE IF NOT EXISTS applications (
    application_id SERIAL PRIMARY KEY,
    teacher_id INT REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    application_type VARCHAR(50) DEFAULT 'new_license', -- new_license, renewal, upgrade
    status VARCHAR(30) DEFAULT 'pending', -- pending, under_review, approved, rejected, incomplete
    submitted_at TIMESTAMP DEFAULT NOW(),
    reviewed_at TIMESTAMP,
    reviewed_by INT REFERENCES users(user_id),
    rejection_reason TEXT,
    notes TEXT,
    license_number VARCHAR(50) UNIQUE, -- Generated when approved
    license_issued_date DATE,
    license_expiry_date DATE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_applications_teacher_id ON applications(teacher_id);
CREATE INDEX IF NOT EXISTS idx_applications_user_id ON applications(user_id);
CREATE INDEX IF NOT EXISTS idx_applications_status ON applications(status);
CREATE INDEX IF NOT EXISTS idx_applications_license_number ON applications(license_number);
