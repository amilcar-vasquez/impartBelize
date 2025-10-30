package data

import (
	"context"
	"database/sql"
	"errors"
	"time"
)

// Teacher represents a teacher profile
type Teacher struct {
	ID            int        `json:"teacher_id"`
	UserID        int        `json:"user_id,omitempty"`
	FirstName     string     `json:"first_name"`
	LastName      string     `json:"last_name"`
	Gender        string     `json:"gender,omitempty"`
	DOB           *time.Time `json:"dob,omitempty"`
	SSN           string     `json:"ssn,omitempty"`
	MaritalStatus string     `json:"marital_status,omitempty"`
	Email         string     `json:"email"`
	Address       string     `json:"address,omitempty"`
	DistrictID    int        `json:"district_id,omitempty"`
	Phone         string     `json:"phone,omitempty"`
	ProfileStatus string     `json:"profile_status,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
}

type TeacherModel struct {
	DB *sql.DB
}

func (m *TeacherModel) Insert(t *Teacher) error {
	query := `INSERT INTO teachers (user_id, first_name, last_name, gender, dob, ssn, marital_status, email, address, district_id, phone, profile_status) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING teacher_id, created_at`

	var dob interface{}
	if t.DOB != nil {
		dob = *t.DOB
	} else {
		dob = nil
	}

	var userID interface{}
	if t.UserID > 0 {
		userID = t.UserID
	} else {
		userID = nil
	}

	var district interface{}
	if t.DistrictID > 0 {
		district = t.DistrictID
	} else {
		district = nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return m.DB.QueryRowContext(ctx, query, userID, t.FirstName, t.LastName, t.Gender, dob, t.SSN, t.MaritalStatus, t.Email, t.Address, district, t.Phone, t.ProfileStatus).Scan(&t.ID, &t.CreatedAt)
}

func (m *TeacherModel) Get(id int) (*Teacher, error) {
	if id < 1 {
		return nil, ErrRecordNotFound
	}
	query := `SELECT teacher_id, user_id, first_name, last_name, gender, dob, ssn, marital_status, email, address, district_id, phone, profile_status, created_at FROM teachers WHERE teacher_id = $1`

	var t Teacher
	var dob sql.NullTime
	var userID sql.NullInt64
	var district sql.NullInt64

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := m.DB.QueryRowContext(ctx, query, id).Scan(&t.ID, &userID, &t.FirstName, &t.LastName, &t.Gender, &dob, &t.SSN, &t.MaritalStatus, &t.Email, &t.Address, &district, &t.Phone, &t.ProfileStatus, &t.CreatedAt)
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}
	if dob.Valid {
		t.DOB = &dob.Time
	}
	if userID.Valid {
		t.UserID = int(userID.Int64)
	}
	if district.Valid {
		t.DistrictID = int(district.Int64)
	}
	return &t, nil
}

func (m *TeacherModel) GetByUserID(userID int) (*Teacher, error) {
	query := `SELECT teacher_id, user_id, first_name, last_name, gender, dob, ssn, marital_status, email, address, district_id, phone, profile_status, created_at FROM teachers WHERE user_id = $1`

	var t Teacher
	var dob sql.NullTime
	var u sql.NullInt64
	var district sql.NullInt64

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := m.DB.QueryRowContext(ctx, query, userID).Scan(&t.ID, &u, &t.FirstName, &t.LastName, &t.Gender, &dob, &t.SSN, &t.MaritalStatus, &t.Email, &t.Address, &district, &t.Phone, &t.ProfileStatus, &t.CreatedAt)
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}
	if dob.Valid {
		t.DOB = &dob.Time
	}
	if u.Valid {
		t.UserID = int(u.Int64)
	}
	if district.Valid {
		t.DistrictID = int(district.Int64)
	}
	return &t, nil
}

func (m *TeacherModel) Delete(id int) error {
	if id < 1 {
		return ErrRecordNotFound
	}
	query := `DELETE FROM teachers WHERE teacher_id = $1`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	res, err := m.DB.ExecContext(ctx, query, id)
	if err != nil {
		return err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if n == 0 {
		return ErrRecordNotFound
	}
	return nil
}
