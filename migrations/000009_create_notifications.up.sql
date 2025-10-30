-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    channel VARCHAR(50) DEFAULT 'email',
    sent_at TIMESTAMP DEFAULT NOW(),
    read BOOLEAN DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
