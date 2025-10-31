// Filename: cmd/api/userHandlers.go

package main

import (
	"errors"
	"net/http"
	"time"

	"github.com/amilcar-vasquez/impartBelize/internal/data"
	"github.com/amilcar-vasquez/impartBelize/internal/validator"
)

// register a user
func (a *app) registerUserHandler(w http.ResponseWriter, r *http.Request) {
	// Get the passed in data from the request body and store in a temporary struct
	var incomingData struct {
		Username string `json:"username"`
		Password string `json:"password"`
		Email    string `json:"email"`
		RoleID   *int   `json:"role_id,omitempty"`
	}
	err := a.readJSON(w, r, &incomingData)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	// Create a new User struct and copy the data from the temporary struct to the new User struct
	user := &data.User{
		Username:    incomingData.Username,
		Email:       incomingData.Email,
		RoleID:      3,     // Default role (keep same default as before)
		IsActive:    false, // Must activate via email
		IsActivated: false,
	}
	if incomingData.RoleID != nil {
		user.RoleID = *incomingData.RoleID
	}

	// hash the password and store it (sets plaintext pointer too)
	err = user.Password.Set(incomingData.Password)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	// Validate the user data
	v := validator.New()
	if data.ValidateUser(v, user); !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	// Try to insert the user data into the database
	err = a.models.Users.Insert(user)
	if err != nil {
		switch {
		case errors.Is(err, data.ErrDuplicateEmail):
			v.AddError("email", "email address already in use")
			a.failedValidationResponse(w, r, v.Errors)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	// Generate a new activation token which expires in 3 days
	token, err := a.models.Tokens.New(user.ID, 3*24*time.Hour, data.ScopeActivation)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	response := envelope{
		"user": user,
	}

	a.background(func() {
		data := map[string]any{
			"activationToken": token.Plaintext,
			"userID":          user.ID,
		}

		err = a.mailer.Send(user.Email, "user_welcome.tmpl", data)
		if err != nil {
			a.logger.Error(err.Error())
		}
	})

	err = a.writeJSON(w, http.StatusCreated, response, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}
}

func (a *app) activateUserHandler(w http.ResponseWriter, r *http.Request) {
	// Get the body from the request and store in temporary struct
	var incomingData struct {
		TokenPlaintext string `json:"token"`
	}
	err := a.readJSON(w, r, &incomingData)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	// Validate the data
	v := validator.New()
	data.ValidateTokenPlaintext(v, incomingData.TokenPlaintext)
	if !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}
	// Let's check if the token provided belongs to the user
	user, err := a.models.Users.GetForToken(data.ScopeActivation,
		incomingData.TokenPlaintext)

	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			v.AddError("token", "invalid or expired activation token")
			a.failedValidationResponse(w, r, v.Errors)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	// User provided the right token so activate them
	a.logger.Info("Activating user", "user_id", user.ID, "username", user.Username, "email", user.Email)
	err = a.models.Users.UpdateActivation(user.ID, true)
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			v.AddError("token", "user not found")
			a.failedValidationResponse(w, r, v.Errors)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	// Update the user object for the response
	user.IsActive = true

	// User has been activated so delete the activation token to
	// prevent reuse.
	err = a.models.Tokens.DeleteAllForUser(data.ScopeActivation, user.ID)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	// Send a response
	data := envelope{
		"user": user,
	}

	err = a.writeJSON(w, http.StatusOK, data, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getUserHandler retrieves a specific user by ID
func (a *app) getUserHandler(w http.ResponseWriter, r *http.Request) {
	// Get the ID from the URL
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	// Get the current user from context
	currentUser := a.contextGetUser(r)

	// Check if the current user can access this user's data
	canAccess, err := a.canAccessUserData(currentUser, id)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	if !canAccess {
		a.notPermittedResponse(w, r)
		return
	}

	// Try to get the user from the database
	user, err := a.models.Users.Get(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	response := envelope{
		"user": user,
	}
	err = a.writeJSON(w, http.StatusOK, response, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getUserByEmailHandler retrieves a user by email (useful for authentication)
func (a *app) getUserByEmailHandler(w http.ResponseWriter, r *http.Request) {
	// Get email from query parameters
	email := r.URL.Query().Get("email")
	if email == "" {
		a.badRequestResponse(w, r, errors.New("email parameter is required"))
		return
	}

	// Try to get the user from the database
	user, err := a.models.Users.GetByEmail(email)
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	response := envelope{
		"user": user,
	}
	err = a.writeJSON(w, http.StatusOK, response, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getAllUsersHandler retrieves all users with pagination and filtering, or a specific user by email
func (a *app) getAllUsersHandler(w http.ResponseWriter, r *http.Request) {
	qs := r.URL.Query()

	// Check if this is an email lookup request
	if email := qs.Get("email"); email != "" {
		a.getUserByEmailHandler(w, r)
		return
	}

	// Parse query parameters for pagination and filtering
	var input struct {
		RegionID    int
		FormationID int
		RankID      int
		IsActive    *bool
		LastName    string
		Username    string
		data.Filters
	}

	v := validator.New()

	// Parse filter parameters
	input.RegionID = a.getSingleIntegerParameter(qs, "region_id", 0, v)
	input.FormationID = a.getSingleIntegerParameter(qs, "formation_id", 0, v)
	input.RankID = a.getSingleIntegerParameter(qs, "rank_id", 0, v)
	input.LastName = a.getSingleQueryParameter(qs, "last_name", "")
	input.Username = a.getSingleQueryParameter(qs, "username", "")

	// Parse is_active parameter
	if activeStr := qs.Get("is_active"); activeStr != "" {
		if activeStr == "true" {
			active := true
			input.IsActive = &active
		} else if activeStr == "false" {
			active := false
			input.IsActive = &active
		} else {
			v.AddError("is_active", "must be true or false")
		}
	}

	// Parse pagination parameters
	input.Filters.Page = a.getSingleIntegerParameter(qs, "page", 1, v)
	input.Filters.PageSize = a.getSingleIntegerParameter(qs, "page_size", 20, v)

	// Parse sort parameter
	input.Filters.Sort = a.getSingleQueryParameter(qs, "sort", "id")
	input.Filters.SortSafelist = []string{"id", "user_id", "last_name", "first_name", "username", "email", "created_at", "-id", "-user_id", "-last_name", "-first_name", "-username", "-email", "-created_at"}

	// Validate filters
	if data.ValidateFilters(v, input.Filters); !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	// Get users from database
	users, metadata, err := a.models.Users.GetAll(input.RegionID, input.FormationID, input.RankID, input.IsActive, input.LastName, input.Username, input.Filters)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	response := envelope{
		"users":    users,
		"metadata": metadata,
	}
	err = a.writeJSON(w, http.StatusOK, response, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// updateUserHandler updates an existing user
func (a *app) updateUserHandler(w http.ResponseWriter, r *http.Request) {
	// Get the ID from the URL
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	// Get the current user from context
	currentUser := a.contextGetUser(r)

	// Check if the current user can access this user's data
	canAccess, err := a.canAccessUserData(currentUser, id)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	if !canAccess {
		a.notPermittedResponse(w, r)
		return
	}

	// Get the existing user from the database
	user, err := a.models.Users.Get(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	// Parse the request body for updates
	var input struct {
		Username    *string `json:"username"`
		Password    *string `json:"password"`
		Email       *string `json:"email"`
		RoleID      *int    `json:"role_id"`
		IsActive    *bool   `json:"is_active"`
		IsActivated *bool   `json:"is_activated"`
	}

	err = a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	// Check if user is trying to update role_id/is_active/is_activated and is not an Administrator
	if input.RoleID != nil || input.IsActive != nil || input.IsActivated != nil {
		// Get the current user's role
		currentUserRole, err := a.models.Roles.Get(currentUser.RoleID)
		if err != nil {
			a.serverErrorResponse(w, r, err)
			return
		}

		// Only Administrators can change roles or activation status
		if currentUserRole.RoleName != "Administrator" && currentUserRole.RoleName != "admin" {
			v := validator.New()
			if input.RoleID != nil {
				v.AddError("role_id", "only administrators can change user roles")
			}
			if input.IsActive != nil {
				v.AddError("is_active", "only administrators can change user activation status")
			}
			if input.IsActivated != nil {
				v.AddError("is_activated", "only administrators can change activation status")
			}
			a.failedValidationResponse(w, r, v.Errors)
			return
		}
	}

	// Update only the fields that were provided
	if input.Username != nil {
		user.Username = *input.Username
	}
	if input.Email != nil {
		user.Email = *input.Email
	}
	if input.RoleID != nil {
		user.RoleID = *input.RoleID
	}
	if input.IsActive != nil {
		user.IsActive = *input.IsActive
	}
	if input.IsActivated != nil {
		user.IsActivated = *input.IsActivated
	}

	// Update password if provided
	if input.Password != nil {
		err = user.Password.Set(*input.Password)
		if err != nil {
			a.serverErrorResponse(w, r, err)
			return
		}
	}

	// Validate the updated user data
	v := validator.New()
	if data.ValidateUser(v, user); !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	// Try to update the user in the database
	err = a.models.Users.Update(user)
	if err != nil {
		switch {
		case errors.Is(err, data.ErrDuplicateEmail):
			v.AddError("email", "email address already in use")
			a.failedValidationResponse(w, r, v.Errors)
		case errors.Is(err, data.ErrEditConflict):
			a.editConflictResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	response := envelope{
		"user": user,
	}
	err = a.writeJSON(w, http.StatusOK, response, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// deleteUserHandler soft deletes a user (sets is_active to false)
func (a *app) deleteUserHandler(w http.ResponseWriter, r *http.Request) {
	// Get the ID from the URL
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	// Try to delete the user from the database
	err = a.models.Users.Delete(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	response := envelope{
		"message": "user successfully deleted",
	}
	err = a.writeJSON(w, http.StatusOK, response, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}
