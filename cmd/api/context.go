package main

import (
	"context"
	"net/http"

	"github.com/amilcar-vasquez/impartBelize/internal/data"
)

type contextKey string

const userContextKey = contextKey("user")

func (a *app) contextSetUser(r *http.Request, user *data.User) *http.Request {
	// WithValue() expects the original context along with the new
	// key:value pair you want to update it with
    ctx := context.WithValue(r.Context(), userContextKey, user)
    return r.WithContext(ctx)
}

func (a *app) contextGetUser(r *http.Request) *data.User {
    user, ok := r.Context().Value(userContextKey).(*data.User)
    if !ok {
        panic("missing user value in request context")
    }

    return user
}
