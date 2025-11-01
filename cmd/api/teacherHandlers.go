// Filename: cmd/api/teacherHandlers.go
package main

import (
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/amilcar-vasquez/impartBelize/internal/data"
	"github.com/amilcar-vasquez/impartBelize/internal/validator"
)

// createTeacherHandler handles POST /v1/teachers
func (a *app) createTeacherHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		UserID        int        `json:"user_id,omitempty"`
		FirstName     string     `json:"first_name"`
		LastName      string     `json:"last_name"`
		Gender        string     `json:"gender,omitempty"`
		DOB           *time.Time `json:"dob,omitempty"`
		SSN           string     `json:"ssn,omitempty"`
		MaritalStatus string     `json:"marital_status,omitempty"`
		Email         string     `json:"email"`
		Address       string     `json:"address,omitempty"`
		DistrictID    int        `json:"district_id,omitempty"`
		Phone         string     `json:"phone,omitempty"`
		ProfileStatus string     `json:"profile_status,omitempty"`
	}

	err := a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	teacher := &data.Teacher{
		UserID:        input.UserID,
		FirstName:     input.FirstName,
		LastName:      input.LastName,
		Gender:        input.Gender,
		DOB:           input.DOB,
		SSN:           input.SSN,
		MaritalStatus: input.MaritalStatus,
		Email:         input.Email,
		Address:       input.Address,
		DistrictID:    input.DistrictID,
		Phone:         input.Phone,
		ProfileStatus: input.ProfileStatus,
	}

	if teacher.ProfileStatus == "" {
		teacher.ProfileStatus = "active" // default
	}

	v := validator.New()
	v.Check(teacher.FirstName != "", "first_name", "must be provided")
	v.Check(len(teacher.FirstName) <= 100, "first_name", "must not be more than 100 characters long")
	v.Check(teacher.LastName != "", "last_name", "must be provided")
	v.Check(len(teacher.LastName) <= 100, "last_name", "must not be more than 100 characters long")
	v.Check(teacher.Email != "", "email", "must be provided")
	v.Check(len(teacher.Email) <= 100, "email", "must not be more than 100 characters long")
	v.Check(len(teacher.SSN) <= 15, "ssn", "must not be more than 15 characters long")
	v.Check(len(teacher.ProfileStatus) <= 30, "profile_status", "must not be more than 30 characters long")

	if !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	err = a.models.Teachers.Insert(teacher)
	if err != nil {
		// Log the actual error for debugging
		a.logger.Error("failed to insert teacher", "error", err)
		a.serverErrorResponse(w, r, err)
		return
	}

	headers := make(http.Header)
	headers.Set("Location", fmt.Sprintf("/v1/teachers/%d", teacher.ID))

	err = a.writeJSON(w, http.StatusCreated, envelope{"teacher": teacher}, headers)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getTeacherHandler handles GET /v1/teachers/:id
func (a *app) getTeacherHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	teacher, err := a.models.Teachers.Get(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"teacher": teacher}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getTeacherByUserIDHandler handles GET /v1/teachers/user/:user_id
func (a *app) getTeacherByUserIDHandler(w http.ResponseWriter, r *http.Request) {
	userID, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	teacher, err := a.models.Teachers.GetByUserID(int(userID))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"teacher": teacher}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// deleteTeacherHandler handles DELETE /v1/teachers/:id
func (a *app) deleteTeacherHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	err = a.models.Teachers.Delete(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"message": "teacher successfully deleted"}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// listTeachersHandler handles GET /v1/teachers
func (a *app) listTeachersHandler(w http.ResponseWriter, r *http.Request) {
	teachers, err := a.models.Teachers.GetAll()
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"teachers": teachers}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}
