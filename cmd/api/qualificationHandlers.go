// Filename: cmd/api/qualificationHandlers.go
package main

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/amilcar-vasquez/impartBelize/internal/data"
	"github.com/amilcar-vasquez/impartBelize/internal/validator"
)

// createQualificationHandler handles POST /v1/qualifications
func (a *app) createQualificationHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		TeacherID      int    `json:"teacher_id"`
		Institution    string `json:"institution,omitempty"`
		Specialization string `json:"specialization,omitempty"`
		Certification  string `json:"certification,omitempty"`
		YearObtained   int    `json:"year_obtained,omitempty"`
		InstitutionID  int    `json:"institution_id,omitempty"`
	}

	err := a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	qualification := &data.Qualification{
		TeacherID:      input.TeacherID,
		Institution:    input.Institution,
		Specialization: input.Specialization,
		Certification:  input.Certification,
		YearObtained:   input.YearObtained,
		InstitutionID:  input.InstitutionID,
	}

	v := validator.New()
	v.Check(qualification.TeacherID > 0, "teacher_id", "must be provided")
	v.Check(len(qualification.Institution) <= 150, "institution", "must not be more than 150 characters long")
	v.Check(len(qualification.Specialization) <= 100, "specialization", "must not be more than 100 characters long")
	v.Check(len(qualification.Certification) <= 150, "certification", "must not be more than 150 characters long")

	if !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	err = a.models.Qualifications.Insert(qualification)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	headers := make(http.Header)
	headers.Set("Location", fmt.Sprintf("/v1/qualifications/%d", qualification.ID))

	err = a.writeJSON(w, http.StatusCreated, envelope{"qualification": qualification}, headers)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getQualificationsByTeacherHandler handles GET /v1/teachers/:teacher_id/qualifications
func (a *app) getQualificationsByTeacherHandler(w http.ResponseWriter, r *http.Request) {
	teacherID, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	qualifications, err := a.models.Qualifications.GetByTeacher(int(teacherID))
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"qualifications": qualifications}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// deleteQualificationHandler handles DELETE /v1/qualifications/:id
func (a *app) deleteQualificationHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	err = a.models.Qualifications.Delete(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"message": "qualification successfully deleted"}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}
