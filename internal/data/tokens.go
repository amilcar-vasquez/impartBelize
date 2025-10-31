package data

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"encoding/base32"
	"time"

	"github.com/amilcar-vasquez/impartBelize/internal/validator"
)

// Purpose of the token
const ScopeActivation = "activation"
const ScopeAuthentication = "authentication"

// Define our token
type Token struct {
    Plaintext string      `json:"token"`     
    Hash      []byte      `json:"-"`
    UserID    int64       `json:"-"`
    Expiry    time.Time   `json:"expiry"`
    Scope     string      `json:"-"`
}


// Generate a token for the user
func generateToken(userID int64, ttl time.Duration, scope string) (*Token, error) {
    token := &Token {
        UserID: userID,
        Expiry: time.Now().Add(ttl),
        Scope: scope,
    }
	// Generate the actual token. We create a byte slice and fill it
	// with random values (rand.Read)
	randomBytes := make([]byte, 16)
	_, err := rand.Read(randomBytes)
	if err != nil {
	return nil, err
	}
	// Encode the random bytes using base-32
	token.Plaintext = base32.StdEncoding.WithPadding(base32.NoPadding).EncodeToString(randomBytes)
	// Now we hash the encoding. 
	hash := sha256.Sum256([]byte(token.Plaintext))
	token.Hash = hash[:]                    // array to slice conversion


	return token,  nil
}


// Validate the token the client sends back to us to be 26 bytes long
func ValidateTokenPlaintext(v *validator.Validator, tokenPlaintext string) {
    v.Check(tokenPlaintext != "", "token", "must be provided")
    v.Check(len(tokenPlaintext) == 26, "token", "must be 26 bytes long")
}

// Our access to the database
type TokenModel struct {
    DB *sql.DB
}
// The New() method creates and returns a new token. It calls Insert() as a 
// helper method
func (t TokenModel) New(userID int64, ttl time.Duration, scope string) (*Token, error) {
	token, err := generateToken(userID, ttl, scope)
	if err != nil {
		return nil, err
	}

	err = t.Insert(token)
	return token, err
}

// Do the actual insert in to the database table
func (t TokenModel) Insert(token *Token) error {
    query := `
              INSERT INTO tokens (hash, user_id, expiry, scope) 
              VALUES ($1, $2, $3, $4)
            `
	args := []any{token.Hash, token.UserID, token.Expiry, token.Scope}
	
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	_, err := t.DB.ExecContext(ctx, query, args...)
	return err
}

// Delete a token based on the type and the user
func (t TokenModel) DeleteAllForUser(scope string, userID int64) error {
	query := `
            DELETE FROM tokens 
            WHERE scope = $1 AND user_id = $2
			`
    ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
    defer cancel()

    _, err := t.DB.ExecContext(ctx, query, scope, userID)
    return err
}
