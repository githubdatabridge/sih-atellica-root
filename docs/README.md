# SIH Atellica Connect Analytics Component - Documentation

Welcome to the comprehensive documentation for the SIH (Siemens Healthineers) Atellica Connect Analytics Component.

## Documentation Structure

### [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md)
Comprehensive overview of the entire project including:
- Executive summary and project purpose
- Architecture overview with diagrams
- Detailed component descriptions
  - Frontend Application (React + QPlus)
  - Application API (Hapi.js backend)
  - Qlik Service (QES wrapper)
  - PostgreSQL Database
- Technology stack summary
- Key features and capabilities
- Service communication patterns
- Data flow explanations
- Security considerations
- Deployment architecture

**Start here** if you want to understand what the project does and how all the pieces fit together.

### [ARCHITECTURE.md](./ARCHITECTURE.md)
Deep dive into the technical architecture:
- Architectural patterns (Microservices, Layered Architecture)
- Detailed layer descriptions (Controllers, Services, Repositories, Entities)
- Communication patterns
  - REST/HTTP APIs
  - WebSocket connections
  - Qlik Capability API integration
- Data flow patterns with detailed diagrams
- Dependency injection patterns
- Database architecture and migrations
- Security architecture
- Scalability considerations
- Error handling and logging strategies
- Integration architecture with Qlik Sense Enterprise

**Read this** if you need to understand the technical implementation details and design decisions.

### [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md)
Practical guide for developers:
- Prerequisites and setup instructions
- Environment configuration
- Running the application (Docker Compose, local development)
- Database migrations
- Frontend development
- Backend development (App API and Qlik Service)
- Creating new API endpoints (step-by-step)
- Testing strategies
- Debugging tips
- Code style and best practices
- Git workflow with submodules
- Troubleshooting common issues
- Performance optimization tips

**Use this** when you're actually working on the code and need practical how-to instructions.

### [CONFIGURATION_GUIDE.md](./CONFIGURATION_GUIDE.md)
Complete configuration reference:
- Service-level environment variables (.env files)
  - App API configuration (database, Qlik Service, authentication)
  - Qlik Service configuration (certificates, Qlik Enterprise connection)
  - Frontend configuration (API endpoints, feature flags)
- Tenant configuration structure (configuration_develop.json, configuration_staging.json)
  - Multi-tenant setup with customers and apps
  - Qlik app mapping and virtual proxy configuration
- Frontend startup configuration (startup.json)
- Configuration scenarios and examples
- Environment-specific setup (development, staging, production)

**Refer to this** when setting up environments, configuring services, or managing multi-tenant deployments.

### [QLIK_SETUP.md](./QLIK_SETUP.md)
Qlik Sense Enterprise integration guide:
- Certificate export from Qlik Management Console (QMC)
  - PEM format export (recommended)
  - PFX format export and conversion
- Certificate installation in Qlik Service
- Qlik Management Console (QMC) configuration
  - Virtual proxy setup and configuration
  - Authentication methods (header, ticket, anonymous)
  - Service account creation and permissions
- Connection testing procedures
  - Backend Qlik Service connectivity
  - Frontend Capability API connectivity
- Troubleshooting Qlik integration issues

**Follow this** when setting up Qlik integration, managing certificates, or troubleshooting Qlik connectivity.

### [DATABASE.md](./DATABASE.md)
Database architecture and operations:
- PostgreSQL 12.8 setup and configuration
- Knex.js migration workflow
  - Creating new migrations
  - Running migrations (up/down)
  - Rollback procedures
- Complete schema reference for all tables
  - Core tables (actions, comments, reactions, pinwalls)
  - Analytics tables (datasets, reports, visualizations)
  - Qlik integration tables (qlik_states, qlik_temp_content)
  - Support tables (tags, links, files)
- Data relationships and foreign keys
- Soft delete pattern implementation
- Backup and restore procedures
- Performance optimization and indexing

**Consult this** when working with database schema, migrations, or data operations.

## Quick Start

If you're new to the project, follow this path:

1. **Understand the Project** - Read [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md)
2. **Set Up Development Environment** - Follow [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md)
3. **Configure Services** - Use [CONFIGURATION_GUIDE.md](./CONFIGURATION_GUIDE.md) to set up .env files and tenant configuration
4. **Set Up Qlik Integration** - Follow [QLIK_SETUP.md](./QLIK_SETUP.md) for certificate export and Qlik Enterprise configuration
5. **Understand Database Schema** - Review [DATABASE.md](./DATABASE.md) for migrations and table structures
6. **Deep Dive into Architecture** - Study [ARCHITECTURE.md](./ARCHITECTURE.md) when you need implementation details

