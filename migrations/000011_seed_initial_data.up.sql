-- Seed initial data (districts, institutions, sample teacher-related records)
-- NOTE: This migration assumes `users` and `roles` tables exist already.

-- Districts
INSERT INTO districts (name) VALUES
('Corozal'),
('Orange Walk'),
('Belize'),
('Cayo'),
('Stann Creek'),
('Toledo')
ON CONFLICT (name) DO NOTHING;

-- Institutions
INSERT INTO institutions (name, district_id, institution_type) VALUES
('University of Belize', 3, 'University'),
('Galen University', 4, 'University'),
('Muffles Junior College', 2, 'Junior College'),
('St. John''s College', 3, 'College'),
('Independence High School', 5, 'High School'),
('Corozal Community College', 1, 'High School')
ON CONFLICT (name) DO NOTHING;

-- Sample Teacher (references users.user_id = 1) - insert only if user exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM users WHERE user_id = 1) THEN
        INSERT INTO teachers (user_id, first_name, last_name, gender, dob, ssn, marital_status, email, address, district_id, phone)
        SELECT 1, 'John', 'Doe', 'Male', '1989-05-15', '123-45-678', 'Married', 'jdoe@school.edu.bz', 'Bullet Tree Village, Cayo', 4, '601-2222'
        WHERE NOT EXISTS (SELECT 1 FROM teachers WHERE email = 'jdoe@school.edu.bz');
    END IF;
END$$;

-- Education record for sample teacher
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM teachers WHERE email = 'jdoe@school.edu.bz') THEN
        INSERT INTO education (teacher_id, institution, level, program, degree, year_obtained)
        SELECT teacher_id, 'University of Belize', 'Tertiary', 'Education', 'Bachelor of Education', 2012
        FROM teachers WHERE email = 'jdoe@school.edu.bz'
        AND NOT EXISTS (SELECT 1 FROM education e JOIN teachers t ON e.teacher_id = t.teacher_id WHERE t.email = 'jdoe@school.edu.bz' AND e.degree = 'Bachelor of Education');
    END IF;
END$$;

-- Qualification for sample teacher
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM teachers WHERE email = 'jdoe@school.edu.bz') THEN
        INSERT INTO qualifications (teacher_id, institution, specialization, certification, year_obtained)
        SELECT teacher_id, 'University of Belize', 'Primary Education', 'Teacher Certification', 2013
        FROM teachers WHERE email = 'jdoe@school.edu.bz'
        AND NOT EXISTS (SELECT 1 FROM qualifications q JOIN teachers t ON q.teacher_id = t.teacher_id WHERE t.email = 'jdoe@school.edu.bz' AND q.certification = 'Teacher Certification');
    END IF;
END$$;

-- Documents for sample teacher
DO $$
DECLARE t_id INT;
BEGIN
    SELECT teacher_id INTO t_id FROM teachers WHERE email = 'jdoe@school.edu.bz' LIMIT 1;
    IF t_id IS NOT NULL AND EXISTS (SELECT 1 FROM users WHERE user_id = 1) THEN
        INSERT INTO documents (teacher_id, uploaded_by, doc_type, file_path, verified, remarks)
        SELECT t_id, 1, 'degree_certificate', '/uploads/jdoe_degree.pdf', TRUE, 'Verified by DEC'
        WHERE NOT EXISTS (SELECT 1 FROM documents WHERE teacher_id = t_id AND doc_type = 'degree_certificate');

        INSERT INTO documents (teacher_id, uploaded_by, doc_type, file_path, verified, remarks)
        SELECT t_id, 1, 'teacher_certification', '/uploads/jdoe_cert.pdf', TRUE, 'Verified by TSC'
        WHERE NOT EXISTS (SELECT 1 FROM documents WHERE teacher_id = t_id AND doc_type = 'teacher_certification');
    END IF;
END$$;

-- Notifications for sample user (user_id = 1)
INSERT INTO notifications (user_id, message, channel)
SELECT 1, 'Your application for a teaching license has been received.', 'email'
WHERE EXISTS (SELECT 1 FROM users WHERE user_id = 1)
AND NOT EXISTS (SELECT 1 FROM notifications WHERE user_id = 1 AND message LIKE 'Your application for a teaching license has been received.%');

INSERT INTO notifications (user_id, message, channel)
SELECT 1, 'Your license has been approved by the CEO.', 'email'
WHERE EXISTS (SELECT 1 FROM users WHERE user_id = 1)
AND NOT EXISTS (SELECT 1 FROM notifications WHERE user_id = 1 AND message LIKE 'Your license has been approved by the CEO.%');
