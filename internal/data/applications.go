// Filename: internal/data/applications.go
package data

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	"github.com/amilcar-vasquez/impartBelize/internal/validator"
)

type Application struct {
	ID                 int64      `json:"application_id"`
	TeacherID          int        `json:"teacher_id"`
	UserID             int        `json:"user_id"`
	ApplicationType    string     `json:"application_type"`
	Status             string     `json:"status"`
	SubmittedAt        time.Time  `json:"submitted_at"`
	ReviewedAt         *time.Time `json:"reviewed_at,omitempty"`
	ReviewedBy         *int       `json:"reviewed_by,omitempty"`
	RejectionReason    string     `json:"rejection_reason,omitempty"`
	Notes              string     `json:"notes,omitempty"`
	LicenseNumber      string     `json:"license_number,omitempty"`
	LicenseIssuedDate  *time.Time `json:"license_issued_date,omitempty"`
	LicenseExpiryDate  *time.Time `json:"license_expiry_date,omitempty"`
	CreatedAt          time.Time  `json:"created_at"`
	UpdatedAt          time.Time  `json:"updated_at"`
}

func ValidateApplication(v *validator.Validator, app *Application) {
	v.Check(app.TeacherID != 0, "teacher_id", "must be provided")
	v.Check(app.UserID != 0, "user_id", "must be provided")
	v.Check(app.ApplicationType != "", "application_type", "must be provided")
	v.Check(validator.PermittedValue(app.ApplicationType, "new_license", "renewal", "upgrade"), "application_type", "must be new_license, renewal, or upgrade")
	v.Check(app.Status != "", "status", "must be provided")
	v.Check(validator.PermittedValue(app.Status, "pending", "under_review", "approved", "rejected", "incomplete"), "status", "must be pending, under_review, approved, rejected, or incomplete")
}

type ApplicationModel struct {
	DB *sql.DB
}

// Insert creates a new application record
func (a *ApplicationModel) Insert(app *Application) error {
	query := `
		INSERT INTO applications (teacher_id, user_id, application_type, status, notes)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING application_id, submitted_at, created_at, updated_at`

	args := []interface{}{app.TeacherID, app.UserID, app.ApplicationType, app.Status, app.Notes}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return a.DB.QueryRowContext(ctx, query, args...).Scan(
		&app.ID,
		&app.SubmittedAt,
		&app.CreatedAt,
		&app.UpdatedAt,
	)
}

// Get retrieves a single application by ID
func (a *ApplicationModel) Get(id int) (*Application, error) {
	if id < 1 {
		return nil, ErrRecordNotFound
	}

	query := `
		SELECT application_id, teacher_id, user_id, application_type, status, 
		       submitted_at, reviewed_at, reviewed_by, rejection_reason, notes,
		       license_number, license_issued_date, license_expiry_date, 
		       created_at, updated_at
		FROM applications
		WHERE application_id = $1`

	var app Application
	var reviewedAt, licenseIssuedDate, licenseExpiryDate sql.NullTime
	var reviewedBy sql.NullInt64
	var rejectionReason, notes, licenseNumber sql.NullString

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := a.DB.QueryRowContext(ctx, query, id).Scan(
		&app.ID,
		&app.TeacherID,
		&app.UserID,
		&app.ApplicationType,
		&app.Status,
		&app.SubmittedAt,
		&reviewedAt,
		&reviewedBy,
		&rejectionReason,
		&notes,
		&licenseNumber,
		&licenseIssuedDate,
		&licenseExpiryDate,
		&app.CreatedAt,
		&app.UpdatedAt,
	)

	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}

	if reviewedAt.Valid {
		app.ReviewedAt = &reviewedAt.Time
	}
	if reviewedBy.Valid {
		reviewedByInt := int(reviewedBy.Int64)
		app.ReviewedBy = &reviewedByInt
	}
	if rejectionReason.Valid {
		app.RejectionReason = rejectionReason.String
	}
	if notes.Valid {
		app.Notes = notes.String
	}
	if licenseNumber.Valid {
		app.LicenseNumber = licenseNumber.String
	}
	if licenseIssuedDate.Valid {
		app.LicenseIssuedDate = &licenseIssuedDate.Time
	}
	if licenseExpiryDate.Valid {
		app.LicenseExpiryDate = &licenseExpiryDate.Time
	}

	return &app, nil
}

