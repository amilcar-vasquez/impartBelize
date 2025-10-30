package data

import (
	"context"
	"database/sql"
	"errors"
	"time"
)

type Notification struct {
	ID      int       `json:"notification_id"`
	UserID  int       `json:"user_id"`
	Message string    `json:"message"`
	Channel string    `json:"channel,omitempty"`
	SentAt  time.Time `json:"sent_at"`
	Read    bool      `json:"read"`
}

type NotificationModel struct {
	DB *sql.DB
}

func (m *NotificationModel) Insert(n *Notification) error {
	query := `INSERT INTO notifications (user_id, message, channel) VALUES ($1,$2,$3) RETURNING notification_id, sent_at`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return m.DB.QueryRowContext(ctx, query, n.UserID, n.Message, n.Channel).Scan(&n.ID, &n.SentAt)
}

func (m *NotificationModel) Get(id int) (*Notification, error) {
	if id < 1 {
		return nil, ErrRecordNotFound
	}
	query := `SELECT notification_id, user_id, message, channel, sent_at, read FROM notifications WHERE notification_id = $1`

	var n Notification
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := m.DB.QueryRowContext(ctx, query, id).Scan(&n.ID, &n.UserID, &n.Message, &n.Channel, &n.SentAt, &n.Read)
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}
	return &n, nil
}

func (m *NotificationModel) GetByUser(userID int) ([]*Notification, error) {
	query := `SELECT notification_id, user_id, message, channel, sent_at, read FROM notifications WHERE user_id = $1 ORDER BY sent_at DESC`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	rows, err := m.DB.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []*Notification{}
	for rows.Next() {
		var n Notification
		if err := rows.Scan(&n.ID, &n.UserID, &n.Message, &n.Channel, &n.SentAt, &n.Read); err != nil {
			return nil, err
		}
		out = append(out, &n)
	}
	if err = rows.Err(); err != nil {
		return nil, err
	}
	return out, nil
}

func (m *NotificationModel) Delete(id int) error {
	if id < 1 {
		return ErrRecordNotFound
	}
	query := `DELETE FROM notifications WHERE notification_id = $1`
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
