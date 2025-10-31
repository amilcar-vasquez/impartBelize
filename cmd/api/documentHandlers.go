// Filename: cmd/api/documentHandlers.go
package main

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/amilcar-vasquez/impartBelize/internal/data"
	"github.com/amilcar-vasquez/impartBelize/internal/validator"
)

// createDocumentHandler handles POST /v1/documents
func (a *app) createDocumentHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		TeacherID     int    `json:"teacher_id"`
		DocType       string `json:"doc_type"`
		FilePath      string `json:"file_path"`
		UploadedBy    int    `json:"uploaded_by,omitempty"`
		Verified      bool   `json:"verified,omitempty"`
		VerifiedBy    int    `json:"verified_by,omitempty"`
		Remarks       string `json:"remarks,omitempty"`
		ApplicationID int    `json:"application_id,omitempty"`
	}

	err := a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	document := &data.Document{
		TeacherID:     input.TeacherID,
		DocType:       input.DocType,
		FilePath:      input.FilePath,
		UploadedBy:    input.UploadedBy,
		Verified:      input.Verified,
		VerifiedBy:    input.VerifiedBy,
		Remarks:       input.Remarks,
		ApplicationID: input.ApplicationID,
	}

	v := validator.New()
	v.Check(document.TeacherID > 0, "teacher_id", "must be provided")
	v.Check(document.DocType != "", "doc_type", "must be provided")
	v.Check(len(document.DocType) <= 100, "doc_type", "must not be more than 100 characters long")
	v.Check(document.FilePath != "", "file_path", "must be provided")
	v.Check(len(document.FilePath) <= 255, "file_path", "must not be more than 255 characters long")

	if !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	err = a.models.Documents.Insert(document)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	headers := make(http.Header)
	headers.Set("Location", fmt.Sprintf("/v1/documents/%d", document.ID))

	err = a.writeJSON(w, http.StatusCreated, envelope{"document": document}, headers)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getDocumentHandler handles GET /v1/documents/:id
func (a *app) getDocumentHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	document, err := a.models.Documents.Get(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"document": document}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// getDocumentsByTeacherHandler handles GET /v1/teachers/:teacher_id/documents
func (a *app) getDocumentsByTeacherHandler(w http.ResponseWriter, r *http.Request) {
	teacherID, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	documents, err := a.models.Documents.GetByTeacher(int(teacherID))
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"documents": documents}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

// deleteDocumentHandler handles DELETE /v1/documents/:id
func (a *app) deleteDocumentHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	err = a.models.Documents.Delete(int(id))
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"message": "document successfully deleted"}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}
