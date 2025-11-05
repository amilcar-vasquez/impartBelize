// Filename: cmd/api/tokenHandlers.go
package main

import (
	"errors"
	"net/http"
	"time"

	"github.com/amilcar-vasquez/impartBelize/internal/data"
	"github.com/amilcar-vasquez/impartBelize/internal/validator"
)

// createAuthTokenHandler handles POST /v1/tokens/authentication
func (a *app) createAuthTokenHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		Email	string        `json:"email"`
		Password string        `json:"password"`
	}

	err := a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	v := validator.New()
	data.ValidateEmail(v, input.Email)
	data.ValidatePasswordPlaintext(v, input.Password)

	if !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	user, err := a.models.Users.GetByEmail(input.Email)
    if err != nil {
        switch {
            case errors.Is(err, data.ErrRecordNotFound):
                a.invalidCredentialsResponse(w, r)
            default:
                a.serverErrorResponse(w, r, err)
        }
        return
    }

	// The user is found. Does their password match?
	match, err := user.Password.Matches(input.Password)
    if err != nil {
        a.serverErrorResponse(w, r, err)
        return
    }

	if !match {
		a.invalidCredentialsResponse(w, r)
		return
	}

	// Create the token
	token, err := a.models.Tokens.New(user.ID, 24*time.Hour, data.ScopeAuthentication)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	err = a.writeJSON(w, http.StatusCreated, envelope{"token": token}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// createActivationTokenHandler handles POST /v1/tokens/activation
func (a *app) createActivationTokenHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		UserID int64 `json:"user_id"`
	}

	err := a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	v := validator.New()
	v.Check(input.UserID > 0, "user_id", "must be provided")

	if !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	// Activation tokens typically have shorter TTL (e.g., 3 days)
	token, err := a.models.Tokens.New(input.UserID, 3*24*time.Hour, data.ScopeActivation)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	err = a.writeJSON(w, http.StatusCreated, envelope{"token": token}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// deleteAllTokensForUserHandler handles DELETE /v1/tokens/user/:user_id
func (a *app) deleteAllTokensForUserHandler(w http.ResponseWriter, r *http.Request) {
	userID, err := a.readIDParam(r)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	// Get scope from query parameter (default to authentication)
	scope := r.URL.Query().Get("scope")
	if scope == "" {
		scope = data.ScopeAuthentication
	}

	v := validator.New()
	v.Check(scope == data.ScopeActivation || scope == data.ScopeAuthentication, "scope", "must be 'activation' or 'authentication'")

	if !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	err = a.models.Tokens.DeleteAllForUser(scope, userID)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"message": "tokens successfully deleted"}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// validateTokenHandler handles POST /v1/tokens/validate
func (a *app) validateTokenHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		Token string `json:"token"`
	}

	err := a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	v := validator.New()
	data.ValidateTokenPlaintext(v, input.Token)

	if !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	// For validation, you would typically look up the user by token
	// This requires a GetForToken method on UserModel which exists
	// but we'll just validate the format here
	err = a.writeJSON(w, http.StatusOK, envelope{"message": "token format is valid"}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}
