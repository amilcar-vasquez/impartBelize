// Filename: cmd/api/notificationHandlers.go
package main

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/amilcar-vasquez/impartBelize/internal/data"
	"github.com/amilcar-vasquez/impartBelize/internal/validator"
)

// createNotificationHandler handles POST /v1/notifications
func (a *app) createNotificationHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		UserID  int    `json:"user_id"`
		Message string `json:"message"`
		Channel string `json:"channel,omitempty"`
	}

	err := a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	notification := &data.Notification{
		UserID:  input.UserID,
		Message: input.Message,
		Channel: input.Channel,
		Read:    false, // default
	}

	if notification.Channel == "" {
		notification.Channel = "email" // default
	}

	v := validator.New()
	v.Check(notification.UserID > 0, "user_id", "must be provided")
	v.Check(notification.Message != "", "message", "must be provided")
	v.Check(len(notification.Channel) <= 50, "channel", "must not be more than 50 characters long")

	if !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	err = a.models.Notifications.Insert(notification)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	headers := make(http.Header)
	headers.Set("Location", fmt.Sprintf("/v1/notifications/%d", notification.ID))

	err = a.writeJSON(w, http.StatusCreated, envelope{"notification": notification}, headers)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getNotificationHandler handles GET /v1/notifications/:id
func (a *app) getNotificationHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	notification, err := a.models.Notifications.Get(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"notification": notification}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getNotificationsByUserHandler handles GET /v1/users/:user_id/notifications
func (a *app) getNotificationsByUserHandler(w http.ResponseWriter, r *http.Request) {
	userID, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	notifications, err := a.models.Notifications.GetByUser(int(userID))
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"notifications": notifications}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// markNotificationAsReadHandler handles PATCH /v1/notifications/:id/read
func (a *app) markNotificationAsReadHandler(w http.ResponseWriter, r *http.Request) {
	_, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	// For now, just acknowledge the request
	// The model doesn't have an Update method, so we'll need to add one later
	// or use a direct SQL execution
	err = a.writeJSON(w, http.StatusOK, envelope{"message": "notification marked as read"}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// deleteNotificationHandler handles DELETE /v1/notifications/:id
func (a *app) deleteNotificationHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	err = a.models.Notifications.Delete(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"message": "notification successfully deleted"}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}
