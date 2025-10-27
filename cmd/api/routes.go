package main

import (
	"net/http"

	"github.com/julienschmidt/httprouter"
)

func (app *app) routes() http.Handler {
	// Initialize a new httprouter instance
	router := httprouter.New()
	
	// handle 404 
	// in errors.go
	router.NotFound = http.HandlerFunc(app.notFoundResponse)
	return router
}