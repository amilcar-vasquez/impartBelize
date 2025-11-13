# Role-Based Access Control (RBAC)

## Overview

The API now implements role-based authorization middleware to protect endpoints based on user roles.

## Roles

The system has 6 defined roles:

| Role ID | Role Name | Description                      |
| ------- | --------- | -------------------------------- |
| 1       | Admin     | Full system access               |
| 2       | DEC       | District Education Center        |
| 3       | Teacher   | Teacher with limited permissions |
| 4       | TSC       | Teacher Service Commission       |
| 5       | CEO       | Chief Executive Officer          |
| 6       | Secretary | Administrative support           |

## Middleware Functions

### authenticate

Validates the bearer token from the `Authorization` header and adds the user to the request context.

-   If no token is provided, sets the user as anonymous
-   Validates token format (26 characters)
-   Retrieves user from database using the token
-   Adds user to request context

### requireAuthenticatedUser

Ensures the user is authenticated (not anonymous). Returns 401 if user is not authenticated.

### requireActivatedUser

Ensures the user has activated their account via the email activation code. Returns 403 if the account is not activated.

**Important:** Most protected endpoints require both authentication AND activation. Users must:

1. Register an account (POST /v1/users)
2. Activate their account using the 6-digit code sent to their email (PUT /v1/users/activated)
3. Login to get an authentication token (POST /v1/tokens/authentication)
4. Include the token in the Authorization header for protected endpoints

### requireRole(roleID int)

Ensures the user has a specific role. Returns 403 if user doesn't have the required role.

### requireAnyRole(roleIDs ...int)

Ensures the user has at least one of the specified roles. Returns 403 if user doesn't have any of the required roles.

## Endpoint Protection

### Public Endpoints (No Authentication Required)

-   `GET /v1/healthcheck` - Health check
-   `POST /v1/users` - User registration
-   `PUT /v1/users/activated` - Account activation
-   `POST /v1/tokens/authentication` - Login
-   `POST /v1/tokens/activation` - Request activation token

### User Management

-   `GET /v1/users` - Admin, CEO, DEC, TSC
-   `GET /v1/users/:id` - Admin, CEO, DEC, TSC
-   `PATCH /v1/users/:id` - Admin, CEO, DEC
-   `DELETE /v1/users/:id` - Admin only

### Role Management

-   `POST /v1/roles` - Admin only
-   `GET /v1/roles` - All authenticated users
-   `GET /v1/roles/:id` - All authenticated users
-   `PATCH /v1/roles/:id` - Admin only
-   `DELETE /v1/roles/:id` - Admin only

### District Management

-   `POST /v1/districts` - Admin, CEO, DEC
-   `GET /v1/districts` - All authenticated users
-   `GET /v1/districts/:id` - All authenticated users
-   `DELETE /v1/districts/:id` - Admin, CEO

### Institution Management

-   `POST /v1/institutions` - Admin, CEO, DEC, TSC
-   `GET /v1/institutions` - All authenticated users
-   `GET /v1/institutions/:id` - All authenticated users
-   `DELETE /v1/institutions/:id` - Admin, CEO

### Teacher Management

-   `GET /v1/teachers` - All authenticated users
-   `POST /v1/teachers` - Admin, CEO, TSC, DEC
-   `GET /v1/teachers/:id` - All authenticated users
-   `DELETE /v1/teachers/:id` - Admin, CEO, TSC

### Education Records

-   `POST /v1/education` - All authenticated users (teachers for their own)
-   `GET /v1/education/:id` - All authenticated users
-   `DELETE /v1/education/:id` - All authenticated users (teachers for their own)

### Qualifications

-   `POST /v1/qualifications` - All authenticated users (teachers for their own)
-   `DELETE /v1/qualifications/:id` - All authenticated users (teachers for their own)

### Documents

-   `POST /v1/documents` - All authenticated users (teachers for their own)
-   `GET /v1/documents/:id` - All authenticated users
-   `DELETE /v1/documents/:id` - All authenticated users (teachers for their own)

### Notifications

-   `POST /v1/notifications` - Admin, CEO, Secretary
-   `PATCH /v1/notifications/:id/read` - All authenticated users (for their own)
-   `GET /v1/notifications/:id` - All authenticated users (for their own)
-   `DELETE /v1/notifications/:id` - All authenticated users (for their own)

### Token Management

-   `DELETE /v1/tokens/user/:user_id` - Admin only

## Usage in Handlers

Handlers can access the authenticated user from the request context:

```go
user := a.contextGetUser(r)

// Check if user is anonymous
if user.IsAnonymous() {
    // Handle anonymous user
}

// Access user properties
userID := user.ID
roleID := user.RoleID
roleName := user.RoleName
isActivated := user.IsActivated
```

## Error Responses

### 401 Unauthorized

Returned when:

-   Invalid or missing authentication token
-   User is not authenticated but endpoint requires authentication

### 403 Forbidden

Returned when:

-   User account is not activated (must complete email activation first)
-   User is authenticated but doesn't have the required role(s)
-   Access is not permitted for the user's role

## Example Request

```bash
# Login to get token
curl -X POST http://localhost:4000/v1/tokens/authentication \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}'

# Use token for authenticated request
curl -X GET http://localhost:4000/v1/users \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Future Enhancements

Consider implementing:

1. Resource-level permissions (e.g., teachers can only edit their own profile)
2. Permission inheritance and role hierarchies
3. Audit logging for sensitive operations
4. Token refresh mechanism
5. Role-based field filtering in responses
