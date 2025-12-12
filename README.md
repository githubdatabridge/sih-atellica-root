# SIH Atellica Connect Analytics Component

Siemens Healthineers development repository for the Atellica Connect Analytics Component - a comprehensive analytics platform providing compliance monitoring, audit management, and reporting capabilities through Qlik Sense integration.

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [Additional Resources](#additional-resources)
- [Support](#support)



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
git clone https://github.com/githubdatabridge/sih-atellica-root.git --recursive
cd sih-atellica-root
```

### 2. Initialize Submodules

This will clone all three service repositories:
- `sih-atellica-qplus-backend` - Backend API
- `sih-atellica-qlik-service` - Qlik wrapper service
- `sih-atellica-qplus-frontend` - React frontend

### 3. Checkout Base Branches

<!-- WTF is this? :D -->
```bash
./checkout-base-branches.sh
```
<!-- It is better to make developer learn about submodule and not make a magic sh scripts :) -->
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

>Edit each service's `.env` file with your specific configuration (see [Environment Configuration](#environment-configuration) section).

### 5. Provide Qlik and Server Certificates
Place the required Qlik and server certificates in a `certificates/` directory at the root of the project:

```
sih-atellica-root/
 ├── certificates/
    ├── qlik/
    │    ├── client.pfx
    │    ├── root.pem
    │    └── ...
    └── server/
          ├── server.crt
          ├── server.key
          └── ...
```
> **Note**: Contact your team lead for the required Qlik and server certificates.

> **Note**: Ensure the paths in the `.env` files point to these certificate locations.

Wait for all services to start (this may take a few minutes on first run).

### 6. Run Database Migrations

Migrations are created under the sih-atellica-qplus-backend repository.
By running the backend service, migrations should run automatically.
```
sih-atellica-qplus-backend/
 ├── src/
 │    ├── database/
 │    │    ├── migrations/
 │    │    │    ├── 20200511074854-create-actions
 │    │    │    ├── ....ts
 │    │    │    └── ...
 │    │    └── knexfile.ts
 │    └── ...
 └── package.json
```
If you need to run them manually, follow these steps:

```bash
npm run migration:latest
```
>**Note**: All other migration commands are available in the `package.json` scripts section. And also on knex documentation: https://knexjs.org/guide/migrations.html

### 7. Start Development (using Docker Compose)

> **Note**: Before starting, ensure all environment variables are configured, certificates are in place.

Start all services using Docker Compose:

```bash
docker-compose up
```

This will start the PostgreSQL database, backend API, Qlik service, except the frontend.

The frontend can be started separately for hot-reloading during development:

```bash
cd sih-atellica-qplus-frontend
yarn install
yarn start
```

### 8. Start Development manually (optional)

> **Note**: Before starting, ensure all environment variables are configured, certificates are in place and postgreSQL database is running.

> **Note**: You should use Docker Compose to start postgreSQL server `docker-compose up db`.

#### Starting Services (`sih-atellica-qplus-backend`, `sih-atellica-qlik-service`)
for each service, open a terminal and run:

```bash
cd sih-atellica-qplus-backend
npm install
npm run start
```

```bash
cd sih-atellica-qlik-service
npm install
npm run start
```

#### Starting Frontend (sih-atellica-qplus-frontend)
```bash
cd sih-atellica-qplus-frontend
yarn install
yarn start
```

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