## Key Architecture Highlights

### Dual Communication Pattern

The frontend uses **two separate communication channels**:

1. **Frontend → Qlik Enterprise Server (Direct)**
   - WebSocket connection via Qlik Capability API
   - QPlus library (`@databridge/qplus`) wraps Capability API
   - Real-time analytics visualizations (Compliance, Audit, Reporting)
   - No intermediate service - browser connects directly to Qlik

2. **Frontend → App API (REST/HTTP)**
   - CRUD operations for application data
   - Bookmarks, comments, user preferences, datasets, reports
   - Socket.IO for real-time application updates

### Backend Service Integration

**App API → Qlik Service** (HTTP/REST):
- Qlik Service is a wrapper for Qlik administrative operations
- Consumed by App API backend (NOT by frontend)
- Operations include:
  - User authentication and synchronization with Qlik
  - Integration lifecycle management (onboard/offboard)
  - App file attachment management
  - Task execution and monitoring
  - License management
  - Session validation

**Qlik Service → Qlik Enterprise** (Certificate-based):
- Uses QRS API (Repository Service) for admin operations
- Uses QPS API (Proxy Service) for session management
- Uses QIX API (Engine) for data operations
- X.509 certificate authentication

## Project Structure

```
db-siemens-dev/
├── docs/                          # Documentation (you are here)
│   ├── README.md                  # This file - documentation navigation
│   ├── PROJECT_OVERVIEW.md        # High-level project overview
│   ├── ARCHITECTURE.md            # Technical architecture details
│   ├── DEVELOPMENT_GUIDE.md       # Development instructions
│   ├── CONFIGURATION_GUIDE.md     # Configuration reference
│   ├── QLIK_SETUP.md              # Qlik integration setup
│   └── DATABASE.md                # Database schema and operations
├── sih-atellica-qplus-backend/            # Backend API (submodule)
├── sih-atellica-qlik-service/               # Qlik wrapper service (submodule)
├── sih-atellica-qplus-frontend/      # React frontend (submodule)
├── devops/                        # DevOps scripts and configurations
├── docker-compose.yml             # Service orchestration
└── README.md                      # Project README
```

## Technology Stack Summary

- **Frontend**: React 18.2, TypeScript 4.5, Material-UI 5.11, QPlus 2.1
- **Backend**: Node.js 16+, TypeScript 5.3, Hapi.js 21.3
- **Database**: PostgreSQL 12.8
- **Analytics**: Qlik Sense Enterprise (via Capability API)
- **Infrastructure**: Docker, Docker Compose

## Common Tasks

- **Start all services**: See [DEVELOPMENT_GUIDE.md - Running the Application](./DEVELOPMENT_GUIDE.md#running-the-application)
- **Configure environment variables**: See [CONFIGURATION_GUIDE.md](./CONFIGURATION_GUIDE.md)
- **Set up Qlik certificates**: See [QLIK_SETUP.md - Certificate Export](./QLIK_SETUP.md#certificate-export-from-qmc)
- **Create database migration**: See [DATABASE.md - Migration Workflow](./DATABASE.md#migration-workflow)
- **Create new API endpoint**: See [DEVELOPMENT_GUIDE.md - API Development](./DEVELOPMENT_GUIDE.md#api-development)
- **Configure multi-tenant setup**: See [CONFIGURATION_GUIDE.md - Tenant Configuration](./CONFIGURATION_GUIDE.md#tenant-configuration)
- **Understand Qlik integration**: See [ARCHITECTURE.md - Integration Architecture](./ARCHITECTURE.md#integration-architecture)
- **Debug issues**: See [DEVELOPMENT_GUIDE.md - Troubleshooting](./DEVELOPMENT_GUIDE.md#troubleshooting)

## Support

For questions or issues:
1. Check the [Troubleshooting section](./DEVELOPMENT_GUIDE.md#troubleshooting) in the Development Guide
2. Review individual service README files in their respective directories
3. Contact the development team

---

**Last Updated**: December 2025
**Version**: 1.0.0
**Maintained by**: Databridge Development Team
