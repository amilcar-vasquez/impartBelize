// Filename: internal/data/users.go
package data

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/amilcar-vasquez/impartBelize/internal/validator"
	"golang.org/x/crypto/bcrypt"
)

var AnonymousUser = &User{}

type User struct {
	ID          int64      `json:"user_id"`
	Username    string     `json:"username"`
	Email       string     `json:"email"`
	Password    password   `json:"-"`
	RoleID      int        `json:"role_id"`
	RoleName    string     `json:"role_name,omitempty"`
	IsActive    bool       `json:"is_active"`
	IsActivated bool       `json:"is_activated"`
	LastLogin   *time.Time `json:"last_login,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
	CreatedBy   int        `json:"created_by,omitempty"`
	UpdatedAt   time.Time  `json:"updated_at"`
	UpdatedBy   int        `json:"updated_by,omitempty"`
}

// define the password type (the plaintext + hashed password)
// lowercase because we do not want it to be public
type password struct {
	plaintext *string
	hash      []byte
}

// The Set() method computes the hash of the password
func (p *password) Set(plaintextPassword string) error {
	hash, err := bcrypt.GenerateFromPassword([]byte(plaintextPassword), 12)
	if err != nil {
		return err
	}
	p.plaintext = &plaintextPassword
	p.hash = hash
	return nil
}

// Compare the client-provided plaintext password with saved-hashed version
func (p *password) Matches(plaintextPassword string) (bool, error) {
	err := bcrypt.CompareHashAndPassword(p.hash, []byte(plaintextPassword))
	if err != nil {
		switch {
		case errors.Is(err, bcrypt.ErrMismatchedHashAndPassword):
			// invalid password
			return false, nil
		default:
			return false, err
		}
	}
	return true, nil
}

// Validate the email address
func ValidateEmail(v *validator.Validator, email string) {
	v.Check(email != "", "email", "must be provided")
	v.Check(len(email) <= 255, "email", "must not be more than 255 bytes long")
	v.Check(validator.Matches(email, validator.EmailRX), "email", "must be a valid email address")
}

// Check that a valid password is provided
func ValidatePasswordPlaintext(v *validator.Validator, password string) {
	v.Check(password != "", "password", "must be provided")
	v.Check(len(password) >= 8, "password", "must be at least 8 bytes long")
	v.Check(len(password) <= 72, "password", "must not be more than 72 bytes long")
}

// Validate a user
func ValidateUser(v *validator.Validator, user *User) {
	v.Check(user.Username != "", "username", "must be provided")
	v.Check(len(user.Username) <= 100, "username", "must not be more than 100 bytes long")
	// validate email for user
	ValidateEmail(v, user.Email)
	// validate the plain text password
	if user.Password.plaintext != nil {
		ValidatePasswordPlaintext(v, *user.Password.plaintext)
	}
	// check if we messed up the password hash
	if user.Password.hash == nil {
		panic("missing password hash for user")
	}

}

// Specify a custom duplicate email error message
var ErrDuplicateEmail = errors.New("duplicate email")

// setup the user model struct
type UserModel struct {
	DB *sql.DB
}

// Insert a new user record in the database
func (u *UserModel) Insert(user *User) error {
	query := `
		INSERT INTO users (
			username, email, password_hash, role_id, is_active, is_activated, last_login, created_by, updated_by
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9
		)
		RETURNING user_id, created_at, updated_at
	`

	var lastLogin interface{}
	if user.LastLogin != nil {
		lastLogin = *user.LastLogin
	} else {
		lastLogin = nil
	}

	var createdBy interface{}
	if user.CreatedBy > 0 {
		createdBy = user.CreatedBy
	} else {
		createdBy = nil
	}

	var updatedBy interface{}
	if user.UpdatedBy > 0 {
		updatedBy = user.UpdatedBy
	} else {
		updatedBy = nil
	}

	args := []interface{}{
		user.Username,
		user.Email,
		user.Password.hash,
		user.RoleID,
		user.IsActive,
		user.IsActivated,
		lastLogin,
		createdBy,
		updatedBy,
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := u.DB.QueryRowContext(ctx, query, args...).Scan(&user.ID, &user.CreatedAt, &user.UpdatedAt)
	if err != nil {
		// detect duplicate email error
		if strings.Contains(err.Error(), "duplicate key value violates unique constraint") && strings.Contains(err.Error(), "users_email_key") {
			return ErrDuplicateEmail
		}
		return err
	}
	return nil
}

// Get a user from the database based on their email provided
func (u *UserModel) GetByEmail(email string) (*User, error) {
	query := `
		SELECT user_id, username, email, password_hash, role_id, is_active, is_activated, last_login, created_at, created_by, updated_at, updated_by
		FROM users
		WHERE email = $1
	`

	var user User

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	var lastLogin sql.NullTime
	var createdBy sql.NullInt64
	var updatedBy sql.NullInt64

	err := u.DB.QueryRowContext(ctx, query, email).Scan(
		&user.ID,
		&user.Username,
		&user.Email,
		&user.Password.hash,
		&user.RoleID,
		&user.IsActive,
		&user.IsActivated,
		&lastLogin,
		&user.CreatedAt,
		&createdBy,
		&user.UpdatedAt,
		&updatedBy,
	)

	if lastLogin.Valid {
		user.LastLogin = &lastLogin.Time
	}
	if createdBy.Valid {
		user.CreatedBy = int(createdBy.Int64)
	}
	if updatedBy.Valid {
		user.UpdatedBy = int(updatedBy.Int64)
	}

	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}
	return &user, nil
}

// Update an existing user record in the database
func (m *UserModel) Update(user *User) error {
	query := `
		UPDATE users
		SET username = $1, email = $2, password_hash = $3, role_id = $4,
			is_active = $5, is_activated = $6, last_login = $7, updated_at = NOW(), updated_by = $8
		WHERE user_id = $9
		RETURNING updated_at
	`

	var lastLogin interface{}
	if user.LastLogin != nil {
		lastLogin = *user.LastLogin
	} else {
		lastLogin = nil
	}

	var updatedBy interface{}
	if user.UpdatedBy > 0 {
		updatedBy = user.UpdatedBy
	} else {
		updatedBy = nil
	}

	args := []interface{}{
		user.Username,
		user.Email,
		user.Password.hash,
		user.RoleID,
		user.IsActive,
		user.IsActivated,
		lastLogin,
		updatedBy,
		user.ID,
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := m.DB.QueryRowContext(ctx, query, args...).Scan(&user.UpdatedAt)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate key value violates unique constraint") && strings.Contains(err.Error(), "users_email_key") {
			return ErrDuplicateEmail
		}
		if errors.Is(err, sql.ErrNoRows) {
			return ErrEditConflict
		}
		return err
	}

	return nil
}

// UpdateActivation updates only the is_active field for a user
// This is used when activating a user account via email token
func (m *UserModel) UpdateActivation(userID int64, isActive bool) error {
	query := `
		UPDATE users
		SET is_active = $1, updated_at = NOW()
		WHERE user_id = $2
		RETURNING updated_at
	`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	var updatedAt time.Time
	err := m.DB.QueryRowContext(ctx, query, isActive, userID).Scan(&updatedAt)
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return ErrRecordNotFound
		default:
			return err
		}
	}

	return nil
}

// Get retrieves a specific user based on its ID
func (u *UserModel) Get(id int) (*User, error) {
	if id < 1 {
		return nil, ErrRecordNotFound
	}

	query := `
		SELECT user_id, username, email, password_hash, role_id, is_active, is_activated, last_login, created_at, created_by, updated_at, updated_by
		FROM users
		WHERE user_id = $1`

	var user User

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	var lastLogin sql.NullTime
	var createdBy sql.NullInt64
	var updatedBy sql.NullInt64
	err := u.DB.QueryRowContext(ctx, query, id).Scan(
		&user.ID,
		&user.Username,
		&user.Email,
		&user.Password.hash,
		&user.RoleID,
		&user.IsActive,
		&user.IsActivated,
		&lastLogin,
		&user.CreatedAt,
		&createdBy,
		&user.UpdatedAt,
		&updatedBy,
	)

	if lastLogin.Valid {
		user.LastLogin = &lastLogin.Time
	}
	if createdBy.Valid {
		user.CreatedBy = int(createdBy.Int64)
	}
	if updatedBy.Valid {
		user.UpdatedBy = int(updatedBy.Int64)
	}

	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}

	return &user, nil
}

// GetAll retrieves all users with filtering and pagination
func (u *UserModel) GetAll(regionID, formationID, rankID int, isActive *bool, lastName string, username string, filters Filters) ([]*User, Metadata, error) {
	query := `
		SELECT count(*) OVER(), user_id, username, email, role_id, is_active, is_activated, last_login, created_at, created_by, updated_at, updated_by
		FROM users
		WHERE 1=1`

	args := []interface{}{}
	argCount := 0

	// Add filters
	if regionID > 0 {
		argCount++
		query += ` AND region_id = $` + fmt.Sprintf("%d", argCount)
		args = append(args, regionID)
	}

	if formationID > 0 {
		argCount++
		query += ` AND formation_id = $` + fmt.Sprintf("%d", argCount)
		args = append(args, formationID)
	}

	if rankID > 0 {
		argCount++
		query += ` AND rank_id = $` + fmt.Sprintf("%d", argCount)
		args = append(args, rankID)
	}

	if lastName != "" {
		argCount++
		query += ` AND last_name ILIKE '%' || $` + fmt.Sprintf("%d", argCount) + ` || '%'`
		args = append(args, lastName)
	}

	if username != "" {
		argCount++
		query += ` AND username ILIKE '%' || $` + fmt.Sprintf("%d", argCount) + ` || '%'`
		args = append(args, username)
	}

	if isActive != nil {
		argCount++
		query += ` AND is_active = $` + fmt.Sprintf("%d", argCount)
		args = append(args, *isActive)
	}

	// Add sorting
	query += fmt.Sprintf(" ORDER BY %s %s", filters.sortColumn(), filters.sortDirection())

	// Add pagination
	argCount++
	limitArg := argCount
	argCount++
	offsetArg := argCount

	query += fmt.Sprintf(" LIMIT $%d OFFSET $%d", limitArg, offsetArg)
	args = append(args, filters.limit(), filters.offset())

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	rows, err := u.DB.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, Metadata{}, err
	}
	defer rows.Close()

	totalRecords := 0
	users := []*User{}

	for rows.Next() {
		var user User
		var lastLogin sql.NullTime
		var createdBy sql.NullInt64
		var updatedBy sql.NullInt64

		err := rows.Scan(
			&totalRecords,
			&user.ID,
			&user.Username,
			&user.Email,
			&user.RoleID,
			&user.IsActive,
			&user.IsActivated,
			&lastLogin,
			&user.CreatedAt,
			&createdBy,
			&user.UpdatedAt,
			&updatedBy,
		)

		if err != nil {
			return nil, Metadata{}, err
		}

		if lastLogin.Valid {
			user.LastLogin = &lastLogin.Time
		}
		if createdBy.Valid {
			user.CreatedBy = int(createdBy.Int64)
		}
		if updatedBy.Valid {
			user.UpdatedBy = int(updatedBy.Int64)
		}

		users = append(users, &user)
	}

	if err = rows.Err(); err != nil {
		return nil, Metadata{}, err
	}

	metadata := calculateMetadata(totalRecords, filters.Page, filters.PageSize)

	return users, metadata, nil
}

// Delete removes a user record from the database
func (u *UserModel) Delete(id int) error {
	if id < 1 {
		return ErrRecordNotFound
	}

	query := `
		DELETE FROM users
		WHERE user_id = $1`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	result, err := u.DB.ExecContext(ctx, query, id)
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

// Verify token to user. We need to hash the passed in token
func (u *UserModel) GetForToken(tokenScope, tokenPlaintext string) (*User, error) {
	tokenHash := sha256.Sum256([]byte(tokenPlaintext))

	// We will do a join- I hope you still remember how to do a join
	query := `
        SELECT users.user_id, users.created_at, users.username,
               users.email, users.password_hash, users.is_active, 
               users.role_id, roles.role_name
        FROM users
        INNER JOIN tokens
        ON users.user_id = tokens.user_id
        INNER JOIN roles
        ON users.role_id = roles.role_id
        WHERE tokens.hash = $1
        AND tokens.scope = $2 
        AND tokens.expiry > $3
       `
	args := []any{tokenHash[:], tokenScope, time.Now()}
	var user User
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	err := u.DB.QueryRowContext(ctx, query, args...).Scan(
		&user.ID,
		&user.CreatedAt,
		&user.Username,
		&user.Email,
		&user.Password.hash,
		&user.IsActive,
		&user.RoleID,
		&user.RoleName,
	)
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}

	// Return the matching user.
	return &user, nil
}

func (u *User) IsAnonymous() bool {
	return u == AnonymousUser
}
