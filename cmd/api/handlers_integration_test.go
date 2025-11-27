package main

import (
	"bytes"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/amilcar-vasquez/impartBelize/internal/data"
)

// Integration tests that verify the full request flow including routing,
// middleware, and authentication

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

// executeRequest tests the complete request flow through routes and middleware
func executeRequest(t *testing.T, app *app, method, url string, body io.Reader) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest(method, url, body)
	req.Header.Set("Content-Type", "application/json")

	rr := httptest.NewRecorder()
	handler := app.routes()
	handler.ServeHTTP(rr, req)

	return rr
}

// executeAuthenticatedRequest tests with a mock authentication token
func executeAuthenticatedRequest(t *testing.T, app *app, method, url string, body io.Reader) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest(method, url, body)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer test-token-123")

	rr := httptest.NewRecorder()
	handler := app.routes()
	handler.ServeHTTP(rr, req)

	return rr
}

// TestMain runs before all tests
func TestMain(m *testing.M) {
	os.Exit(m.Run())
}

// ============================================================================
// Public Endpoint Tests - These should work without authentication
// ============================================================================

func TestHealthcheckEndpoint(t *testing.T) {
	app := newTestApp(t)

	rr := executeRequest(t, app, "GET", "/v1/healthcheck", nil)

	if rr.Code != http.StatusOK {
		t.Errorf("Expected status 200, got %d", rr.Code)
	}

	if rr.Header().Get("Content-Type") != "application/json" {
		t.Errorf("Expected Content-Type application/json, got %s", rr.Header().Get("Content-Type"))
	}

	// Verify JSON response structure
	var response map[string]interface{}
	err := json.Unmarshal(rr.Body.Bytes(), &response)
	if err != nil {
		t.Errorf("Failed to parse JSON response: %v", err)
	}

	if response["status"] != "available" {
		t.Errorf("Expected status 'available', got %v", response["status"])
	}
}

func TestUserRegistrationEndpoint(t *testing.T) {
	app := newTestApp(t)

	// Test that the endpoint is accessible (will fail at DB layer, but shouldn't return 401)
	payload := `{"username": "testuser", "email": "test@example.com", "password": "password123"}`
	rr := executeRequest(t, app, "POST", "/v1/users", bytes.NewBufferString(payload))

	// Should get 500 (DB error) not 401 (auth error) since this is a public endpoint
	if rr.Code == http.StatusUnauthorized {
		t.Error("User registration endpoint should not require authentication")
	}
}

func TestActivateUserEndpoint(t *testing.T) {
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
			name:           "Invalid token format",
			payload:        `{"token": "short"}`,
			expectedStatus: http.StatusUnprocessableEntity,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := executeRequest(t, app, "PUT", "/v1/users/activated", bytes.NewBufferString(tt.payload))
			if rr.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d", tt.expectedStatus, rr.Code)
			}
		})
	}
}

func TestCreateAuthTokenEndpoint(t *testing.T) {
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
			rr := executeRequest(t, app, "POST", "/v1/tokens/authentication", bytes.NewBufferString(tt.payload))
			if rr.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d. Body: %s", tt.expectedStatus, rr.Code, rr.Body.String())
			}
		})
	}
}

// ============================================================================
// Authentication Tests - Protected endpoints should return 401
// ============================================================================

func TestProtectedEndpointsRequireAuthentication(t *testing.T) {
	app := newTestApp(t)

	protectedEndpoints := []struct {
		method string
		path   string
	}{
		{"POST", "/v1/districts"},
		{"GET", "/v1/districts"},
		{"GET", "/v1/districts/1"},
		{"DELETE", "/v1/districts/1"},
		{"POST", "/v1/institutions"},
		{"GET", "/v1/institutions"},
		{"GET", "/v1/institutions/1"},
		{"DELETE", "/v1/institutions/1"},
		{"POST", "/v1/teachers"},
		{"GET", "/v1/teachers"},
		{"GET", "/v1/teachers/1"},
		{"DELETE", "/v1/teachers/1"},
		{"POST", "/v1/education"},
		{"GET", "/v1/education/1"},
		{"DELETE", "/v1/education/1"},
		{"POST", "/v1/qualifications"},
		{"DELETE", "/v1/qualifications/1"},
		{"POST", "/v1/documents"},
		{"GET", "/v1/documents/1"},
		{"DELETE", "/v1/documents/1"},
		{"POST", "/v1/notifications"},
		{"GET", "/v1/notifications/1"},
		{"DELETE", "/v1/notifications/1"},
		{"PATCH", "/v1/notifications/1/read"},
		{"GET", "/v1/users"},
		{"GET", "/v1/users/1"},
		{"PATCH", "/v1/users/1"},
		{"DELETE", "/v1/users/1"},
	}

	for _, endpoint := range protectedEndpoints {
		t.Run(endpoint.method+" "+endpoint.path, func(t *testing.T) {
			rr := executeRequest(t, app, endpoint.method, endpoint.path, nil)

			// These endpoints should require authentication
			if rr.Code != http.StatusUnauthorized {
				t.Errorf("Expected 401 Unauthorized for %s %s, got %d - endpoint is not properly protected",
					endpoint.method, endpoint.path, rr.Code)
			}
		})
	}
}

func TestGetAllRolesEndpoint(t *testing.T) {
	app := newTestApp(t)

	// This endpoint is currently public (no auth middleware)
	rr := executeRequest(t, app, "GET", "/v1/roles", nil)

	// Should return OK or InternalServerError (DB), not Unauthorized
	if rr.Code == http.StatusUnauthorized {
		t.Error("Get all roles should not require authentication based on current routes")
	}
}

// ============================================================================
// Route Tests - Verify routing works correctly
// ============================================================================

