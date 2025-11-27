package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/amilcar-vasquez/impartBelize/internal/data"
)

// Direct handler tests that bypass authentication middleware

// Helper to test handlers directly with authenticated context
func testHandlerDirect(t *testing.T, app *app, handler http.HandlerFunc, method, path string, body string) *httptest.ResponseRecorder {
	t.Helper()

	req := httptest.NewRequest(method, path, bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")

	// Add authenticated admin user to context
	user := &data.User{
		ID:          1,
		Username:    "testadmin",
		Email:       "admin@example.com",
		IsActivated: true,
		RoleID:      1, // Admin role
	}
	req = app.contextSetUser(req, user)

	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	return rr
}

// District Handler Direct Tests
func TestCreateDistrictHandlerDirect(t *testing.T) {
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
			payload:        `{"name": "` + strings.Repeat("a", 256) + `"}`,
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
			rr := testHandlerDirect(t, app, app.createDistrictHandler, "POST", "/v1/districts", tt.payload)
			if rr.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d. Body: %s", tt.expectedStatus, rr.Code, rr.Body.String())
			}
		})
	}
}

// GetAllDistrictsHandler requires database - skip in unit tests
// This would be tested in integration tests with a real DB// Institution Handler Direct Tests
func TestCreateInstitutionHandlerDirect(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name           string
		payload        string
		expectedStatus int
	}{
		{
			name:           "Missing name",
			payload:        `{"name": "", "district_id": 1}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
		{
			name:           "Name too long",
			payload:        `{"name": "` + strings.Repeat("x", 201) + `", "district_id": 1}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := testHandlerDirect(t, app, app.createInstitutionHandler, "POST", "/v1/institutions", tt.payload)
			if rr.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d. Body: %s", tt.expectedStatus, rr.Code, rr.Body.String())
			}
		})
	}
}

// GetAllInstitutionsHandler requires database - skip in unit tests// Teacher Handler Direct Tests
func TestCreateTeacherHandlerDirect(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name           string
		payload        string
		expectedStatus int
	}{
		{
			name:           "Missing first name",
			payload:        `{"first_name": "", "last_name": "Doe", "email": "test@example.com"}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
		{
			name:           "Missing email",
			payload:        `{"first_name": "John", "last_name": "Doe", "email": ""}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
		{
			name:           "Email too long",
			payload:        `{"first_name": "John", "last_name": "Doe", "email": "` + strings.Repeat("a", 95) + `@test.com"}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := testHandlerDirect(t, app, app.createTeacherHandler, "POST", "/v1/teachers", tt.payload)
			if rr.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d. Body: %s", tt.expectedStatus, rr.Code, rr.Body.String())
			}
		})
	}
}

// ListTeachersHandler requires database - skip in unit tests// Education Handler Direct Tests
func TestCreateEducationHandlerDirect(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name           string
		payload        string
		expectedStatus int
	}{
		{
			name:           "Missing teacher_id",
			payload:        `{"teacher_id": 0, "institution": "Test University"}`,
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
			rr := testHandlerDirect(t, app, app.createEducationHandler, "POST", "/v1/education", tt.payload)
			if rr.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d. Body: %s", tt.expectedStatus, rr.Code, rr.Body.String())
			}
		})
	}
}

// Qualification Handler Direct Tests
func TestCreateQualificationHandlerDirect(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name           string
		payload        string
		expectedStatus int
	}{
		{
			name:           "Missing teacher_id",
			payload:        `{"teacher_id": 0, "certification": "Teaching License"}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
		{
			name:           "Certification too long",
			payload:        `{"teacher_id": 1, "certification": "` + strings.Repeat("x", 151) + `"}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := testHandlerDirect(t, app, app.createQualificationHandler, "POST", "/v1/qualifications", tt.payload)
			if rr.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d. Body: %s", tt.expectedStatus, rr.Code, rr.Body.String())
			}
		})
	}
}

// Document Handler Direct Tests
func TestCreateDocumentHandlerDirect(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name           string
		payload        string
		expectedStatus int
	}{
		{
			name:           "Missing teacher_id",
			payload:        `{"teacher_id": 0, "doc_type": "ID"}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
		{
			name:           "Missing doc_type",
			payload:        `{"teacher_id": 1, "doc_type": ""}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := testHandlerDirect(t, app, app.createDocumentHandler, "POST", "/v1/documents", tt.payload)
			if rr.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d. Body: %s", tt.expectedStatus, rr.Code, rr.Body.String())
			}
		})
	}
}

// Notification Handler Direct Tests
func TestCreateNotificationHandlerDirect(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name           string
		payload        string
		expectedStatus int
	}{
		{
			name:           "Missing user_id",
			payload:        `{"user_id": 0, "message": "Test message"}`,
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
			rr := testHandlerDirect(t, app, app.createNotificationHandler, "POST", "/v1/notifications", tt.payload)
			if rr.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d. Body: %s", tt.expectedStatus, rr.Code, rr.Body.String())
			}
		})
	}
}

// User Handler Direct Tests
// Note: RegisterUserHandler requires database connection to call CountUsers()
// before validation, so it cannot be tested without a database.
// This would be covered in integration tests.

func TestActivateUserHandlerDirect(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name           string
		payload        string
		expectedStatus int
	}{
		{
			name:           "Missing token",
			payload:        `{"token": ""}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
		{
			name:           "Invalid token length",
			payload:        `{"token": "short"}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := testHandlerDirect(t, app, app.activateUserHandler, "PUT", "/v1/users/activated", tt.payload)
			if rr.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d. Body: %s", tt.expectedStatus, rr.Code, rr.Body.String())
			}
		})
	}
}

// Token Handler Direct Tests
func TestCreateAuthTokenHandlerDirect(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name           string
		payload        string
		expectedStatus int
	}{
		{
			name:           "Missing email",
			payload:        `{"email": "", "password": "password123"}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
		{
			name:           "Invalid email format",
			payload:        `{"email": "invalid", "password": "password123"}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
		{
			name:           "Missing password",
			payload:        `{"email": "test@example.com", "password": ""}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := testHandlerDirect(t, app, app.createAuthTokenHandler, "POST", "/v1/tokens/authentication", tt.payload)
			if rr.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d. Body: %s", tt.expectedStatus, rr.Code, rr.Body.String())
			}
		})
	}
}

// Role Handler Direct Tests
// GetAllRolesHandler requires database - skip in unit tests// JSON Response Validation Tests
func TestValidJSONResponses(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name    string
		handler http.HandlerFunc
		method  string
		path    string
		body    string
	}{
		{
			name:    "Create district with validation error",
			handler: app.createDistrictHandler,
			method:  "POST",
			path:    "/v1/districts",
			body:    `{"name": ""}`,
		},
		{
			name:    "Create teacher with validation error",
			handler: app.createTeacherHandler,
			method:  "POST",
			path:    "/v1/teachers",
			body:    `{"first_name": ""}`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := testHandlerDirect(t, app, tt.handler, tt.method, tt.path, tt.body)

			// Check that response is valid JSON
			if rr.Header().Get("Content-Type") == "application/json" {
				var response map[string]interface{}
				err := json.Unmarshal(rr.Body.Bytes(), &response)
				if err != nil {
					t.Errorf("Response body is not valid JSON: %v", err)
				}
			}
		})
	}
}
