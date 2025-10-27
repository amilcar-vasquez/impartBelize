package main

import "net/http"

func (a *app) logError(r *http.Request, err error) {
	method := r.Method
	uri := r.URL.RequestURI()
	a.logger.Error(err.Error(), "method", method, "url", uri)
}

func (a *app) errorResponseJSON(w http.ResponseWriter, r *http.Request, status int, message any) {
	errorData := envelope{"error": message}
	err := a.writeJSON(w, status, errorData, nil)
	if err != nil {
		a.logError(r, err)
		w.WriteHeader(500)
	}
}

func (a *app) notFoundResponse(w http.ResponseWriter, r *http.Request) {
	message := "the requested resource could not be found"
	a.errorResponseJSON(w, r, http.StatusNotFound, message)
}