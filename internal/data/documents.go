package data

import (
	"context"
	"database/sql"
	"errors"
	"time"
)

type Document struct {
	ID            int       `json:"document_id"`
	TeacherID     int       `json:"teacher_id"`
	UploadedBy    int       `json:"uploaded_by,omitempty"`
	ApplicationID int       `json:"application_id,omitempty"`
	DocType       string    `json:"doc_type"`
	FilePath      string    `json:"file_path"`
	Verified      bool      `json:"verified"`
	VerifiedBy    int       `json:"verified_by,omitempty"`
	Remarks       string    `json:"remarks,omitempty"`
	UploadedAt    time.Time `json:"uploaded_at"`
}

type DocumentModel struct {
	DB *sql.DB
}

func (m *DocumentModel) Insert(d *Document) error {
	query := `INSERT INTO documents (teacher_id, uploaded_by, application_id, doc_type, file_path, verified, verified_by, remarks) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING document_id, uploaded_at`

	var uploadedBy interface{}
	if d.UploadedBy > 0 {
		uploadedBy = d.UploadedBy
	} else {
		uploadedBy = nil
	}
	var appID interface{}
	if d.ApplicationID > 0 {
		appID = d.ApplicationID
	} else {
		appID = nil
	}
	var verifiedBy interface{}
	if d.VerifiedBy > 0 {
		verifiedBy = d.VerifiedBy
	} else {
		verifiedBy = nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return m.DB.QueryRowContext(ctx, query, d.TeacherID, uploadedBy, appID, d.DocType, d.FilePath, d.Verified, verifiedBy, d.Remarks).Scan(&d.ID, &d.UploadedAt)
}

func (m *DocumentModel) Get(id int) (*Document, error) {
	if id < 1 {
		return nil, ErrRecordNotFound
	}
	query := `SELECT document_id, teacher_id, uploaded_by, application_id, doc_type, file_path, verified, verified_by, remarks, uploaded_at FROM documents WHERE document_id = $1`

	var d Document
	var uploadedBy sql.NullInt64
	var appID sql.NullInt64
	var verifiedBy sql.NullInt64

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := m.DB.QueryRowContext(ctx, query, id).Scan(&d.ID, &d.TeacherID, &uploadedBy, &appID, &d.DocType, &d.FilePath, &d.Verified, &verifiedBy, &d.Remarks, &d.UploadedAt)
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}
	if uploadedBy.Valid {
		d.UploadedBy = int(uploadedBy.Int64)
	}
	if appID.Valid {
		d.ApplicationID = int(appID.Int64)
	}
	if verifiedBy.Valid {
		d.VerifiedBy = int(verifiedBy.Int64)
	}
	return &d, nil
}

func (m *DocumentModel) GetByTeacher(teacherID int) ([]*Document, error) {
	query := `SELECT document_id, teacher_id, uploaded_by, application_id, doc_type, file_path, verified, verified_by, remarks, uploaded_at FROM documents WHERE teacher_id = $1 ORDER BY uploaded_at DESC`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	rows, err := m.DB.QueryContext(ctx, query, teacherID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []*Document{}
	for rows.Next() {
		var d Document
		var uploadedBy sql.NullInt64
		var appID sql.NullInt64
		var verifiedBy sql.NullInt64
		if err := rows.Scan(&d.ID, &d.TeacherID, &uploadedBy, &appID, &d.DocType, &d.FilePath, &d.Verified, &verifiedBy, &d.Remarks, &d.UploadedAt); err != nil {
			return nil, err
		}
		if uploadedBy.Valid {
			d.UploadedBy = int(uploadedBy.Int64)
		}
		if appID.Valid {
			d.ApplicationID = int(appID.Int64)
		}
		if verifiedBy.Valid {
			d.VerifiedBy = int(verifiedBy.Int64)
		}
		out = append(out, &d)
	}
	if err = rows.Err(); err != nil {
		return nil, err
	}
	return out, nil
}

func (m *DocumentModel) Delete(id int) error {
	if id < 1 {
		return ErrRecordNotFound
	}
	query := `DELETE FROM documents WHERE document_id = $1`
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
