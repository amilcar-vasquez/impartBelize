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

	// !User routes
	// *-- Register a New User (public) -- *
	router.HandlerFunc(http.MethodPost, apiV1Route+"/users", a.registerUserHandler)
	// *-- Activate a User (public) -- *
	router.HandlerFunc(http.MethodPut, apiV1Route+"/users/activated", a.activateUserHandler)
	
	// Protected user routes - admin, CEO, DEC, TSC can view all users (must be activated)
	router.Handler(http.MethodGet, apiV1Route+"/users", a.requireAnyRole([]string{"admin", "CEO", "DEC", "TSC"}, http.HandlerFunc(a.getAllUsersHandler)))
	router.Handler(http.MethodGet, apiV1Route+"/users/:id", a.requireActivatedUser(a.getUserHandler))
	// admin, CEO, and DEC can update users (must be activated)
	router.Handler(http.MethodPatch, apiV1Route+"/users/:id", a.requireActivatedUser(a.updateUserHandler))
	// Only admin can delete users (must be activated)
	router.Handler(http.MethodDelete, apiV1Route+"/users/:id", 
		a.requireRole("admin", http.HandlerFunc(a.deleteUserHandler)))

	// Role routes - Only admin can manage roles (must be activated)
	router.Handler(http.MethodPost, apiV1Route+"/roles", 
		a.requireRole("admin", http.HandlerFunc(a.createRoleHandler)))
	router.Handler(http.MethodGet, apiV1Route+"/roles", 
		http.HandlerFunc(a.getAllRolesHandler))
	router.Handler(http.MethodGet, apiV1Route+"/roles/:id", 
		a.requireActivatedUser(http.HandlerFunc(a.getRoleHandler)))
	router.Handler(http.MethodPatch, apiV1Route+"/roles/:id", 
		a.requireRole("admin", http.HandlerFunc(a.updateRoleHandler)))
	router.Handler(http.MethodDelete, apiV1Route+"/roles/:id", 
		a.requireRole("admin", http.HandlerFunc(a.deleteRoleHandler)))

	// District routes - admin, CEO, DEC can manage districts (must be activated)
	router.Handler(http.MethodPost, apiV1Route+"/districts", 
		a.requireAnyRole([]string{"admin", "CEO", "DEC"}, http.HandlerFunc(a.createDistrictHandler)))
	router.Handler(http.MethodGet, apiV1Route+"/districts", 
		a.requireActivatedUser(http.HandlerFunc(a.getAllDistrictsHandler)))
	router.Handler(http.MethodGet, apiV1Route+"/districts/:id", 
		a.requireActivatedUser(http.HandlerFunc(a.getDistrictHandler)))
	router.Handler(http.MethodDelete, apiV1Route+"/districts/:id", 
		a.requireAnyRole([]string{"admin", "CEO"}, http.HandlerFunc(a.deleteDistrictHandler)))

	// Institution routes - admin, CEO, DEC, TSC can manage institutions (must be activated)
	router.Handler(http.MethodPost, apiV1Route+"/institutions", 
		a.requireAnyRole([]string{"admin", "CEO", "DEC", "TSC"}, http.HandlerFunc(a.createInstitutionHandler)))
	router.Handler(http.MethodGet, apiV1Route+"/institutions", 
		a.requireActivatedUser(http.HandlerFunc(a.getAllInstitutionsHandler)))
	router.Handler(http.MethodGet, apiV1Route+"/institutions/:id", 
		a.requireActivatedUser(http.HandlerFunc(a.getInstitutionHandler)))
	router.Handler(http.MethodDelete, apiV1Route+"/institutions/:id", 
		a.requireAnyRole([]string{"admin", "CEO"}, http.HandlerFunc(a.deleteInstitutionHandler)))

	// Teacher routes - All authenticated users can list/view, admin/CEO/TSC/DEC can create (must be activated)
	router.Handler(http.MethodGet, apiV1Route+"/teachers", 
		a.requireActivatedUser(http.HandlerFunc(a.listTeachersHandler)))
	router.Handler(http.MethodPost, apiV1Route+"/teachers", 
		a.requireActivatedUser(http.HandlerFunc(a.createTeacherHandler)))
	// Register literal paths and sub-resources before wildcard :id to avoid conflicts
	// These sub-resource routes must come before /teachers/:id
	router.Handler(http.MethodGet, apiV1Route+"/teachers/:id/education", 
	a.requireActivatedUser(http.HandlerFunc(a.getEducationByTeacherHandler)))
	router.Handler(http.MethodGet, apiV1Route+"/teachers/:id/qualifications", 
	a.requireActivatedUser(http.HandlerFunc(a.getQualificationsByTeacherHandler)))
	router.Handler(http.MethodGet, apiV1Route+"/teachers/:id/documents", 
	a.requireActivatedUser(http.HandlerFunc(a.getDocumentsByTeacherHandler)))
	// Wildcard routes must come last
	router.Handler(http.MethodPatch, apiV1Route+"/teachers/:id", 
	a.requireActivatedUser(http.HandlerFunc(a.updateTeacherHandler)))
	router.Handler(http.MethodDelete, apiV1Route+"/teachers/:id", 
	a.requireAnyRole([]string{"admin", "CEO", "TSC"}, http.HandlerFunc(a.deleteTeacherHandler)))
	router.Handler(http.MethodGet, apiV1Route+"/teachers/:id", 
	a.requireActivatedUser(http.HandlerFunc(a.getTeacherHandler)))
	router.Handler(http.MethodGet, apiV1Route+"/teacher/user/:id", 
		a.requireActivatedUser(http.HandlerFunc(a.getTeacherByUserIDHandler)))

	// Education routes - Teachers can manage their own, admin/CEO/TSC/DEC can manage all (must be activated)
	router.Handler(http.MethodPost, apiV1Route+"/education", 
		a.requireActivatedUser(http.HandlerFunc(a.createEducationHandler)))
	router.Handler(http.MethodGet, apiV1Route+"/education/:id", 
		a.requireActivatedUser(http.HandlerFunc(a.getEducationHandler)))
	router.Handler(http.MethodDelete, apiV1Route+"/education/:id", 
		a.requireActivatedUser(http.HandlerFunc(a.deleteEducationHandler)))
	// Qualification routes - Teachers can manage their own, admin/CEO/TSC/DEC can manage all (must be activated)
	router.Handler(http.MethodPost, apiV1Route+"/qualifications", 
		a.requireActivatedUser(http.HandlerFunc(a.createQualificationHandler)))
	router.Handler(http.MethodPatch, apiV1Route+"/qualifications/:id", 
		a.requireActivatedUser(http.HandlerFunc(a.updateQualificationHandler)))
	router.Handler(http.MethodDelete, apiV1Route+"/qualifications/:id", 
		a.requireActivatedUser(http.HandlerFunc(a.deleteQualificationHandler)))

	// Document routes - Teachers can manage their own, admin/CEO/TSC/DEC can manage all (must be activated)
	router.Handler(http.MethodPost, apiV1Route+"/documents", 
		a.requireActivatedUser(http.HandlerFunc(a.createDocumentHandler)))
	router.Handler(http.MethodGet, apiV1Route+"/documents/:id", 
		a.requireActivatedUser(http.HandlerFunc(a.getDocumentHandler)))
	router.Handler(http.MethodPatch, apiV1Route+"/documents/:id", 
		a.requireActivatedUser(http.HandlerFunc(a.updateDocumentHandler)))
	router.Handler(http.MethodDelete, apiV1Route+"/documents/:id", 
		a.requireActivatedUser(http.HandlerFunc(a.deleteDocumentHandler)))
	
	// Application routes - Teachers can create/view their own, admin/CEO/TSC/DEC can manage all (must be activated)
	router.Handler(http.MethodPost, apiV1Route+"/applications", 
		a.requireActivatedUser(http.HandlerFunc(a.createApplicationHandler)))
	router.Handler(http.MethodGet, apiV1Route+"/applications", 
		a.requireActivatedUser(http.HandlerFunc(a.getAllApplicationsHandler)))
	router.Handler(http.MethodGet, apiV1Route+"/application/teacher/:id", 
		a.requireActivatedUser(http.HandlerFunc(a.getApplicationsByTeacherHandler)))
	router.Handler(http.MethodGet, apiV1Route+"/applications/:id", 
		a.requireActivatedUser(http.HandlerFunc(a.getApplicationHandler)))
	router.Handler(http.MethodPatch, apiV1Route+"/applications/:id", 
		a.requireAnyRole([]string{"admin", "CEO", "TSC", "DEC"}, http.HandlerFunc(a.updateApplicationHandler)))
	router.Handler(http.MethodDelete, apiV1Route+"/applications/:id", 
		a.requireAnyRole([]string{"admin", "CEO", "TSC"}, http.HandlerFunc(a.deleteApplicationHandler)))
	
	// Notification routes - admin/CEO/Secretary can create, users can manage their own (must be activated)
	router.Handler(http.MethodPost, apiV1Route+"/notifications", a.requireAnyRole([]string{"admin", "CEO", "Secretary"}, http.HandlerFunc(a.createNotificationHandler)))
	router.Handler(http.MethodPatch, apiV1Route+"/notifications/:id/read", 
		a.requireActivatedUser(http.HandlerFunc(a.markNotificationAsReadHandler)))
	router.Handler(http.MethodGet, apiV1Route+"/notifications/:id", 
		a.requireActivatedUser(http.HandlerFunc(a.getNotificationHandler)))
	router.Handler(http.MethodDelete, apiV1Route+"/notifications/:id", 
		a.requireActivatedUser(http.HandlerFunc(a.deleteNotificationHandler)))
	// Token routes
	// *-- get token for login (public) -- *
	router.HandlerFunc(http.MethodPost, apiV1Route+"/tokens/authentication", a.createAuthTokenHandler)
	// *-- create an activation token (public) -- *
	router.HandlerFunc(http.MethodPost, apiV1Route+"/tokens/activation", a.createActivationTokenHandler)
	// Only admin can delete all tokens for a user (must be activated)
	router.Handler(http.MethodDelete, apiV1Route+"/tokens/user/:user_id", 
		a.authenticate(a.requireActivatedUser(a.requireRole("admin", http.HandlerFunc(a.deleteAllTokensForUserHandler)))))

	// Apply middleware
	handler := a.recoverPanic(router)
	handler = a.enableCORS(handler)
	handler = a.authenticate(handler)
	handler = a.rateLimit(handler)

	return handler
}
