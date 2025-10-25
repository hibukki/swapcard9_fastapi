# Running the Backend Locally - Complete Guide

This guide provides step-by-step instructions to run the FastAPI backend locally from a completely clean environment.

## Table of Contents

1. [Quick Start with Setup Script](#quick-start-with-setup-script) - **⭐ Recommended Method**
2. [Prerequisites](#prerequisites)
3. [Manual Setup Instructions](#manual-setup-instructions) - Alternative to script
4. [Testing the API](#testing-the-api)
5. [Running Tests](#running-tests)
6. [Troubleshooting](#troubleshooting)
7. [Test Results Summary](#test-results-summary)
8. [Verified Functionality](#verified-functionality)

---

## Quick Start with Setup Script

**⭐ This is the recommended method** - use the automated setup script that handles everything for you.

### Setup and Run Server

```bash
./setup_env.sh --run
```

This single command will:
- Install PostgreSQL
- Configure database and user
- Install uv and Python dependencies
- Run database migrations
- Create initial superuser
- Start the development server

### Setup and Run Tests

```bash
./setup_env.sh --test
```

### Setup Only (no server/tests)

```bash
./setup_env.sh
```

### View Help

```bash
./setup_env.sh --help
```

### Subsequent Runs

After initial setup, just run:

```bash
./setup_env.sh --run
```

The script is smart enough to detect what's already installed and skip those steps.

---

## Prerequisites

This guide assumes you're starting from a clean Ubuntu/Debian-based system with:
- Python 3.10+ available
- Git available
- Root or sudo access

All other dependencies will be installed automatically by the setup script.

---

## Manual Setup Instructions

If you prefer to run commands manually instead of using the script, follow these instructions.

### Complete Setup from Clean Image

Run these commands in order to set up everything from scratch:

```bash
# Step 1: Update package manager and install PostgreSQL
apt-get update
apt-get install -y postgresql postgresql-contrib

# Step 2: Start PostgreSQL service
service postgresql start

# Step 3: Configure PostgreSQL database and user
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'changethis';"
sudo -u postgres psql -c "CREATE DATABASE app;"

# Step 4: Install uv (Python package manager) if not already installed
curl -LsSf https://astral.sh/uv/install.sh | sh

# Step 5: Add uv to PATH for current session (if just installed)
export PATH="/root/.local/bin:$PATH"

# Step 6: Navigate to backend directory
cd /home/user/swapcard9_fastapi/backend

# Step 7: Install Python dependencies with uv
uv sync

# Step 8: Activate virtual environment
source .venv/bin/activate

# Step 9: Check database connection
python app/backend_pre_start.py

# Step 10: Run database migrations
alembic upgrade head

# Step 11: Create initial data (superuser)
python app/initial_data.py

# Step 12: Start the development server
fastapi dev app/main.py
```

The server will now be running at http://localhost:8000

### Copy-Paste Single Command

If you want to run everything in one command, copy and paste this:

```bash
apt-get update && \
apt-get install -y postgresql postgresql-contrib && \
service postgresql start && \
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'changethis';" && \
sudo -u postgres psql -c "CREATE DATABASE app;" && \
curl -LsSf https://astral.sh/uv/install.sh | sh && \
export PATH="/root/.local/bin:$PATH" && \
cd /home/user/swapcard9_fastapi/backend && \
uv sync && \
source .venv/bin/activate && \
python app/backend_pre_start.py && \
alembic upgrade head && \
python app/initial_data.py && \
echo "✅ Setup complete! Now run: fastapi dev app/main.py"
```

Then start the server:
```bash
cd /home/user/swapcard9_fastapi/backend && source .venv/bin/activate && fastapi dev app/main.py
```

### Detailed Step-by-Step Instructions

If you prefer to understand each step in detail, follow these instructions.

#### Step 1: Install Required Tools

**Install PostgreSQL**

```bash
# Update package list and install PostgreSQL
apt-get update
apt-get install -y postgresql postgresql-contrib

# Start PostgreSQL service
service postgresql start

# Verify PostgreSQL is running
service postgresql status
```

**Install uv (Python package manager)**

```bash
# Install uv if not already installed
curl -LsSf https://astral.sh/uv/install.sh | sh

# Add to PATH (if just installed)
export PATH="/root/.local/bin:$PATH"

# Verify installation
uv --version
```

#### Step 2: Configure PostgreSQL

```bash
# Set password for postgres user (matches .env file)
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'changethis';"

# Create the application database
sudo -u postgres psql -c "CREATE DATABASE app;"

# Verify database was created
sudo -u postgres psql -c "\l" | grep app
```

#### Step 3: Install Backend Dependencies

```bash
# Navigate to backend directory
cd /home/user/swapcard9_fastapi/backend

# Install dependencies using uv
uv sync

# Activate virtual environment
source .venv/bin/activate
```

#### Step 4: Initialize Database

```bash
# Make sure you're in the backend directory with venv activated
cd /home/user/swapcard9_fastapi/backend
source .venv/bin/activate

# Check database connection
python app/backend_pre_start.py

# Run database migrations
alembic upgrade head

# Create initial data (superuser)
python app/initial_data.py
```

#### Step 5: Run the Backend Server

```bash
# Make sure you're in the backend directory with venv activated
cd /home/user/swapcard9_fastapi/backend
source .venv/bin/activate

# Start development server (with hot reload)
fastapi dev app/main.py
```

The server will be available at:
- **API**: http://localhost:8000
- **Interactive API Docs**: http://localhost:8000/docs
- **Alternative Docs**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/api/v1/openapi.json

---

## Testing the API

### Test Health Check

```bash
curl http://localhost:8000/api/v1/utils/health-check/
```

### Login and Get Token

```bash
curl -X POST "http://localhost:8000/api/v1/login/access-token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin@example.com&password=changethis"
```

### Test Authenticated Endpoint

```bash
# First get a token (replace YOUR_TOKEN with the token from previous step)
TOKEN="YOUR_TOKEN"

# Get current user
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/v1/users/me"

# Get all items
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/v1/items/"

# Create an item
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Item","description":"This is a test"}' \
  "http://localhost:8000/api/v1/items/"
```

---

## Running Tests

**Prerequisites for tests:**
- PostgreSQL must be running (`service postgresql start`)
- Database must be configured (see Step 2)
- Dependencies must be installed (`uv sync`)

### Run Tests Quickly

```bash
# Make sure PostgreSQL is running
service postgresql status || service postgresql start

# Navigate to backend directory and activate venv
cd /home/user/swapcard9_fastapi/backend
source .venv/bin/activate

# Run tests with pytest (recommended for quick testing)
pytest
```

### Run Tests with Coverage Report

```bash
cd /home/user/swapcard9_fastapi/backend
source .venv/bin/activate

# Run tests with coverage report
bash ./scripts/test.sh

# Coverage report will be generated in htmlcov/index.html
```

### Complete Test Command from Clean Image

If you want to run tests immediately after setup:

```bash
# Complete setup + run tests (from clean image)
apt-get update && \
apt-get install -y postgresql postgresql-contrib && \
service postgresql start && \
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'changethis';" && \
sudo -u postgres psql -c "CREATE DATABASE app;" && \
curl -LsSf https://astral.sh/uv/install.sh | sh && \
export PATH="/root/.local/bin:$PATH" && \
cd /home/user/swapcard9_fastapi/backend && \
uv sync && \
source .venv/bin/activate && \
python app/backend_pre_start.py && \
alembic upgrade head && \
python app/initial_data.py && \
pytest
```

**Expected output:** ✅ **55 passed** (all tests should pass)

**Note:** If tests fail with connection timeout errors, restart PostgreSQL:

```bash
service postgresql restart
```

## Default Credentials

The initial superuser is created with these credentials (configured in `.env`):

- **Email**: admin@example.com
- **Password**: changethis

**⚠️ IMPORTANT**: Change these values in production!

## Environment Variables

Key environment variables in `.env` file:

```env
POSTGRES_SERVER=localhost
POSTGRES_PORT=5432
POSTGRES_DB=app
POSTGRES_USER=postgres
POSTGRES_PASSWORD=changethis

SECRET_KEY=changethis
FIRST_SUPERUSER=admin@example.com
FIRST_SUPERUSER_PASSWORD=changethis
```

## Troubleshooting

### PostgreSQL not starting

```bash
service postgresql status
service postgresql start
```

### Database connection errors

```bash
# Check PostgreSQL is running
service postgresql status

# Check database exists
sudo -u postgres psql -c "\l"

# Verify user and password
sudo -u postgres psql -c "\du"
```

### Port already in use

```bash
# Check what's using port 8000
lsof -i :8000

# Kill the process if needed
kill -9 <PID>
```

### Reset database

```bash
cd /home/user/swapcard9_fastapi/backend
source .venv/bin/activate

# Drop and recreate database
sudo -u postgres psql -c "DROP DATABASE app;"
sudo -u postgres psql -c "CREATE DATABASE app;"

# Re-run migrations
alembic upgrade head
python app/initial_data.py
```

---

## Manual Server Start (Without Script)

If you prefer to start the server manually after setup:

```bash
# 1. Start PostgreSQL (if not already running)
service postgresql start

# 2. Navigate to backend directory and activate environment
cd /home/user/swapcard9_fastapi/backend
source .venv/bin/activate

# 3. Start the development server
fastapi dev app/main.py
```

Or as a one-liner:
```bash
service postgresql start && cd /home/user/swapcard9_fastapi/backend && source .venv/bin/activate && fastapi dev app/main.py
```

**Recommended:** Use `./setup_env.sh --run` instead for a simpler experience.

## Known Warnings

You may see these warnings during startup - they are expected in development:

1. **Security warnings** about `SECRET_KEY`, `POSTGRES_PASSWORD`, and `FIRST_SUPERUSER_PASSWORD` being "changethis"
   - These are intentional for development
   - Change them for production deployments

2. **Bcrypt version warning**: `WARNING:passlib.handlers.bcrypt:(trapped) error reading bcrypt version`
   - This is cosmetic only and doesn't affect functionality
   - bcrypt 4.3.0 changed internal structure but works correctly

## Test Results Summary

All tests passing: ✅ **55/55 tests passed**

Test breakdown:
- Items API tests: 11 tests
- Login/Auth API tests: 7 tests
- Private API tests: 1 test
- Users API tests: 25 tests
- CRUD tests: 9 tests
- Scripts tests: 2 tests

Coverage areas:
- Authentication (JWT tokens, login, password reset)
- User CRUD operations (create, read, update, delete)
- Item CRUD operations
- Permissions and authorization
- Validation and error handling

## Verified Functionality

The following functionality has been tested and verified working:

### Core Features
- ✅ FastAPI server starts and runs
- ✅ PostgreSQL database connection
- ✅ Database migrations (4 migrations applied)
- ✅ Initial superuser creation
- ✅ Hot reload for development

### API Endpoints
- ✅ Health check endpoint
- ✅ JWT authentication
- ✅ User registration and login
- ✅ Password recovery
- ✅ User CRUD operations
- ✅ Item CRUD operations
- ✅ Permission-based access control
- ✅ OpenAPI documentation

### Development Tools
- ✅ Interactive API docs at `/docs`
- ✅ Alternative docs at `/redoc`
- ✅ OpenAPI JSON schema
- ✅ Test suite (pytest)
- ✅ Code coverage reporting

## Next Steps

- Visit http://localhost:8000/docs to explore the API interactively
- Modify models in `backend/app/models.py`
- Add API endpoints in `backend/app/api/`
- Update CRUD operations in `backend/app/crud.py`
- Run `alembic revision --autogenerate -m "description"` after model changes
