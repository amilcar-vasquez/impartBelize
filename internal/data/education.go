package data

import (
	"context"
	"database/sql"
	"errors"
	"time"
)

type Education struct {
	ID            int    `json:"education_id"`
	TeacherID     int    `json:"teacher_id"`
	Institution   string `json:"institution"`
	Level         string `json:"level,omitempty"`
	Program       string `json:"program,omitempty"`
	Degree        string `json:"degree,omitempty"`
	YearObtained  int    `json:"year_obtained,omitempty"`
	InstitutionID int    `json:"institution_id,omitempty"`
}

type EducationModel struct {
	DB *sql.DB
}

func (m *EducationModel) Insert(e *Education) error {
	query := `INSERT INTO education (teacher_id, institution, level, program, degree, year_obtained, institution_id) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING education_id`

	var year interface{}
	if e.YearObtained > 0 {
		year = e.YearObtained
	} else {
		year = nil
	}

	var instID interface{}
	if e.InstitutionID > 0 {
		instID = e.InstitutionID
	} else {
		instID = nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return m.DB.QueryRowContext(ctx, query, e.TeacherID, e.Institution, e.Level, e.Program, e.Degree, year, instID).Scan(&e.ID)
}

func (m *EducationModel) Get(id int) (*Education, error) {
	if id < 1 {
		return nil, ErrRecordNotFound
	}
	query := `SELECT education_id, teacher_id, institution, level, program, degree, year_obtained, institution_id FROM education WHERE education_id = $1`

	var e Education
	var year sql.NullInt64
	var inst sql.NullInt64

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := m.DB.QueryRowContext(ctx, query, id).Scan(&e.ID, &e.TeacherID, &e.Institution, &e.Level, &e.Program, &e.Degree, &year, &inst)
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}
	if year.Valid {
		e.YearObtained = int(year.Int64)
	}
	if inst.Valid {
		e.InstitutionID = int(inst.Int64)
	}
	return &e, nil
}

func (m *EducationModel) GetByTeacher(teacherID int) ([]*Education, error) {
	query := `SELECT education_id, teacher_id, institution, level, program, degree, year_obtained, institution_id FROM education WHERE teacher_id = $1 ORDER BY year_obtained DESC NULLS LAST`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	rows, err := m.DB.QueryContext(ctx, query, teacherID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []*Education{}
	for rows.Next() {
		var e Education
		var year sql.NullInt64
		var inst sql.NullInt64
		if err := rows.Scan(&e.ID, &e.TeacherID, &e.Institution, &e.Level, &e.Program, &e.Degree, &year, &inst); err != nil {
			return nil, err
		}
		if year.Valid {
			e.YearObtained = int(year.Int64)
		}
		if inst.Valid {
			e.InstitutionID = int(inst.Int64)
		}
		out = append(out, &e)
	}
	if err = rows.Err(); err != nil {
		return nil, err
	}
	return out, nil
}

func (m *EducationModel) Delete(id int) error {
	if id < 1 {
		return ErrRecordNotFound
	}
	query := `DELETE FROM education WHERE education_id = $1`
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
