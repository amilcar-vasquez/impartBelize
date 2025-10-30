-- Remove seeded initial data inserted by 000011_seed_initial_data.up.sql
-- Note: This tries to remove the sample records but will not drop core tables.

-- Remove sample notifications for user_id = 1
DELETE FROM notifications WHERE user_id = 1 AND message LIKE 'Your application for a teaching license has been received.%';
DELETE FROM notifications WHERE user_id = 1 AND message LIKE 'Your license has been approved by the CEO.%';

-- Remove sample documents (by file_path)
DELETE FROM documents WHERE file_path IN ('/uploads/jdoe_degree.pdf','/uploads/jdoe_cert.pdf');

-- Remove education and qualification records for teacher email jdoe@school.edu.bz
DELETE FROM education WHERE teacher_id IN (SELECT teacher_id FROM teachers WHERE email = 'jdoe@school.edu.bz');
DELETE FROM qualifications WHERE teacher_id IN (SELECT teacher_id FROM teachers WHERE email = 'jdoe@school.edu.bz');

-- Remove sample teacher
DELETE FROM teachers WHERE email = 'jdoe@school.edu.bz';

-- Remove sample institutions (by name)
DELETE FROM institutions WHERE name IN (
  'University of Belize','Galen University','Muffles Junior College','St. John''s College','Independence High School','Corozal Community College'
);

-- Remove districts
DELETE FROM districts WHERE name IN ('Corozal','Orange Walk','Belize','Cayo','Stann Creek','Toledo');
