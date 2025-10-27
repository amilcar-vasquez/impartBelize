package main

import (
	"net/http"
)


func (a *app) healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	data := envelope {
		"status": "available",
		"system_info": map[string]string{
			"environment": a.config.env,
			"version": a.config.version,
		},
	}

	err := a.writeJSON(w, http.StatusOK, data, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}