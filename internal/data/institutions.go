package data

import (
	"context"
	"database/sql"
	"errors"
	"time"
)

// Institution represents an educational institution
type Institution struct {
	ID              int    `json:"institution_id"`
	Name            string `json:"name"`
	DistrictID      int    `json:"district_id,omitempty"`
	InstitutionType string `json:"institution_type,omitempty"`
}

type InstitutionModel struct {
	DB *sql.DB
}

func (m *InstitutionModel) Insert(i *Institution) error {
	query := `INSERT INTO institutions (name, district_id, institution_type) VALUES ($1, $2, $3) RETURNING institution_id`

	var district interface{}
	if i.DistrictID > 0 {
		district = i.DistrictID
	} else {
		district = nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return m.DB.QueryRowContext(ctx, query, i.Name, district, i.InstitutionType).Scan(&i.ID)
}

func (m *InstitutionModel) Get(id int) (*Institution, error) {
	if id < 1 {
		return nil, ErrRecordNotFound
	}
	query := `SELECT institution_id, name, district_id, institution_type FROM institutions WHERE institution_id = $1`

	var ins Institution
	var district sql.NullInt64
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := m.DB.QueryRowContext(ctx, query, id).Scan(&ins.ID, &ins.Name, &district, &ins.InstitutionType)
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}
	if district.Valid {
		ins.DistrictID = int(district.Int64)
	}
	return &ins, nil
}

func (m *InstitutionModel) GetAll() ([]*Institution, error) {
	query := `SELECT institution_id, name, district_id, institution_type FROM institutions ORDER BY name`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	rows, err := m.DB.QueryContext(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []*Institution{}
	for rows.Next() {
		var ins Institution
		var district sql.NullInt64
		if err := rows.Scan(&ins.ID, &ins.Name, &district, &ins.InstitutionType); err != nil {
			return nil, err
		}
		if district.Valid {
			ins.DistrictID = int(district.Int64)
		}
		out = append(out, &ins)
	}
	if err = rows.Err(); err != nil {
		return nil, err
	}
	return out, nil
}

func (m *InstitutionModel) Delete(id int) error {
	if id < 1 {
		return ErrRecordNotFound
	}
	query := `DELETE FROM institutions WHERE institution_id = $1`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	res, err := m.DB.ExecContext(ctx, query, id)
	if err != nil {
		return err
	}
	rowsAffected, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rowsAffected == 0 {
		return ErrRecordNotFound
	}
	return nil
}
