package main

import (
	"bytes"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/amilcar-vasquez/impartBelize/internal/data"
)

// newTestApp creates a new application instance for testing
func newTestApp(t *testing.T) *app {
	return &app{
		config: configuration{
			version: "1.0.0-test",
			env:     "test",
		},
		logger: slog.New(slog.NewTextHandler(io.Discard, nil)),
		models: data.NewTestModels(),
	}
}

// executeRequest is a helper that creates a request and records the response
func executeRequest(t *testing.T, app *app, method, url string, body io.Reader) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest(method, url, body)
	req.Header.Set("Content-Type", "application/json")

	rr := httptest.NewRecorder()
	handler := app.routes()
	handler.ServeHTTP(rr, req)

	return rr
}

// checkResponseCode checks if the response status code matches expected
func checkResponseCode(t *testing.T, expected, actual int) {
	t.Helper()
	if expected != actual {
		t.Errorf("Expected response code %d. Got %d", expected, actual)
	}
}

// TestMain runs before all tests
func TestMain(m *testing.M) {
	os.Exit(m.Run())
}

// Test Healthcheck Handler
func TestHealthcheckHandler(t *testing.T) {
	app := newTestApp(t)

	rr := executeRequest(t, app, "GET", "/v1/healthcheck", nil)
	checkResponseCode(t, http.StatusOK, rr.Code)

	if rr.Header().Get("Content-Type") != "application/json" {
		t.Errorf("Expected Content-Type application/json, got %s", rr.Header().Get("Content-Type"))
	}
}

// District Handler Tests
func TestCreateDistrictHandler(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name           string
		payload        string
		expectedStatus int
	}{
		{
			name:           "Missing name",
			payload:        `{"name": ""}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
		{
			name:           "Name too long",
			payload:        `{"name": "` + strings.Repeat("a", 51) + `"}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
		{
			name:           "Invalid JSON",
			payload:        `{"name": "Test"`,
			expectedStatus: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := executeRequest(t, app, "POST", "/v1/districts", bytes.NewBufferString(tt.payload))
			checkResponseCode(t, tt.expectedStatus, rr.Code)
		})
	}
} // Institution Handler Tests
func TestCreateInstitutionHandler(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name           string
		payload        string
		expectedStatus int
	}{
		{
			name:           "Missing name",
			payload:        `{"name": ""}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
		{
			name:           "Name too long",
			payload:        `{"name": "` + strings.Repeat("b", 201) + `"}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := executeRequest(t, app, "POST", "/v1/institutions", bytes.NewBufferString(tt.payload))
			checkResponseCode(t, tt.expectedStatus, rr.Code)
		})
	}
}

// Teacher Handler Tests
func TestCreateTeacherHandler(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name           string
		payload        string
		expectedStatus int
	}{
		{
			name:           "Missing required fields",
			payload:        `{"first_name": ""}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
		{
			name:           "Invalid JSON",
			payload:        `{invalid}`,
			expectedStatus: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := executeRequest(t, app, "POST", "/v1/teachers", bytes.NewBufferString(tt.payload))
			checkResponseCode(t, tt.expectedStatus, rr.Code)
		})
	}
}

// Education Handler Tests
func TestCreateEducationHandler(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name           string
		payload        string
		expectedStatus int
	}{
		{
			name:           "Missing teacher_id",
			payload:        `{"teacher_id": 0, "institution": ""}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
		{
			name:           "Missing institution",
			payload:        `{"teacher_id": 1, "institution": ""}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := executeRequest(t, app, "POST", "/v1/education", bytes.NewBufferString(tt.payload))
			checkResponseCode(t, tt.expectedStatus, rr.Code)
		})
	}
}

// Document Handler Tests
func TestCreateDocumentHandler(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name           string
		payload        string
		expectedStatus int
	}{
		{
			name:           "Missing teacher_id",
			payload:        `{"teacher_id": 0, "doc_type": "test", "file_path": "test.pdf"}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
		{
			name:           "Missing doc_type",
			payload:        `{"teacher_id": 1, "doc_type": "", "file_path": "test.pdf"}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := executeRequest(t, app, "POST", "/v1/documents", bytes.NewBufferString(tt.payload))
			checkResponseCode(t, tt.expectedStatus, rr.Code)
		})
	}
}

// Notification Handler Tests
func TestCreateNotificationHandler(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name           string
		payload        string
		expectedStatus int
	}{
		{
			name:           "Missing user_id",
			payload:        `{"user_id": 0, "message": "test"}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
		{
			name:           "Missing message",
			payload:        `{"user_id": 1, "message": ""}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := executeRequest(t, app, "POST", "/v1/notifications", bytes.NewBufferString(tt.payload))
			checkResponseCode(t, tt.expectedStatus, rr.Code)
		})
	}
}

// Token Handler Tests
func TestCreateAuthTokenHandler(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name           string
		payload        string
		expectedStatus int
	}{
		{
			name:           "Missing user_id",
			payload:        `{"user_id": 0}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := executeRequest(t, app, "POST", "/v1/tokens/authentication", bytes.NewBufferString(tt.payload))
			checkResponseCode(t, tt.expectedStatus, rr.Code)
		})
	}
}

// Test 404 Not Found
func TestNotFoundResponse(t *testing.T) {
	app := newTestApp(t)

	rr := executeRequest(t, app, "GET", "/v1/nonexistent", nil)
	checkResponseCode(t, http.StatusNotFound, rr.Code)
}
