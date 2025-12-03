# SIH Atellica Connect Analytics Component

Siemens Healthineers development repository for the Atellica Connect Analytics Component - a comprehensive analytics platform providing compliance monitoring, audit management, and reporting capabilities through Qlik Sense integration.

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Git Submodules Management](#git-submodules-management)
- [Starting Services](#starting-services)
- [Environment Configuration](#environment-configuration)
- [Development Workflow](#development-workflow)
- [Database Setup](#database-setup)
- [Service Descriptions](#service-descriptions)
- [Accessing Services](#accessing-services)
- [Common Tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)
- [Documentation](#documentation)

## Project Overview

The SIH Atellica Connect Analytics Component is a microservices-based analytics platform that integrates with Qlik Sense Enterprise to provide:

- **Compliance Dashboard**: Real-time compliance metrics and KPIs
- **Audit Management**: Comprehensive audit trail and investigation tools
- **Reporting**: Customizable reports and data exports

**Key Technologies**: React 18, Node.js, TypeScript, Hapi.js, PostgreSQL, Qlik Sense Enterprise, Docker

## Architecture

This project uses a **microservices architecture** with three main services:

```
┌──────────────────────────────────────────────────────────────────┐
│                    SIH Analytics Platform                        │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────┐                                         │
│  │   Frontend App     │ (Capability API via QPlus)              │
│  │  (React + Qlik)    │──────────────┐                          │
│  └──────────┬─────────┘              │                          │
│             │                         ▼                          │
│             │ (REST/HTTP)    ┌─────────────────────┐            │
│             │                │  Qlik Enterprise    │            │
│             │                │  Server (QES)       │            │
│             │                └──────────▲──────────┘            │
│             │                           │                        │
│             │                           │ (QRS/QPS/QIX)          │
│             ▼                           │                        │
│  ┌──────────────────────┐              │                        │
│  │   App API (Hapi.js)  │──────────────┘                        │
│  └──────────┬───────────┘  (Qlik Admin Operations)              │
│             │                    │                               │
│             ▼                    ▼                               │
│  ┌──────────────────┐   ┌────────────────────┐                 │
│  │  PostgreSQL DB   │   │   Qlik Service     │                 │
│  │                  │   │   (QES Wrapper)    │                 │
│  └──────────────────┘   └────────────────────┘                 │
└──────────────────────────────────────────────────────────────────┘
```

For detailed architecture documentation, see [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md).

## Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

- **Git**: Version 2.17.1 or higher
  ```bash
  git --version
  ```

- **Docker Desktop**: Version 20.10.8 or higher
  ```bash
  docker --version
  docker-compose --version
  ```

- **Node.js** (optional, for local development): Version 16.5.0 - 20.x
  ```bash
  node --version
  ```

- **NPM**: Version 9.0.0 or higher
  ```bash
  npm --version
  ```

### Important Docker Configuration

**Windows/Mac Users**:
- Open Docker Desktop → Settings → Resources → File Sharing
- **Ensure the drive containing this project is shared with Docker**
- This is critical for volume mounting to work correctly

### Access Requirements

- Access to Qlik Sense Enterprise Server
- VPN connection (if required for your organization)
- Qlik certificates (will be provided by your team lead)

## Quick Start

Get the project running in 6 steps:

### 1. Clone the Repository

```bash
git clone <repository-url>
cd db-siemens-dev
```

### 2. Initialize Submodules

```bash
git submodule update --init --remote
```

This will clone all three service repositories:
- `sih-atellica-qplus-backend` - Backend API
- `sih-atellica-qlik-service` - Qlik wrapper service
- `sih-atellica-qplus-frontend` - React frontend

### 3. Checkout Base Branches

```bash
./checkout-base-branches.sh
```

This ensures all repositories are on their correct base branches for development.

### 4. Configure Environment

Each service manages its own environment configuration. Copy the example files:

```bash
# App API configuration
cp sih-atellica-qplus-backend/.env.example sih-atellica-qplus-backend/.env

# Qlik Service configuration
cp sih-atellica-qlik-service/.env.example sih-atellica-qlik-service/.env

# Frontend configuration (if needed)
cp sih-atellica-qplus-frontend/.env.example sih-atellica-qplus-frontend/.env
```

Edit each service's `.env` file with your specific configuration (see [Environment Configuration](#environment-configuration) section).

### 5. Start All Services

```bash
docker-compose up
```

Wait for all services to start (this may take a few minutes on first run).

### 6. Run Database Migrations

In a new terminal (while services are running):

```bash
# If you have a migrations service/directory
cd db-database-migrations  # or wherever migrations are located
npm install
npm run create   # Create database
npm run migrate  # Run migrations
```

**Note**: If there's no separate migrations directory, migrations may run automatically in the App API service.

## Git Submodules Management

This repository uses Git submodules to manage independent service repositories. Here are the essential commands:

### Initialize Submodules (First Time)

```bash
# Clone all submodules
git submodule update --init --remote

# Or clone repository with submodules in one command
git clone --recurse-submodules <repository-url>
```

### Checkout Base Branches (Recommended)

After initializing submodules, use this script to automatically checkout all base branches:

```bash
# Checkout all base branches for main repo and submodules
./checkout-base-branches.sh
```

This script will:
- Checkout `main` in the root repository
- Checkout `siemens-develop` in sih-atellica-qlik-service
- Checkout `siemens-develop` in sih-atellica-qplus-backend (includes migrations)
- Checkout `main` in sih-atellica-qplus-frontend
- Fetch and pull latest changes from remote
- Display status for each repository

**Use this script** whenever you want to ensure you're on the correct base branches for development.

### Update Submodules to Latest

```bash
# Update all submodules to latest commit on their remote branches
git submodule update --remote

# Update specific submodule
git submodule update --remote sih-atellica-qplus-backend
```

### Check Submodule Status

```bash
# See current commit for each submodule
git submodule status

# See which submodules have changes
git submodule foreach 'git status'
```

### Working Within a Submodule

```bash
# Navigate into submodule
cd sih-atellica-qplus-backend

# Work normally with git
git checkout main
git pull
git checkout -b feature/my-feature

# Make changes, commit, push
git add .
git commit -m "My changes"
git push origin feature/my-feature
```

### Committing Submodule Changes in Main Repo

When you update a submodule to a new commit, you need to commit that change in the main repository:

```bash
# After updating submodule
cd db-siemens-dev
git add sih-atellica-qplus-backend
git commit -m "Update app API to latest version"
git push
```

### Adding a New Submodule

```bash
git submodule add <repository-url> <path>
git commit -m "Add new submodule"
```

### Removing a Submodule

```bash
# Deinitialize the submodule
git submodule deinit <path_to_submodule>

# Remove from git
git rm <path_to_submodule>

# Commit the change
git commit -m "Removed submodule <name>"

# Clean up .git/modules
rm -rf .git/modules/<path_to_submodule>
```

### Helpful Submodule Commands

```bash
# Run a command in all submodules
git submodule foreach 'git pull'
git submodule foreach 'git checkout main'

# See diff for submodules
git diff --submodule

# Clone repo and checkout specific submodule commits
git clone <repository-url>
git submodule update --init
```

## Starting Services

### Start All Services (Recommended)

```bash
# Start all services in foreground (see logs)
docker-compose up

# Start all services in background (detached mode)
docker-compose up -d

# Start with rebuild (if you changed Dockerfiles)
docker-compose up --build
```

### Start Individual Services

```bash
# Start only specific services
docker-compose up sih-atellica-qplus-backend
docker-compose up sih-atellica-qlik-service
docker-compose up db

# Start multiple specific services
docker-compose up db sih-atellica-qplus-backend
```

### Stop Services

```bash
# Stop all services (preserves data)
docker-compose down

# Stop and remove volumes (DELETES DATABASE DATA!)
docker-compose down -v

# Stop specific service
docker-compose stop sih-atellica-qplus-backend
```

### Restart Services

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart sih-atellica-qplus-backend
```

### View Logs

```bash
# View all service logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f sih-atellica-qplus-backend

# View last 100 lines
docker-compose logs --tail=100 sih-atellica-qplus-backend
```

### Check Service Status

```bash
# See running containers
docker-compose ps

# See detailed container info
docker ps
```

### Starting Frontend (Development Mode)

The frontend can run outside Docker for faster development:

```bash
cd sih-atellica-qplus-frontend
npm install
npm start
```

Frontend will be available at `http://localhost:7005` (or configured port).

## Environment Configuration

### Service-Specific Configuration

This project does NOT use a root-level `.env` file. Each service manages its own environment configuration:

- **sih-atellica-qplus-backend/.env** - Backend API configuration
- **sih-atellica-qlik-service/.env** - Qlik wrapper service configuration
- **sih-atellica-qplus-frontend/.env** - Frontend configuration

### Copy Environment Templates

```bash
# App API
cd sih-atellica-qplus-backend
cp .env.example .env

# Qlik Service
cd ../sih-atellica-qlik-service
cp .env.example .env

# Frontend (if needed)
cd ../sih-atellica-qplus-frontend
cp .env.example .env

# Return to root
cd ..
```

### Essential Environment Variables

Each service's `.env.example` file contains all available options with sensible defaults (commented out). Below are the critical settings you'll need to configure:

#### App API Configuration (sih-atellica-qplus-backend/.env)

Edit `sih-atellica-qplus-backend/.env` and configure these critical settings:

**Database Configuration**:
```bash
# Usually defaults are fine for Docker Compose
# DB_HOST=localhost
# DB_PORT=5432
# DB_USER=root
# DB_PASS=root
# DB_DATABASE=databridge_dev
```

**Qlik Service Integration**:
```bash
# Point to Qlik Service container
# QLIK_SERVICE_HOST=http://sih-atellica-qlik-service
# QLIK_SERVICE_PORT=8080
```

**API Key** (for service-to-service authentication):
```bash
API_KEY=your-secure-api-key-here
```

**Tenant Configuration**:
```bash
# TENANT_FILE_NAME=tenants_develop.json
# TENANT_FILE_PATH=src/
```

#### Qlik Service Configuration (sih-atellica-qlik-service/.env)

Edit `sih-atellica-qlik-service/.env` and configure these critical settings:

**Qlik Sense Enterprise Connection**:
```bash
# QS_REPOSITORY_USER_ID=sa_repository
# QS_REPOSITORY_USER_DIRECTORY=INTERNAL
# QS_ENGINE_USER_ID=sa_api
# QS_ENGINE_USER_DIRECTORY=INTERNAL
```

**Certificate Paths** (for QES authentication):
```bash
# QS_CERT_TYPE=ca  # ca | pfx
# QS_CA_PATH=../../certificates/qlik/root.pem
# QS_KEY_PATH=../../certificates/qlik/client_key.pem
# QS_CERT_PATH=../../certificates/qlik/client.pem
```

#### Frontend Configuration (sih-atellica-qplus-frontend/.env)

Frontend environment variables are typically injected at build time. See `sih-atellica-qplus-frontend/.env.example` for details.

### Configuration Notes

- All variables in `.env.example` files are **commented out with default values**
- **Uncomment and modify** only the variables you need to change
- Most defaults work for local Docker Compose development
- For production, you'll need to configure Qlik server URLs, certificates, and API keys

For complete environment variable reference, see each service's `.env.example` file:
- `sih-atellica-qplus-backend/.env.example`
- `sih-atellica-qlik-service/.env.example`
- `sih-atellica-qplus-frontend/.env.example`

## Development Workflow

### Daily Development

1. **Pull latest changes**:
   ```bash
   git pull
   git submodule update --remote
   ```

2. **Start services**:
   ```bash
   docker-compose up
   ```

3. **Start frontend** (separate terminal):
   ```bash
   cd sih-atellica-qplus-frontend
   npm start
   ```

4. **Make changes** in your preferred editor

5. **Hot reload** is enabled:
   - Frontend: Changes reflect immediately
   - Backend: TypeScript recompiles and Node.js restarts automatically

### Installing New Packages

#### In Docker Container

```bash
# SSH into the container
docker-compose exec sih-atellica-qplus-backend sh

# Install package
npm install package-name

# Exit container
exit

# Or restart to trigger npm install
docker-compose restart sih-atellica-qplus-backend
```

#### For Frontend (Local Development)

```bash
cd sih-atellica-qplus-frontend
npm install package-name
```

### Running Tests

```bash
# App API tests
cd sih-atellica-qplus-backend
npm test

# Frontend tests
cd sih-atellica-qplus-frontend
npm test
```

## Database Setup

### Initial Database Creation

If migrations are in a separate directory:

```bash
cd db-database-migrations
npm install
npm run create    # Creates the database
npm run migrate   # Runs all migrations
```

### Connect to Database

#### Using psql (Command Line)

```bash
# From host machine
psql -h localhost -p 5432 -U root -d pgdb
# Password: root

# From Docker
docker-compose exec db psql -U root -d pgdb
```

#### Using Database Client (GUI)

Connection details:
- **Host**: localhost
- **Port**: 5432
- **Database**: pgdb
- **Username**: root
- **Password**: root

### Database Operations

```bash
# Backup database
docker-compose exec db pg_dump -U root pgdb > backup_$(date +%Y%m%d).sql

# Restore database
docker-compose exec -T db psql -U root pgdb < backup_20231201.sql

# View database logs
docker-compose logs db
```

### Creating New Migrations

```bash
cd sih-atellica-qplus-backend
npm run migration:make -- migration_name
```

This creates a new migration file in `src/database/migrations/`.

## Service Descriptions

### sih-atellica-qplus-backend (Port 3002)

**Backend API Service** - Handles all application business logic and data operations.

**Responsibilities**:
- CRUD operations for bookmarks, comments, users, datasets, reports
- User authentication and authorization
- Database interactions
- Integration with Qlik Service for administrative Qlik operations
- Real-time updates via Socket.IO

**Swagger Documentation**: http://localhost:3002/documentation

### sih-atellica-qlik-service (Port 3001)

**Qlik Wrapper Service** - Provides abstraction layer for Qlik Enterprise operations.

**Responsibilities**:
- User authentication and synchronization with Qlik
- Integration lifecycle management (onboard/offboard)
- App file attachment operations
- Reload task execution and monitoring
- License management
- Session validation

**Consumed by**: App API (backend only, NOT frontend)

**Swagger Documentation**: http://localhost:3001/documentation

### sih-atellica-qplus-frontend (Port 7005)

**Frontend Application** - React-based user interface with embedded Qlik analytics.

**Responsibilities**:
- User interface for Compliance, Audit, and Reporting dashboards
- Direct integration with Qlik Enterprise via Capability API (QPlus library)
- Application data management via App API calls
- Real-time analytics visualization

**Access**: http://localhost:7005 (development)

### PostgreSQL Database (Port 5432)

**Database Service** - Stores all application data.

**Contents**:
- User accounts and authentication
- Bookmarks and comments
- Tenant configurations
- Application settings
- Audit logs

## Accessing Services

Once all services are running:

| Service | URL | Description |
|---------|-----|-------------|
| Frontend | http://localhost:7005 | Main application UI |
| App API | http://localhost:3002 | Backend API |
| App API Docs | http://localhost:3002/documentation | Swagger documentation |
| Qlik Service | http://localhost:3001 | Qlik wrapper service |
| Qlik Service Docs | http://localhost:3001/documentation | Swagger documentation |
| PostgreSQL | localhost:5432 | Database (use psql or GUI client) |

## Common Tasks

### Reset Everything (Clean Start)

```bash
# Stop and remove all containers, networks, volumes
docker-compose down -v

# Remove node_modules volumes
docker volume rm db-siemens-dev_db-insight-app-api-node_modules
docker volume rm db-siemens-dev_sih-atellica-qlik-service-node_modules

# Restart fresh
docker-compose up --build
```

### Clear Database

```bash
# Stop services
docker-compose down -v

# Restart (database will be empty)
docker-compose up

# Run migrations again
cd db-database-migrations
npm run create
npm run migrate
```

### Update All Services

```bash
# Pull latest code
git pull

# Update submodules
git submodule update --remote

# Rebuild and restart
docker-compose down
docker-compose up --build
```

### SSH into Container

```bash
# App API
docker-compose exec sih-atellica-qplus-backend sh

# Qlik Service
docker-compose exec sih-atellica-qlik-service sh

# Database
docker-compose exec db sh
```

### View Container Resource Usage

```bash
docker stats
```

### Clean Docker System

```bash
# Remove unused containers, networks, images
docker system prune

# Remove everything (including volumes)
docker system prune -a --volumes
```

## Troubleshooting

### Services Won't Start

**Problem**: Port already in use
```bash
# Find what's using the port
lsof -i :3002  # Mac/Linux
netstat -ano | findstr :3002  # Windows

# Kill the process or change port in docker-compose.yml
```

**Problem**: Drive not shared with Docker
- Windows/Mac: Docker Desktop → Settings → Resources → File Sharing
- Add the drive containing this project

### Database Connection Issues

**Problem**: Cannot connect to database
```bash
# Check if database container is running
docker-compose ps

# Check database logs
docker-compose logs db

# Verify credentials in .env match docker-compose.yml
```

### Submodule Issues

**Problem**: Submodule appears empty
```bash
git submodule update --init --remote
```

**Problem**: Submodule on wrong commit
```bash
cd <submodule-directory>
git checkout main
git pull
cd ..
git add <submodule-directory>
git commit -m "Update submodule"
```

### Node Modules Issues

**Problem**: Module not found errors
```bash
# Rebuild node_modules
docker-compose down
docker volume rm db-siemens-dev_db-insight-app-api-node_modules
docker-compose up --build
```

### Hot Reload Not Working

**Problem**: Changes not reflecting in backend
```bash
# Restart the service
docker-compose restart sih-atellica-qplus-backend

# Check logs for TypeScript compilation errors
docker-compose logs -f sih-atellica-qplus-backend
```

### Qlik Connection Issues

**Problem**: Cannot connect to Qlik Enterprise
- Verify VPN connection (if required)
- Check Qlik server URL in `.env`
- Verify certificates are placed in `sih-atellica-qlik-service/src/certificates/`
- Check virtual proxy configuration

### Frontend Issues

**Problem**: Frontend won't start
```bash
cd sih-atellica-qplus-frontend
rm -rf node_modules
npm install
npm start
```

**Problem**: Qlik visualizations not loading
- Check `startup.json` configuration
- Verify Qlik app IDs are correct
- Check browser console for errors
- Verify Qlik Enterprise Server is accessible

## Documentation

For detailed documentation, see the [docs/](./docs/) directory:

- **[docs/README.md](./docs/README.md)** - Documentation guide and navigation
- **[docs/PROJECT_OVERVIEW.md](./docs/PROJECT_OVERVIEW.md)** - Comprehensive project overview
- **[docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)** - Technical architecture deep dive
- **[docs/DEVELOPMENT_GUIDE.md](./docs/DEVELOPMENT_GUIDE.md)** - Detailed development instructions

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Git Submodules Tutorial](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- [Qlik Sense Developer](https://help.qlik.com/en-US/sense-developer/)
- [Hapi.js Documentation](https://hapi.dev/)
- [React Documentation](https://react.dev/)

## Support

For questions or issues:

1. Check the [Troubleshooting](#troubleshooting) section above
2. Review [docs/DEVELOPMENT_GUIDE.md](./docs/DEVELOPMENT_GUIDE.md)
3. Check individual service README files in their respective directories
4. Contact the development team

---

**Project**: SIH Atellica Connect Analytics Component
**Version**: 1.0.0
**Maintained by**: Databridge Development Team
**Last Updated**: December 2025
