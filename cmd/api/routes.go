package main

import (
	"net/http"

	"github.com/julienschmidt/httprouter"
)

func (a *app) routes() http.Handler {

	const apiV1Route = "/v1"

	// Initialize the router
	router := httprouter.New()

	// handle 404
	router.NotFound = http.HandlerFunc(a.notFoundResponse)

	// Define API routes
	router.HandlerFunc(http.MethodGet, apiV1Route+"/healthcheck", a.healthCheckHandler)

	// Apply middleware
	handler := a.recoverPanic(router)
	handler = a.enableCORS(handler)
	handler = a.rateLimit(handler)

	return handler
}
