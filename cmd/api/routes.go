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

	// User routes
	router.HandlerFunc(http.MethodPost, apiV1Route+"/users", a.registerUserHandler)
	router.HandlerFunc(http.MethodPut, apiV1Route+"/users/activated", a.activateUserHandler)
	router.HandlerFunc(http.MethodGet, apiV1Route+"/users/:id", a.getUserHandler)
	router.HandlerFunc(http.MethodGet, apiV1Route+"/users", a.getAllUsersHandler)
	router.HandlerFunc(http.MethodPatch, apiV1Route+"/users/:id", a.updateUserHandler)
	router.HandlerFunc(http.MethodDelete, apiV1Route+"/users/:id", a.deleteUserHandler)

	// Role routes
	router.HandlerFunc(http.MethodPost, apiV1Route+"/roles", a.createRoleHandler)
	router.HandlerFunc(http.MethodGet, apiV1Route+"/roles/:id", a.getRoleHandler)
	router.HandlerFunc(http.MethodGet, apiV1Route+"/roles", a.getAllRolesHandler)
	router.HandlerFunc(http.MethodPatch, apiV1Route+"/roles/:id", a.updateRoleHandler)
	router.HandlerFunc(http.MethodDelete, apiV1Route+"/roles/:id", a.deleteRoleHandler)

	// District routes
	router.HandlerFunc(http.MethodPost, apiV1Route+"/districts", a.createDistrictHandler)
	router.HandlerFunc(http.MethodGet, apiV1Route+"/districts/:id", a.getDistrictHandler)
	router.HandlerFunc(http.MethodGet, apiV1Route+"/districts", a.getAllDistrictsHandler)
	router.HandlerFunc(http.MethodDelete, apiV1Route+"/districts/:id", a.deleteDistrictHandler)

	// Institution routes
	router.HandlerFunc(http.MethodPost, apiV1Route+"/institutions", a.createInstitutionHandler)
	router.HandlerFunc(http.MethodGet, apiV1Route+"/institutions/:id", a.getInstitutionHandler)
	router.HandlerFunc(http.MethodGet, apiV1Route+"/institutions", a.getAllInstitutionsHandler)
	router.HandlerFunc(http.MethodDelete, apiV1Route+"/institutions/:id", a.deleteInstitutionHandler)

	// Teacher routes
	router.HandlerFunc(http.MethodPost, apiV1Route+"/teachers", a.createTeacherHandler)
	router.HandlerFunc(http.MethodGet, apiV1Route+"/teachers/:id", a.getTeacherHandler)
	router.HandlerFunc(http.MethodGet, apiV1Route+"/teachers/user/:user_id", a.getTeacherByUserIDHandler)
	router.HandlerFunc(http.MethodDelete, apiV1Route+"/teachers/:id", a.deleteTeacherHandler)

	// Education routes
	router.HandlerFunc(http.MethodPost, apiV1Route+"/education", a.createEducationHandler)
	router.HandlerFunc(http.MethodGet, apiV1Route+"/education/:id", a.getEducationHandler)
	router.HandlerFunc(http.MethodGet, apiV1Route+"/teachers/:teacher_id/education", a.getEducationByTeacherHandler)
	router.HandlerFunc(http.MethodDelete, apiV1Route+"/education/:id", a.deleteEducationHandler)

	// Qualification routes
	router.HandlerFunc(http.MethodPost, apiV1Route+"/qualifications", a.createQualificationHandler)
	router.HandlerFunc(http.MethodGet, apiV1Route+"/teachers/:teacher_id/qualifications", a.getQualificationsByTeacherHandler)
	router.HandlerFunc(http.MethodDelete, apiV1Route+"/qualifications/:id", a.deleteQualificationHandler)

	// Document routes
	router.HandlerFunc(http.MethodPost, apiV1Route+"/documents", a.createDocumentHandler)
	router.HandlerFunc(http.MethodGet, apiV1Route+"/documents/:id", a.getDocumentHandler)
	router.HandlerFunc(http.MethodGet, apiV1Route+"/teachers/:teacher_id/documents", a.getDocumentsByTeacherHandler)
	router.HandlerFunc(http.MethodDelete, apiV1Route+"/documents/:id", a.deleteDocumentHandler)

	// Notification routes
	router.HandlerFunc(http.MethodPost, apiV1Route+"/notifications", a.createNotificationHandler)
	router.HandlerFunc(http.MethodGet, apiV1Route+"/notifications/:id", a.getNotificationHandler)
	router.HandlerFunc(http.MethodGet, apiV1Route+"/users/:user_id/notifications", a.getNotificationsByUserHandler)
	router.HandlerFunc(http.MethodPatch, apiV1Route+"/notifications/:id/read", a.markNotificationAsReadHandler)
	router.HandlerFunc(http.MethodDelete, apiV1Route+"/notifications/:id", a.deleteNotificationHandler)

	// Token routes
	router.HandlerFunc(http.MethodPost, apiV1Route+"/tokens/authentication", a.createAuthTokenHandler)
	router.HandlerFunc(http.MethodPost, apiV1Route+"/tokens/activation", a.createActivationTokenHandler)
	router.HandlerFunc(http.MethodPost, apiV1Route+"/tokens/validate", a.validateTokenHandler)
	router.HandlerFunc(http.MethodDelete, apiV1Route+"/tokens/user/:user_id", a.deleteAllTokensForUserHandler)

	// Apply middleware
	handler := a.recoverPanic(router)
	handler = a.enableCORS(handler)
	handler = a.rateLimit(handler)

	return handler
}
