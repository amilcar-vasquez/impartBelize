package main

import (
	"fmt"
	"net/http"
)

// log an error message
func (a *app) logError(r *http.Request, err error) {

	method := r.Method
	uri := r.URL.RequestURI()
	a.logger.Error(err.Error(), "method", method, "uri", uri)

}

// send an error response in JSON
func (a *app) errorResponseJSON(w http.ResponseWriter, r *http.Request, status int, message any) {
	errorData := envelope{"error": message}
	err := a.writeJSON(w, status, errorData, nil)
	if err != nil {
		a.logError(r, err)
		w.WriteHeader(500)
	}
}

// send an error response if our server messes up
func (a *app) serverErrorResponse(w http.ResponseWriter,
	r *http.Request,
	err error) {

	// first thing is to log error message
	a.logError(r, err)
	// prepare a response to send to the client
	message := "the server encountered a problem and could not process your request"
	a.errorResponseJSON(w, r, http.StatusInternalServerError, message)
}

// send an error response if our client messes up with a 404
func (a *app) notFoundResponse(w http.ResponseWriter,
	r *http.Request) {

	// we only log server errors, not client errors
	// prepare a response to send to the client
	message := "the requested resource could not be found"
	a.errorResponseJSON(w, r, http.StatusNotFound, message)
}

// send an error response if our client messes up with a 405
func (a *app) methodNotAllowedResponse(
	w http.ResponseWriter,
	r *http.Request) {

	// we only log server errors, not client errors
	// prepare a formatted response to send to the client
	message := fmt.Sprintf("the %s method is not supported for this resource", r.Method)

	a.errorResponseJSON(w, r, http.StatusMethodNotAllowed, message)
}

func (a *app) badRequestResponse(w http.ResponseWriter, r *http.Request, err error) {
	a.errorResponseJSON(w, r, http.StatusBadRequest, err.Error())
}

func (a *app) failedValidationResponse(w http.ResponseWriter, r *http.Request, errors map[string]string) {
	a.errorResponseJSON(w, r, http.StatusUnprocessableEntity, errors)
}

func (a *app) rateLimitExceededResponse(w http.ResponseWriter, r *http.Request) {
	message := "rate limit exceeded"
	a.errorResponseJSON(w, r, http.StatusTooManyRequests, message)
}

func (a *app) editConflictResponse(w http.ResponseWriter, r *http.Request) {
	message := "unable to update the record due to an edit conflict, please try again"
	a.errorResponseJSON(w, r, http.StatusConflict, message)
}

// Return a 401 status code
func (a *app) invalidCredentialsResponse(w http.ResponseWriter, r *http.Request) {
    message := "invalid authentication credentials"
    a.errorResponseJSON(w, r, http.StatusUnauthorized, message)
}

func (a *app) invalidAuthenticationTokenResponse(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("WWW-Authenticate", "Bearer")

	message := "invalid or missing authentication token"
	a.errorResponseJSON(w, r, http.StatusUnauthorized, message)
}

func (a *app) authenticationRequiredResponse(w http.ResponseWriter, r *http.Request) {
    message := "you must be authenticated to access this resource"
    a.errorResponseJSON(w, r, http.StatusUnauthorized, message)
}

func (a *app) inactiveAccountResponse(w http.ResponseWriter, r *http.Request) {
    message := "your user account must be activated to access this resource"
    a.errorResponseJSON(w, r, http.StatusForbidden, message)
}

// 403 Forbidden status if bad permission
func (a *app) notPermittedResponse(w http.ResponseWriter,
                                                       r *http.Request) {
    message := "your user account doesn't have the necessary permissions to access this resource"

    a.errorResponseJSON(w, r, http.StatusForbidden, message)
}
