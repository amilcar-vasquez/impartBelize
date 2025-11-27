-- Drop applications table
DROP INDEX IF EXISTS idx_applications_license_number;
DROP INDEX IF EXISTS idx_applications_status;
DROP INDEX IF EXISTS idx_applications_user_id;
DROP INDEX IF EXISTS idx_applications_teacher_id;
DROP TABLE IF EXISTS applications;
