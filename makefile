include .envrc

# run/api: run the api server
.PHONY: run/api
run/api:
	@echo "Running API server..."
	@go run ./cmd/api --port=4000 --env=development --db-dsn=${DB_DSN}


## db/psql: connect to the database using psql (terminal)
.PHONY: db/psql
db/psql:
	@psql ${DB_DSN}

## db/migrations/new name=$1: create a new database migration
.PHONY: db/migrations/new
db/migrations/new:
	@echo 'Creating migration files for ${name}...'
	migrate create -seq -ext=.sql -dir=./migrations ${name}

## db/migrations/up: apply all up database migrations
.PHONY: db/migrations/up
db/migrations/up:
	@echo 'Running up migrations...'
	migrate -path ./migrations -database ${DB_DSN} up

## db/migrations/down: rollback last migration
.PHONY: db/migrations/down
db/migrations/down:
	@echo 'Rolling back last successful migration...'
	migrate -path ./migrations -database ${DB_DSN} down ${version}

.PHONY: db/migrations/version
db/migrations/version:
	@echo 'Current migration version...'
	migrate -path ./migrations -database ${DB_DSN} version

# force the migration version (use with caution)
.PHONY: db/migrations/force
db/migrations/force:
	@echo 'Forcing migration to ${version} version...'
	migrate -path ./migrations -database ${DB_DSN} force ${version}

## test: run all tests
.PHONY: test
test:
	@echo "Running tests..."
	@go test -v ./...
	@echo "Tests completed."