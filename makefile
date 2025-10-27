include .envrc

# run/api: run the api server
.PHONY: run/api
run/api:
	@echo "Running API server..."
	@go run ./cmd/api --port=4000 --env=development --db-dsn=${DB_DSN}