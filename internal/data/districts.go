package data

import (
	"context"
	"database/sql"
	"errors"
	"time"
)

// District represents an administrative district
type District struct {
	ID   int    `json:"district_id"`
	Name string `json:"name"`
}

// DistrictModel wraps a DB connection
type DistrictModel struct {
	DB *sql.DB
}

// Insert adds a district
func (m *DistrictModel) Insert(d *District) error {
	query := `INSERT INTO districts (name) VALUES ($1) RETURNING district_id`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return m.DB.QueryRowContext(ctx, query, d.Name).Scan(&d.ID)
}

// Get returns a district by id
func (m *DistrictModel) Get(id int) (*District, error) {
	if id < 1 {
		return nil, ErrRecordNotFound
	}

	query := `SELECT district_id, name FROM districts WHERE district_id = $1`

	var d District
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := m.DB.QueryRowContext(ctx, query, id).Scan(&d.ID, &d.Name)
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}
	return &d, nil
}

// GetAll returns all districts
func (m *DistrictModel) GetAll() ([]*District, error) {
	query := `SELECT district_id, name FROM districts ORDER BY name`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	rows, err := m.DB.QueryContext(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	districts := []*District{}
	for rows.Next() {
		var d District
		if err := rows.Scan(&d.ID, &d.Name); err != nil {
			return nil, err
		}
		districts = append(districts, &d)
	}
	if err = rows.Err(); err != nil {
		return nil, err
	}
	return districts, nil
}

// Delete removes a district
func (m *DistrictModel) Delete(id int) error {
	if id < 1 {
		return ErrRecordNotFound
	}
	query := `DELETE FROM districts WHERE district_id = $1`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	result, err := m.DB.ExecContext(ctx, query, id)
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
