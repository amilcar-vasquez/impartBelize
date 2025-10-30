// Filename: internal/data/roles.go
package data

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/amilcar-vasquez/impartBelize/internal/validator"
)

// Role struct represents a system role
type Role struct {
	ID       int    `json:"id"`
	RoleName string `json:"role_name"`
}

// ValidateRole validates a role struct
func ValidateRole(v *validator.Validator, role *Role) {
	v.Check(role.RoleName != "", "role_name", "must be provided")
	v.Check(len(role.RoleName) <= 50, "role_name", "must not be more than 50 characters long")
}

// RoleModel wraps a database connection pool
type RoleModel struct {
	DB *sql.DB
}

// Insert a new role record in the database
func (r *RoleModel) Insert(role *Role) error {
	query := `
		INSERT INTO roles (role_name)
		VALUES ($1)
		RETURNING role_id`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return r.DB.QueryRowContext(ctx, query, role.RoleName).Scan(&role.ID)
}

// Get retrieves a specific role based on its ID
func (r *RoleModel) Get(id int) (*Role, error) {
	if id < 1 {
		return nil, ErrRecordNotFound
	}

	query := `
		SELECT role_id, role_name
		FROM roles
		WHERE role_id = $1`

	var role Role

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := r.DB.QueryRowContext(ctx, query, id).Scan(
		&role.ID,
		&role.RoleName,
	)

	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}

	return &role, nil
}

// GetByName retrieves a role by its name (useful for authentication)
func (r *RoleModel) GetByName(name string) (*Role, error) {
	query := `
		SELECT role_id, role_name
		FROM roles
		WHERE role_name = $1`

	var role Role

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := r.DB.QueryRowContext(ctx, query, name).Scan(
		&role.ID,
		&role.RoleName,
	)

	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}

	return &role, nil
}

// GetAll retrieves all roles from the database
func (r *RoleModel) GetAll() ([]*Role, error) {
	query := `
		SELECT role_id, role_name
		FROM roles
		ORDER BY role_name`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	rows, err := r.DB.QueryContext(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	roles := []*Role{}

	for rows.Next() {
		var role Role

		err := rows.Scan(
			&role.ID,
			&role.RoleName,
		)
		if err != nil {
			return nil, err
		}

		roles = append(roles, &role)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return roles, nil
}

// Update an existing role record in the database
func (r *RoleModel) Update(role *Role) error {
	query := `
		UPDATE roles
		SET role_name = $2
		WHERE role_id = $1`

	args := []interface{}{
		role.ID,
		role.RoleName,
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	_, err := r.DB.ExecContext(ctx, query, args...)
	return err
}

// Delete removes a role record from the database
func (r *RoleModel) Delete(id int) error {
	if id < 1 {
		return ErrRecordNotFound
	}

	query := `DELETE FROM roles WHERE role_id = $1`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	result, err := r.DB.ExecContext(ctx, query, id)
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
