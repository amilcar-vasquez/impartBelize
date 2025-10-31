// Filename: cmd/api/roleHandlers.go
package main

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/amilcar-vasquez/impartBelize/internal/data"
	"github.com/amilcar-vasquez/impartBelize/internal/validator"
)

// createRoleHandler handles POST /v1/roles
func (a *app) createRoleHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		RoleName string `json:"role_name"`
	}

	err := a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	role := &data.Role{
		RoleName: input.RoleName,
	}

	v := validator.New()
	if data.ValidateRole(v, role); !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	err = a.models.Roles.Insert(role)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	headers := make(http.Header)
	headers.Set("Location", fmt.Sprintf("/v1/roles/%d", role.ID))

	err = a.writeJSON(w, http.StatusCreated, envelope{"role": role}, headers)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getRoleHandler handles GET /v1/roles/:id
func (a *app) getRoleHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	role, err := a.models.Roles.Get(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"role": role}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getAllRolesHandler handles GET /v1/roles
func (a *app) getAllRolesHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		data.Filters
	}

	v := validator.New()

	qs := r.URL.Query()

	input.Filters.Page = a.getSingleIntegerParameter(qs, "page", 1, v)
	input.Filters.PageSize = a.getSingleIntegerParameter(qs, "page_size", 20, v)
	input.Filters.Sort = a.getSingleQueryParameter(qs, "sort", "id")
	input.Filters.SortSafelist = []string{"id", "role_name", "-id", "-role_name"}

	if data.ValidateFilters(v, input.Filters); !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	roles, err := a.models.Roles.GetAll()
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	// Create simple metadata since no pagination is implemented yet
	metadata := data.Metadata{
		CurrentPage:  1,
		PageSize:     len(roles),
		FirstPage:    1,
		LastPage:     1,
		TotalRecords: len(roles),
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"roles": roles, "metadata": metadata}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// updateRoleHandler handles PATCH /v1/roles/:id
func (a *app) updateRoleHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	role, err := a.models.Roles.Get(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	var input struct {
		RoleName *string `json:"role_name"`
	}

	err = a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	if input.RoleName != nil {
		role.RoleName = *input.RoleName
	}

	v := validator.New()
	if data.ValidateRole(v, role); !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	err = a.models.Roles.Update(role)
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"role": role}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// deleteRoleHandler handles DELETE /v1/roles/:id
func (a *app) deleteRoleHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	err = a.models.Roles.Delete(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"message": "role successfully deleted"}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}