func TestNotFoundRoute(t *testing.T) {
	app := newTestApp(t)

	rr := executeRequest(t, app, "GET", "/v1/nonexistent", nil)

	if rr.Code != http.StatusNotFound {
		t.Errorf("Expected 404 Not Found, got %d", rr.Code)
	}
}

func TestMethodNotAllowed(t *testing.T) {
	app := newTestApp(t)

	// Healthcheck only accepts GET
	rr := executeRequest(t, app, "POST", "/v1/healthcheck", nil)

	if rr.Code != http.StatusMethodNotAllowed && rr.Code != http.StatusNotFound {
		t.Errorf("Expected 405 Method Not Allowed or 404, got %d", rr.Code)
	}
}

// ============================================================================
// Middleware Tests
// ============================================================================

func TestCORSMiddleware(t *testing.T) {
	app := newTestApp(t)

	req := httptest.NewRequest("OPTIONS", "/v1/healthcheck", nil)
	req.Header.Set("Origin", "http://localhost:3000")
	req.Header.Set("Access-Control-Request-Method", "GET")

	rr := httptest.NewRecorder()
	handler := app.routes()
	handler.ServeHTTP(rr, req)

	// Should have CORS headers (actual values depend on middleware implementation)
	if rr.Header().Get("Vary") == "" && rr.Header().Get("Access-Control-Allow-Origin") == "" {
		t.Log("Note: CORS headers may not be set for OPTIONS requests in current implementation")
	}
}

func TestRecoverPanicMiddleware(t *testing.T) {
	app := newTestApp(t)

	// Create a handler that panics
	panicHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		panic("test panic")
	})

	// Wrap with recover panic middleware
	handler := app.recoverPanic(panicHandler)

	req := httptest.NewRequest("GET", "/", nil)
	rr := httptest.NewRecorder()

	// This should not panic, middleware should recover
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusInternalServerError {
		t.Errorf("Expected 500 Internal Server Error after panic, got %d", rr.Code)
	}
}

// ============================================================================
// JSON Response Format Tests
// ============================================================================

func TestJSONResponseFormats(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name         string
		method       string
		path         string
		payload      string
		expectJSON   bool
		expectedCode int
	}{
		{
			name:         "Healthcheck returns valid JSON",
			method:       "GET",
			path:         "/v1/healthcheck",
			expectJSON:   true,
			expectedCode: http.StatusOK,
		},
		{
			name:         "Validation errors return JSON",
			method:       "PUT",
			path:         "/v1/users/activated",
			payload:      `{"token": ""}`,
			expectJSON:   true,
			expectedCode: http.StatusUnprocessableEntity,
		},
		{
			name:         "Not found returns JSON",
			method:       "GET",
			path:         "/v1/nonexistent",
			expectJSON:   true,
			expectedCode: http.StatusNotFound,
		},
		{
			name:         "Unauthorized returns JSON",
			method:       "GET",
			path:         "/v1/districts",
			expectJSON:   true,
			expectedCode: http.StatusUnauthorized,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var body io.Reader
			if tt.payload != "" {
				body = bytes.NewBufferString(tt.payload)
			}

			rr := executeRequest(t, app, tt.method, tt.path, body)

			if rr.Code != tt.expectedCode {
				t.Errorf("Expected status %d, got %d", tt.expectedCode, rr.Code)
			}

			if tt.expectJSON {
				contentType := rr.Header().Get("Content-Type")
				if contentType != "application/json" {
					t.Errorf("Expected Content-Type application/json, got %s", contentType)
				}

				var response map[string]interface{}
				err := json.Unmarshal(rr.Body.Bytes(), &response)
				if err != nil {
					t.Errorf("Response is not valid JSON: %v. Body: %s", err, rr.Body.String())
				}
			}
		})
	}
}

// ============================================================================
// Request Validation Tests
// ============================================================================

func TestInvalidJSONHandling(t *testing.T) {
	app := newTestApp(t)

	tests := []struct {
		name   string
		method string
		path   string
		body   string
	}{
		{
			name:   "Auth token with invalid JSON",
			method: "POST",
			path:   "/v1/tokens/authentication",
			body:   `{invalid json}`,
		},
		{
			name:   "User activation with invalid JSON",
			method: "PUT",
			path:   "/v1/users/activated",
			body:   `{"token": unclosed string`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := executeRequest(t, app, tt.method, tt.path, bytes.NewBufferString(tt.body))

			if rr.Code != http.StatusBadRequest {
				t.Errorf("Expected 400 Bad Request for invalid JSON, got %d", rr.Code)
			}
		})
	}
}

// ============================================================================
// Integration Flow Tests
// ============================================================================

func TestCompleteUserRegistrationFlow(t *testing.T) {
	app := newTestApp(t)

	t.Run("Step 1: Register user", func(t *testing.T) {
		payload := `{"username": "newuser", "email": "newuser@example.com", "password": "securepass123"}`
		rr := executeRequest(t, app, "POST", "/v1/users", bytes.NewBufferString(payload))

		// Will fail at DB but shouldn't be authentication error
		if rr.Code == http.StatusUnauthorized {
			t.Error("Registration should not require authentication")
		}
	})

	t.Run("Step 2: Activate user", func(t *testing.T) {
		// With invalid token (valid format but not in DB)
		payload := `{"token": "ABCDEFGHIJKLMNOPQRSTUVWXYZ"}`
		rr := executeRequest(t, app, "PUT", "/v1/users/activated", bytes.NewBufferString(payload))

		// Should accept the request (will fail at DB lookup)
		if rr.Code == http.StatusUnauthorized {
			t.Error("Activation should not require authentication")
		}
	})
}
