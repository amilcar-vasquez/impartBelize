-- Create documents table
CREATE TABLE IF NOT EXISTS documents (
    document_id SERIAL PRIMARY KEY,
    teacher_id INT REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    uploaded_by INT REFERENCES users(user_id) ON DELETE SET NULL,
    application_id INT,
    doc_type VARCHAR(100) NOT NULL,
    file_path TEXT NOT NULL,
    verified BOOLEAN DEFAULT FALSE,
    verified_by INT REFERENCES users(user_id),
    remarks TEXT,
    uploaded_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_documents_teacher_id ON documents(teacher_id);
