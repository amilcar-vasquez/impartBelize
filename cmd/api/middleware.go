package main

import (
	"errors"
	"fmt"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/amilcar-vasquez/impartBelize/internal/data"
	"github.com/amilcar-vasquez/impartBelize/internal/validator"
	"golang.org/x/time/rate"
)

func (a *app) recoverPanic(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				w.Header().Set("Connection", "close")
				a.serverErrorResponse(w, r, fmt.Errorf("%v", err))
			}
		}()
		next.ServeHTTP(w, r)
	})
}

func (a *app) enableCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Add("Vary", "Origin")
		w.Header().Add("Vary", "Access-Control-Request-Method")

		origin := r.Header.Get("Origin")

		if origin != "" {
			// Check if origin matches any trusted origin (with wildcard support)
			for i := range a.config.cors.trustedOrigins {
				trusted := a.config.cors.trustedOrigins[i]
				// Support wildcard matching for localhost and 127.0.0.1
				if trusted == origin ||
					(strings.HasSuffix(trusted, "*") && strings.HasPrefix(origin, trusted[:len(trusted)-1])) ||
					(strings.Contains(origin, "localhost") && strings.Contains(trusted, "localhost")) ||
					(strings.Contains(origin, "127.0.0.1") && strings.Contains(trusted, "127.0.0.1")) {

					w.Header().Set("Access-Control-Allow-Origin", origin)
					w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
					w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")

					if r.Method == "OPTIONS" {
						w.WriteHeader(http.StatusOK)
						return
					}
					break
				}
			}
		}
		next.ServeHTTP(w, r)
	})
}

func (a *app) rateLimit(next http.Handler) http.Handler {
	type client struct {
		limiter  *rate.Limiter
		lastSeen time.Time
	}

	var mu sync.Mutex
	var clients = make(map[string]*client)

	go func() {
		for {
			time.Sleep(time.Minute)
			mu.Lock()

			for ip, client := range clients {
				if time.Since(client.lastSeen) > 3*time.Minute {
					delete(clients, ip)
				}
			}
			mu.Unlock()
		}
	}()

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if a.config.limiter.enabled {
			ip, _, err := net.SplitHostPort(r.RemoteAddr)
			if err != nil {
				a.serverErrorResponse(w, r, err)
				return
			}

			mu.Lock()

			_, found := clients[ip]
			if !found {
				clients[ip] = &client{limiter: rate.NewLimiter(rate.Limit(a.config.limiter.rps), a.config.limiter.burst)}
			}

			clients[ip].lastSeen = time.Now()

			if !clients[ip].limiter.Allow() {
				mu.Unlock()
				a.rateLimitExceededResponse(w, r)
				return
			}

			mu.Unlock()
		}
		next.ServeHTTP(w, r)
	})
}

func (a *app) authenticate(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Add("Vary", "Authorization")

		// Get the Authorization header from the request. It should have the
		// Bearer token
		authorizationHeader := r.Header.Get("Authorization")

		// If there is no Authorization header then we have an Anonymous user
		if authorizationHeader == "" {
			r = a.contextSetUser(r, data.AnonymousUser)
			next.ServeHTTP(w, r)
			return
		}

		headerParts := strings.Split(authorizationHeader, " ")
		if len(headerParts) != 2 || headerParts[0] != "Bearer" {
			a.invalidAuthenticationTokenResponse(w, r)
			return
		}

		// Get the actual token
		token := headerParts[1]
		// Validate
		v := validator.New()
		data.ValidateTokenPlaintext(v, token)
		if !v.IsEmpty() {
			a.invalidAuthenticationTokenResponse(w, r)
			return
		}

		// Get the user info associated with this authentication token
		user, err := a.models.Users.GetForToken(data.ScopeAuthentication, token)
		if err != nil {
			switch {
			case errors.Is(err, data.ErrRecordNotFound):
				a.invalidAuthenticationTokenResponse(w, r)
			default:
				a.serverErrorResponse(w, r, err)
			}
			return
		}
		// Add the retrieved user info to the context
		r = a.contextSetUser(r, user)

		// Call the next handler in the chain.
		next.ServeHTTP(w, r)
	})
}

func (a *app) requireAuthenticatedUser(next http.HandlerFunc) http.HandlerFunc {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

		user := a.contextGetUser(r)

		if user.IsAnonymous() {
			a.authenticationRequiredResponse(w, r)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (a *app) requireActivatedUser(next http.HandlerFunc) http.HandlerFunc {
	fn := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user := a.contextGetUser(r)

		if !user.IsActive {
			a.inactiveAccountResponse(w, r)
			return
		}

		next.ServeHTTP(w, r)
	})
	return a.requireAuthenticatedUser(fn)
}



// This middleware checks if the user has the required role
// We send the role name that is expected as an argument
func (a *app) requireRole(roleName string, next http.HandlerFunc) http.HandlerFunc {
	fn := func(w http.ResponseWriter, r *http.Request) {
		user := a.contextGetUser(r)

		// Get the user's role from the database
		role, err := a.models.Roles.Get(user.RoleID)
		if err != nil {
			a.serverErrorResponse(w, r, err)
			return
		}

		// Check if the user has the required role
		if role.RoleName != roleName {
			a.notPermittedResponse(w, r)
			return
		}

		// User has the correct role, continue
		next.ServeHTTP(w, r)
	}

	return a.requireActivatedUser(fn)
}

// This middleware checks if the user has one of multiple allowed roles
func (a *app) requireAnyRole(roleNames []string, next http.HandlerFunc) http.HandlerFunc {
	fn := func(w http.ResponseWriter, r *http.Request) {
		user := a.contextGetUser(r)

		// Get the user's role from the database
		role, err := a.models.Roles.Get(user.RoleID)
		if err != nil {
			a.serverErrorResponse(w, r, err)
			return
		}

		// Check if the user has any of the allowed roles
		hasRole := false
		for _, allowedRole := range roleNames {
			if role.RoleName == allowedRole {
				hasRole = true
				break
			}
		}

		if !hasRole {
			a.notPermittedResponse(w, r)
			return
		}

		// User has one of the allowed roles, continue
		next.ServeHTTP(w, r)
	}

	return a.requireActivatedUser(fn)
}
