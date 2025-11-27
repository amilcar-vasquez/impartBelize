package main

import (
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/amilcar-vasquez/impartBelize/internal/data"
	"github.com/amilcar-vasquez/impartBelize/internal/validator"
)

// createApplicationHandler handles POST /v1/applications
func (a *app) createApplicationHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		TeacherID       int    `json:"teacher_id"`
		UserID          int    `json:"user_id"`
		ApplicationType string `json:"application_type"`
		Notes           string `json:"notes"`
	}

	err := a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	application := &data.Application{
		TeacherID:       input.TeacherID,
		UserID:          input.UserID,
		ApplicationType: input.ApplicationType,
		Status:          "pending",
		Notes:           input.Notes,
	}

	v := validator.New()
	if data.ValidateApplication(v, application); !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	err = a.models.Applications.Insert(application)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	headers := make(http.Header)
	headers.Set("Location", fmt.Sprintf("/v1/applications/%d", application.ID))

	err = a.writeJSON(w, http.StatusCreated, envelope{"application": application}, headers)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getApplicationHandler handles GET /v1/applications/:id
func (a *app) getApplicationHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	application, err := a.models.Applications.Get(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"application": application}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getApplicationsByTeacherHandler handles GET /v1/applications/teacher/:id
func (a *app) getApplicationsByTeacherHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	applications, err := a.models.Applications.GetByTeacherID(int(id))
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"applications": applications}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getAllApplicationsHandler handles GET /v1/applications
func (a *app) getAllApplicationsHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		Status          string
		ApplicationType string
		data.Filters
	}

	v := validator.New()
	qs := r.URL.Query()

	input.Status = a.getSingleQueryParameter(qs, "status", "")
	input.ApplicationType = a.getSingleQueryParameter(qs, "application_type", "")
	input.Filters.Page = a.getSingleIntegerParameter(qs, "page", 1, v)
	input.Filters.PageSize = a.getSingleIntegerParameter(qs, "page_size", 20, v)
	input.Filters.Sort = a.getSingleQueryParameter(qs, "sort", "-submitted_at")
	input.Filters.SortSafelist = []string{
		"application_id", "submitted_at", "status",
		"-application_id", "-submitted_at", "-status",
	}

	if data.ValidateFilters(v, input.Filters); !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	applications, metadata, err := a.models.Applications.GetAll(
		input.Status,
		input.ApplicationType,
		input.Filters,
	)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"applications": applications, "metadata": metadata}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// updateApplicationHandler handles PATCH /v1/applications/:id
func (a *app) updateApplicationHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	application, err := a.models.Applications.Get(int(id))
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
		Status            *string `json:"status"`
		RejectionReason   *string `json:"rejection_reason"`
		Notes             *string `json:"notes"`
		LicenseNumber     *string `json:"license_number"`
		LicenseIssuedDate *string `json:"license_issued_date"`
		LicenseExpiryDate *string `json:"license_expiry_date"`
	}

	err = a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	// Get current user for reviewed_by
	user := a.contextGetUser(r)

	if input.Status != nil {
		application.Status = *input.Status
		// Set reviewed_at and reviewed_by when status changes
		now := time.Now()
		application.ReviewedAt = &now
		reviewedByInt := int(user.ID)
		application.ReviewedBy = &reviewedByInt

		// Generate license fields when status is approved
		if *input.Status == "approved" {
			// Generate license number if not provided
			if input.LicenseNumber == nil || *input.LicenseNumber == "" {
				// Generate license number format: BZ-YYYY-XXXXX (BZ-2025-00123)
				licenseNumber := fmt.Sprintf("BZ-%d-%05d", now.Year(), application.ID)
				application.LicenseNumber = licenseNumber
			}

			// Set issue date to now if not provided
			if input.LicenseIssuedDate == nil {
				application.LicenseIssuedDate = &now
			}

			// Set expiry date to 2 years from issue date if not provided
			if input.LicenseExpiryDate == nil {
				issueDate := now
				if application.LicenseIssuedDate != nil {
					issueDate = *application.LicenseIssuedDate
				}
				expiryDate := issueDate.AddDate(2, 0, 0) // Add 2 years
				application.LicenseExpiryDate = &expiryDate
			}
		}
	}

	if input.RejectionReason != nil {
		application.RejectionReason = *input.RejectionReason
	}

	if input.Notes != nil {
		application.Notes = *input.Notes
	}

	// Allow manual override of license fields
	if input.LicenseNumber != nil {
		application.LicenseNumber = *input.LicenseNumber
	}

	if input.LicenseIssuedDate != nil {
		date, err := time.Parse("2006-01-02", *input.LicenseIssuedDate)
		if err != nil {
			v := validator.New()
			v.AddError("license_issued_date", "must be a valid date in YYYY-MM-DD format")
			a.failedValidationResponse(w, r, v.Errors)
			return
		}
		application.LicenseIssuedDate = &date
	}

	if input.LicenseExpiryDate != nil {
		date, err := time.Parse("2006-01-02", *input.LicenseExpiryDate)
		if err != nil {
			v := validator.New()
			v.AddError("license_expiry_date", "must be a valid date in YYYY-MM-DD format")
			a.failedValidationResponse(w, r, v.Errors)
			return
		}
		application.LicenseExpiryDate = &date
	}

	v := validator.New()
	if data.ValidateApplication(v, application); !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	err = a.models.Applications.Update(application)
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"application": application}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// deleteApplicationHandler handles DELETE /v1/applications/:id
func (a *app) deleteApplicationHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	err = a.models.Applications.Delete(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"message": "application successfully deleted"}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}
