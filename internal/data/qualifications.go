package data

import (
	"context"
	"database/sql"
	"time"
)

type Qualification struct {
	ID             int    `json:"qualification_id"`
	TeacherID      int    `json:"teacher_id"`
	Institution    string `json:"institution,omitempty"`
	Specialization string `json:"specialization,omitempty"`
	Certification  string `json:"certification,omitempty"`
	YearObtained   int    `json:"year_obtained,omitempty"`
	InstitutionID  int    `json:"institution_id,omitempty"`
}

type QualificationModel struct {
	DB *sql.DB
}

func (m *QualificationModel) Insert(q *Qualification) error {
	query := `INSERT INTO qualifications (teacher_id, institution, specialization, certification, year_obtained, institution_id) VALUES ($1,$2,$3,$4,$5,$6) RETURNING qualification_id`

	var year interface{}
	if q.YearObtained > 0 {
		year = q.YearObtained
	} else {
		year = nil
	}

	var inst interface{}
	if q.InstitutionID > 0 {
		inst = q.InstitutionID
	} else {
		inst = nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return m.DB.QueryRowContext(ctx, query, q.TeacherID, q.Institution, q.Specialization, q.Certification, year, inst).Scan(&q.ID)
}

func (m *QualificationModel) GetByTeacher(teacherID int) ([]*Qualification, error) {
	query := `SELECT qualification_id, teacher_id, institution, specialization, certification, year_obtained, institution_id FROM qualifications WHERE teacher_id = $1 ORDER BY year_obtained DESC NULLS LAST`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	rows, err := m.DB.QueryContext(ctx, query, teacherID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	res := []*Qualification{}
	for rows.Next() {
		var q Qualification
		var year sql.NullInt64
		var inst sql.NullInt64
		if err := rows.Scan(&q.ID, &q.TeacherID, &q.Institution, &q.Specialization, &q.Certification, &year, &inst); err != nil {
			return nil, err
		}
		if year.Valid {
			q.YearObtained = int(year.Int64)
		}
		if inst.Valid {
			q.InstitutionID = int(inst.Int64)
		}
		res = append(res, &q)
	}
	if err = rows.Err(); err != nil {
		return nil, err
	}
	return res, nil
}

func (m *QualificationModel) Delete(id int) error {
	if id < 1 {
		return ErrRecordNotFound
	}
	query := `DELETE FROM qualifications WHERE qualification_id = $1`

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
