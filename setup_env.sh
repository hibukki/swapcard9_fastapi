#!/usr/bin/env bash

#############################################################################
# FastAPI Backend - Environment Setup Script
#
# This script sets up a complete development environment from a clean image
# including PostgreSQL, Python dependencies, and database initialization.
#
# Usage:
#   ./setup_env.sh                  # Setup environment only
#   ./setup_env.sh --run            # Setup and run the server
#   ./setup_env.sh --test           # Setup and run tests
#   ./setup_env.sh --help           # Show help
#
#############################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
POSTGRES_PASSWORD="changethis"
DB_NAME="app"
BACKEND_DIR="/home/user/swapcard9_fastapi/backend"

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
}

# Function to show help
show_help() {
    cat << EOF
FastAPI Backend - Environment Setup Script

This script sets up a complete development environment from a clean image.

Usage:
    ./setup_env.sh [OPTIONS]

Options:
    --run       Setup environment and start the development server
    --test      Setup environment and run the test suite
    --help      Show this help message

Examples:
    ./setup_env.sh              # Setup environment only
    ./setup_env.sh --run        # Setup and run server
    ./setup_env.sh --test       # Setup and run tests

What this script does:
    1. Installs PostgreSQL
    2. Configures database and user
    3. Installs uv (Python package manager)
    4. Installs Python dependencies
    5. Runs database migrations
    6. Creates initial superuser

Default credentials:
    Email: admin@example.com
    Password: changethis

EOF
}

# Parse command line arguments
RUN_SERVER=false
RUN_TESTS=false

for arg in "$@"; do
    case $arg in
        --run)
            RUN_SERVER=true
            shift
            ;;
        --test)
            RUN_TESTS=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Start setup
print_header "FastAPI Backend - Environment Setup"

# Step 1: Install PostgreSQL
print_header "Step 1/7: Installing PostgreSQL"
if command -v psql &> /dev/null; then
    print_success "PostgreSQL is already installed"
else
    print_info "Updating package lists..."
    apt-get update -qq

    print_info "Installing PostgreSQL..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq postgresql postgresql-contrib > /dev/null
    print_success "PostgreSQL installed successfully"
fi

# Step 2: Start PostgreSQL
print_header "Step 2/7: Starting PostgreSQL"
if service postgresql status > /dev/null 2>&1; then
    print_success "PostgreSQL is already running"
else
    print_info "Starting PostgreSQL service..."
    service postgresql start > /dev/null
    print_success "PostgreSQL started successfully"
fi

# Step 3: Configure PostgreSQL
print_header "Step 3/7: Configuring PostgreSQL"

print_info "Setting postgres user password..."
sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$POSTGRES_PASSWORD';" > /dev/null
print_success "Password set"

print_info "Creating database '$DB_NAME'..."
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    print_warning "Database '$DB_NAME' already exists"
else
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;" > /dev/null
    print_success "Database created"
fi

# Step 4: Install uv
print_header "Step 4/7: Installing uv (Python package manager)"
if command -v uv &> /dev/null; then
    print_success "uv is already installed ($(uv --version))"
else
    print_info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh > /dev/null 2>&1
    export PATH="/root/.local/bin:$PATH"
    print_success "uv installed successfully"
fi

# Ensure uv is in PATH
export PATH="/root/.local/bin:$PATH"

# Step 5: Install Python dependencies
print_header "Step 5/7: Installing Python dependencies"
print_info "Navigating to backend directory: $BACKEND_DIR"
cd "$BACKEND_DIR"

print_info "Installing dependencies with uv (this may take a few minutes)..."
uv sync --quiet
print_success "Dependencies installed successfully"

# Step 6: Initialize database
print_header "Step 6/7: Initializing database"

print_info "Activating virtual environment..."
source .venv/bin/activate

print_info "Checking database connection..."
if python app/backend_pre_start.py > /dev/null 2>&1; then
    print_success "Database connection successful"
else
    print_error "Database connection failed"
    exit 1
fi

print_info "Running database migrations..."
alembic upgrade head > /dev/null 2>&1
print_success "Migrations completed"

print_info "Creating initial superuser..."
python app/initial_data.py > /dev/null 2>&1
print_success "Initial data created"

# Step 7: Summary
print_header "Setup Complete!"

cat << EOF
${GREEN}✓${NC} Environment setup completed successfully!

${BLUE}Database Information:${NC}
  Host:     localhost
  Port:     5432
  Database: $DB_NAME
  User:     postgres
  Password: $POSTGRES_PASSWORD

${BLUE}Default Superuser:${NC}
  Email:    admin@example.com
  Password: changethis

${BLUE}Backend Directory:${NC}
  $BACKEND_DIR

EOF

# Run server if requested
if [ "$RUN_SERVER" = true ]; then
    print_header "Starting Development Server"
    print_info "Server will be available at: ${GREEN}http://localhost:8000${NC}"
    print_info "API docs available at: ${GREEN}http://localhost:8000/docs${NC}"
    print_info "Press Ctrl+C to stop the server"
    echo ""

    cd "$BACKEND_DIR"
    source .venv/bin/activate
    fastapi dev app/main.py
    exit 0
fi

# Run tests if requested
if [ "$RUN_TESTS" = true ]; then
    print_header "Running Tests"
    cd "$BACKEND_DIR"
    source .venv/bin/activate
    pytest
    exit 0
fi

# Show next steps
cat << EOF
${BLUE}Next Steps:${NC}

1. Start the development server:
   ${GREEN}cd $BACKEND_DIR${NC}
   ${GREEN}source .venv/bin/activate${NC}
   ${GREEN}fastapi dev app/main.py${NC}

   Or run: ${GREEN}./setup_env.sh --run${NC}

2. Run tests:
   ${GREEN}cd $BACKEND_DIR${NC}
   ${GREEN}source .venv/bin/activate${NC}
   ${GREEN}pytest${NC}

   Or run: ${GREEN}./setup_env.sh --test${NC}

3. Visit the API documentation:
   ${GREEN}http://localhost:8000/docs${NC}

${BLUE}Subsequent Runs:${NC}
   Just run: ${GREEN}./setup_env.sh --run${NC}

EOF