// GetByTeacherID retrieves all applications for a specific teacher
func (a *ApplicationModel) GetByTeacherID(teacherID int) ([]*Application, error) {
	query := `
		SELECT application_id, teacher_id, user_id, application_type, status, 
		       submitted_at, reviewed_at, reviewed_by, rejection_reason, notes,
		       license_number, license_issued_date, license_expiry_date, 
		       created_at, updated_at
		FROM applications
		WHERE teacher_id = $1
		ORDER BY submitted_at DESC`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	rows, err := a.DB.QueryContext(ctx, query, teacherID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	applications := []*Application{}

	for rows.Next() {
		var app Application
		var reviewedAt, licenseIssuedDate, licenseExpiryDate sql.NullTime
		var reviewedBy sql.NullInt64
		var rejectionReason, notes, licenseNumber sql.NullString

		err := rows.Scan(
			&app.ID,
			&app.TeacherID,
			&app.UserID,
			&app.ApplicationType,
			&app.Status,
			&app.SubmittedAt,
			&reviewedAt,
			&reviewedBy,
			&rejectionReason,
			&notes,
			&licenseNumber,
			&licenseIssuedDate,
			&licenseExpiryDate,
			&app.CreatedAt,
			&app.UpdatedAt,
		)

		if err != nil {
			return nil, err
		}

		if reviewedAt.Valid {
			app.ReviewedAt = &reviewedAt.Time
		}
		if reviewedBy.Valid {
			reviewedByInt := int(reviewedBy.Int64)
			app.ReviewedBy = &reviewedByInt
		}
		if rejectionReason.Valid {
			app.RejectionReason = rejectionReason.String
		}
		if notes.Valid {
			app.Notes = notes.String
		}
		if licenseNumber.Valid {
			app.LicenseNumber = licenseNumber.String
		}
		if licenseIssuedDate.Valid {
			app.LicenseIssuedDate = &licenseIssuedDate.Time
		}
		if licenseExpiryDate.Valid {
			app.LicenseExpiryDate = &licenseExpiryDate.Time
		}

		applications = append(applications, &app)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return applications, nil
}

// GetAll retrieves all applications with filtering and pagination
func (a *ApplicationModel) GetAll(status string, applicationType string, filters Filters) ([]*Application, Metadata, error) {
	query := `
		SELECT count(*) OVER(), application_id, teacher_id, user_id, application_type, 
		       status, submitted_at, reviewed_at, reviewed_by, rejection_reason, notes,
		       license_number, license_issued_date, license_expiry_date, 
		       created_at, updated_at
		FROM applications
		WHERE 1=1`

	args := []interface{}{}
	argCount := 0

	if status != "" {
		argCount++
		query += ` AND status = $` + fmt.Sprintf("%d", argCount)
		args = append(args, status)
	}

	if applicationType != "" {
		argCount++
		query += ` AND application_type = $` + fmt.Sprintf("%d", argCount)
		args = append(args, applicationType)
	}

	query += fmt.Sprintf(" ORDER BY %s %s", filters.sortColumn(), filters.sortDirection())

	argCount++
	limitArg := argCount
	argCount++
	offsetArg := argCount

	query += fmt.Sprintf(" LIMIT $%d OFFSET $%d", limitArg, offsetArg)
	args = append(args, filters.limit(), filters.offset())

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	rows, err := a.DB.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, Metadata{}, err
	}
	defer rows.Close()

	totalRecords := 0
	applications := []*Application{}

	for rows.Next() {
		var app Application
		var reviewedAt, licenseIssuedDate, licenseExpiryDate sql.NullTime
		var reviewedBy sql.NullInt64
		var rejectionReason, notes, licenseNumber sql.NullString

		err := rows.Scan(
			&totalRecords,
			&app.ID,
			&app.TeacherID,
			&app.UserID,
			&app.ApplicationType,
			&app.Status,
			&app.SubmittedAt,
			&reviewedAt,
			&reviewedBy,
			&rejectionReason,
			&notes,
			&licenseNumber,
			&licenseIssuedDate,
			&licenseExpiryDate,
			&app.CreatedAt,
			&app.UpdatedAt,
		)

		if err != nil {
			return nil, Metadata{}, err
		}

		if reviewedAt.Valid {
			app.ReviewedAt = &reviewedAt.Time
		}
		if reviewedBy.Valid {
			reviewedByInt := int(reviewedBy.Int64)
			app.ReviewedBy = &reviewedByInt
		}
		if rejectionReason.Valid {
			app.RejectionReason = rejectionReason.String
		}
		if notes.Valid {
			app.Notes = notes.String
		}
		if licenseNumber.Valid {
			app.LicenseNumber = licenseNumber.String
		}
		if licenseIssuedDate.Valid {
			app.LicenseIssuedDate = &licenseIssuedDate.Time
		}
		if licenseExpiryDate.Valid {
			app.LicenseExpiryDate = &licenseExpiryDate.Time
		}

		applications = append(applications, &app)
	}

	if err = rows.Err(); err != nil {
		return nil, Metadata{}, err
	}

	metadata := calculateMetadata(totalRecords, filters.Page, filters.PageSize)

	return applications, metadata, nil
}

// Update updates an application record
func (a *ApplicationModel) Update(app *Application) error {
	query := `
		UPDATE applications
		SET status = $1, reviewed_at = $2, reviewed_by = $3, rejection_reason = $4,
		    notes = $5, license_number = $6, license_issued_date = $7, 
		    license_expiry_date = $8, updated_at = NOW()
		WHERE application_id = $9
		RETURNING updated_at`

	args := []interface{}{
		app.Status,
		app.ReviewedAt,
		app.ReviewedBy,
		app.RejectionReason,
		app.Notes,
		app.LicenseNumber,
		app.LicenseIssuedDate,
		app.LicenseExpiryDate,
		app.ID,
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := a.DB.QueryRowContext(ctx, query, args...).Scan(&app.UpdatedAt)
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return ErrRecordNotFound
		default:
			return err
		}
	}

	return nil
}

// Delete removes an application record
func (a *ApplicationModel) Delete(id int) error {
	if id < 1 {
		return ErrRecordNotFound
	}

	query := `DELETE FROM applications WHERE application_id = $1`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	result, err := a.DB.ExecContext(ctx, query, id)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return ErrRecordNotFound
	}

	return nil
}
