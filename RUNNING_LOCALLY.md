# Running the Backend Locally - Complete Guide

This guide provides step-by-step instructions to run the FastAPI backend locally from scratch.

## Prerequisites

- Python 3.11+ (already installed in this environment)
- Git (already installed)

## Step 1: Install Required Tools

### Install uv (Python package manager)

```bash
# If not already installed
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Install PostgreSQL

```bash
# Update package list and install PostgreSQL
apt-get update
apt-get install -y postgresql postgresql-contrib

# Start PostgreSQL service
service postgresql start
```

## Step 2: Configure PostgreSQL

```bash
# Set password for postgres user (matches .env file)
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'changethis';"

# Create the application database
sudo -u postgres psql -c "CREATE DATABASE app;"

# Verify database was created
sudo -u postgres psql -c "\l" | grep app
```

## Step 3: Install Backend Dependencies

```bash
# Navigate to backend directory
cd /home/user/swapcard9_fastapi/backend

# Install dependencies using uv
uv sync

# Activate virtual environment
source .venv/bin/activate
```

## Step 4: Initialize Database

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

## Step 5: Run the Backend Server

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

## Step 6: Test the API

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

## Step 7: Run Tests

```bash
# Make sure you're in the backend directory with venv activated
cd /home/user/swapcard9_fastapi/backend
source .venv/bin/activate

# Run tests with pytest (recommended for quick testing)
pytest
```

Or run tests with coverage:

```bash
cd /home/user/swapcard9_fastapi/backend
source .venv/bin/activate

# Run tests with coverage report
bash ./scripts/test.sh
```

Expected output: **55 passed** (all tests should pass)

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

## Quick Start (All Commands)

If everything is already installed, use these commands:

```bash
# Start PostgreSQL
service postgresql start

# Navigate and activate environment
cd /home/user/swapcard9_fastapi/backend
source .venv/bin/activate

# Run the server
fastapi dev app/main.py
```

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
