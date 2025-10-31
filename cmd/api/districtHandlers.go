// Filename: cmd/api/districtHandlers.go
package main

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/amilcar-vasquez/impartBelize/internal/data"
	"github.com/amilcar-vasquez/impartBelize/internal/validator"
)

// createDistrictHandler handles POST /v1/districts
func (a *app) createDistrictHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		Name string `json:"name"`
	}

	err := a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	district := &data.District{
		Name: input.Name,
	}

	v := validator.New()
	v.Check(district.Name != "", "name", "must be provided")
	v.Check(len(district.Name) <= 50, "name", "must not be more than 50 characters long")

	if !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	err = a.models.Districts.Insert(district)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	headers := make(http.Header)
	headers.Set("Location", fmt.Sprintf("/v1/districts/%d", district.ID))

	err = a.writeJSON(w, http.StatusCreated, envelope{"district": district}, headers)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getDistrictHandler handles GET /v1/districts/:id
func (a *app) getDistrictHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	district, err := a.models.Districts.Get(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"district": district}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getAllDistrictsHandler handles GET /v1/districts
func (a *app) getAllDistrictsHandler(w http.ResponseWriter, r *http.Request) {
	districts, err := a.models.Districts.GetAll()
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	metadata := data.Metadata{
		CurrentPage:  1,
		PageSize:     len(districts),
		FirstPage:    1,
		LastPage:     1,
		TotalRecords: len(districts),
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"districts": districts, "metadata": metadata}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// deleteDistrictHandler handles DELETE /v1/districts/:id
func (a *app) deleteDistrictHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	err = a.models.Districts.Delete(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"message": "district successfully deleted"}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}
