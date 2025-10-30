package data

import (
	"context"
	"database/sql"
	"errors"
	"time"
)

type AuthToken struct {
	ID        int       `json:"token_id"`
	UserID    int       `json:"user_id"`
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expires_at"`
	CreatedAt time.Time `json:"created_at"`
	Revoked   bool      `json:"revoked"`
}

type AuthTokenModel struct {
	DB *sql.DB
}

func (m *AuthTokenModel) Insert(t *AuthToken) error {
	query := `INSERT INTO auth_tokens (user_id, token, expires_at) VALUES ($1,$2,$3) RETURNING token_id, created_at`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return m.DB.QueryRowContext(ctx, query, t.UserID, t.Token, t.ExpiresAt).Scan(&t.ID, &t.CreatedAt)
}

func (m *AuthTokenModel) GetByToken(token string) (*AuthToken, error) {
	query := `SELECT token_id, user_id, token, expires_at, created_at, revoked FROM auth_tokens WHERE token = $1`

	var t AuthToken
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := m.DB.QueryRowContext(ctx, query, token).Scan(&t.ID, &t.UserID, &t.Token, &t.ExpiresAt, &t.CreatedAt, &t.Revoked)
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}
	return &t, nil
}

func (m *AuthTokenModel) Delete(id int) error {
	if id < 1 {
		return ErrRecordNotFound
	}
	query := `DELETE FROM auth_tokens WHERE token_id = $1`
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
