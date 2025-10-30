#!/bin/bash

# Impart Belize - Database Setup Script
# This script creates the PostgreSQL database and user for the Impart Belize system

set -e  # Exit on any error

# Configuration
DB_NAME="impart"
DB_USER="impart"
DB_PASSWORD="ImpartBelize2025"
DB_HOST="localhost"
DB_PORT="5432"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if PostgreSQL is running
check_postgres() {
    print_status "Checking if PostgreSQL is running..."
    if ! pg_isready -h "$DB_HOST" -p "$DB_PORT" >/dev/null 2>&1; then
        print_error "PostgreSQL is not running or not accessible at $DB_HOST:$DB_PORT"
        print_error "Please start PostgreSQL service first:"
        print_error "  sudo systemctl start postgresql"
        print_error "  # or"
        print_error "  sudo service postgresql start"
        exit 1
    fi
    print_status "PostgreSQL is running ✓"
}

# Create database user
create_user() {
    print_status "Creating database user '$DB_USER'..."
    
    # Check if user already exists
    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
        print_warning "User '$DB_USER' already exists"
        
        # Update user password and privileges
        sudo -u postgres psql -c "ALTER USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
        sudo -u postgres psql -c "ALTER USER $DB_USER CREATEDB;"
        print_status "Updated existing user '$DB_USER' with new password and privileges"
    else
        # Create new user
        sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD' CREATEDB;"
        print_status "Created user '$DB_USER' ✓"
    fi
}

# Create database
create_database() {
    print_status "Creating database '$DB_NAME'..."
    
    # Check if database already exists
    if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
        print_warning "Database '$DB_NAME' already exists"
        read -p "Do you want to drop and recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo -u postgres psql -c "DROP DATABASE $DB_NAME;"
            print_status "Dropped existing database '$DB_NAME'"
        else
            print_status "Keeping existing database '$DB_NAME'"
            grant_privileges
            return
        fi
    fi
    
    # Create database
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
    print_status "Created database '$DB_NAME' ✓"
}

# Grant privileges
grant_privileges() {
    print_status "Granting privileges to user '$DB_USER' on database '$DB_NAME'..."
    
    # Connect to the database and grant privileges
    sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
    sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL ON SCHEMA public TO $DB_USER;"
    sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;"
    sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;"
    sudo -u postgres psql -d "$DB_NAME" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;"
    sudo -u postgres psql -d "$DB_NAME" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;"
    
    print_status "Granted all privileges ✓"
}

# Test connection
test_connection() {
    print_status "Testing database connection..."
    
    # Test connection with the new user
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" >/dev/null 2>&1; then
        print_status "Database connection test successful ✓"
    else
        print_error "Failed to connect to database with user '$DB_USER'"
        exit 1
    fi
}

# Generate environment file
generate_env_file() {
    print_status "Generating environment configuration..."
    
    # Create .envrc file for the project
    cat > .envrc << EOF
# Belize Police Department - Nforce Academy Database Configuration
export POLICE_TRAINING_DB_DSN="postgres://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME?sslmode=disable"

# Individual components (for reference)
export DB_HOST="$DB_HOST"
export DB_PORT="$DB_PORT"
export DB_NAME="$DB_NAME"
export DB_USER="$DB_USER"
export DB_PASSWORD="$DB_PASSWORD"
EOF

    print_status "Created .envrc file with database configuration ✓"
    print_warning "Make sure to source the .envrc file or install direnv:"
    print_warning "  source .envrc"
    print_warning "  # or install direnv and run: direnv allow"
}

# Main execution
main() {
    echo "================================================"
    echo "Impart Belize - Database Setup Script"
    echo "================================================"
    echo
    
    check_postgres
    create_user
    create_database
    grant_privileges
    test_connection
    generate_env_file
    
    echo
    echo "================================================"
    print_status "Database setup completed successfully!"
    echo "================================================"
    echo
    echo "Connection Details:"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_USER"
    echo "  Host: $DB_HOST"
    echo "  Port: $DB_PORT"
    echo
    echo "DSN: postgres://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME?sslmode=disable"
    echo
    echo "Next steps:"
    echo "  1. Source the environment file: source .envrc"
    echo "  2. Run migrations: make db/migrations/up"
    echo "  3. Start the application: make run/api"
    echo
}

# Check if running as root (not recommended for this script)
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root. This script will use 'sudo -u postgres' for database operations."
fi

# Run main function
main "$@"