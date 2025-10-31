// Filename: cmd/api/educationHandlers.go
package main

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/amilcar-vasquez/impartBelize/internal/data"
	"github.com/amilcar-vasquez/impartBelize/internal/validator"
)

// createEducationHandler handles POST /v1/education
func (a *app) createEducationHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		TeacherID     int    `json:"teacher_id"`
		Institution   string `json:"institution"`
		Level         string `json:"level,omitempty"`
		Program       string `json:"program,omitempty"`
		Degree        string `json:"degree,omitempty"`
		YearObtained  int    `json:"year_obtained,omitempty"`
		InstitutionID int    `json:"institution_id,omitempty"`
	}

	err := a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	education := &data.Education{
		TeacherID:     input.TeacherID,
		Institution:   input.Institution,
		Level:         input.Level,
		Program:       input.Program,
		Degree:        input.Degree,
		YearObtained:  input.YearObtained,
		InstitutionID: input.InstitutionID,
	}

	v := validator.New()
	v.Check(education.TeacherID > 0, "teacher_id", "must be provided")
	v.Check(education.Institution != "", "institution", "must be provided")
	v.Check(len(education.Institution) <= 150, "institution", "must not be more than 150 characters long")
	v.Check(len(education.Level) <= 50, "level", "must not be more than 50 characters long")
	v.Check(len(education.Program) <= 100, "program", "must not be more than 100 characters long")
	v.Check(len(education.Degree) <= 100, "degree", "must not be more than 100 characters long")

	if !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	err = a.models.Education.Insert(education)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	headers := make(http.Header)
	headers.Set("Location", fmt.Sprintf("/v1/education/%d", education.ID))

	err = a.writeJSON(w, http.StatusCreated, envelope{"education": education}, headers)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getEducationHandler handles GET /v1/education/:id
func (a *app) getEducationHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	education, err := a.models.Education.Get(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"education": education}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getEducationByTeacherHandler handles GET /v1/teachers/:teacher_id/education
func (a *app) getEducationByTeacherHandler(w http.ResponseWriter, r *http.Request) {
	teacherID, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	educations, err := a.models.Education.GetByTeacher(int(teacherID))
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"education": educations}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// deleteEducationHandler handles DELETE /v1/education/:id
func (a *app) deleteEducationHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	err = a.models.Education.Delete(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"message": "education record successfully deleted"}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}
