// Filename: cmd/api/institutionHandlers.go
package main

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/amilcar-vasquez/impartBelize/internal/data"
	"github.com/amilcar-vasquez/impartBelize/internal/validator"
)

// createInstitutionHandler handles POST /v1/institutions
func (a *app) createInstitutionHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		Name            string `json:"name"`
		DistrictID      int    `json:"district_id,omitempty"`
		InstitutionType string `json:"institution_type,omitempty"`
	}

	err := a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	institution := &data.Institution{
		Name:            input.Name,
		DistrictID:      input.DistrictID,
		InstitutionType: input.InstitutionType,
	}

	v := validator.New()
	v.Check(institution.Name != "", "name", "must be provided")
	v.Check(len(institution.Name) <= 200, "name", "must not be more than 200 characters long")

	if !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	err = a.models.Institutions.Insert(institution)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	headers := make(http.Header)
	headers.Set("Location", fmt.Sprintf("/v1/institutions/%d", institution.ID))

	err = a.writeJSON(w, http.StatusCreated, envelope{"institution": institution}, headers)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getInstitutionHandler handles GET /v1/institutions/:id
func (a *app) getInstitutionHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	institution, err := a.models.Institutions.Get(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"institution": institution}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getAllInstitutionsHandler handles GET /v1/institutions
func (a *app) getAllInstitutionsHandler(w http.ResponseWriter, r *http.Request) {
	institutions, err := a.models.Institutions.GetAll()
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	metadata := data.Metadata{
		CurrentPage:  1,
		PageSize:     len(institutions),
		FirstPage:    1,
		LastPage:     1,
		TotalRecords: len(institutions),
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"institutions": institutions, "metadata": metadata}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// deleteInstitutionHandler handles DELETE /v1/institutions/:id
func (a *app) deleteInstitutionHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	err = a.models.Institutions.Delete(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"message": "institution successfully deleted"}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}
