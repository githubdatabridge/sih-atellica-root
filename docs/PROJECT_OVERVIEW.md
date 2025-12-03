# SIH Atellica Connect Analytics Component - Project Overview

## Executive Summary

The SIH (Siemens Healthineers) Atellica Connect Analytics Component is a comprehensive analytics platform designed to provide insights into compliance, audit, and reporting for Siemens Healthineers operations. Built on a modern microservices architecture, the platform integrates seamlessly with Qlik Sense analytics to deliver interactive, data-driven visualizations and reports.

## Project Purpose

This project serves as an analytics solution that enables:

- **Compliance Monitoring**: Track and analyze compliance metrics across Siemens Healthineers systems
- **Audit Management**: Provide comprehensive audit trail and reporting capabilities
- **Reporting & Analytics**: Generate interactive reports and dashboards using Qlik Sense integration
- **Data Bridge Integration**: Acts as a middleware between Siemens systems and Qlik analytics platform

## Architecture Overview

The project follows a microservices architecture pattern with three primary components orchestrated via Docker Compose:

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
│             │                │  - QRS/QPS/QIX APIs │            │
│             │                └──────────▲──────────┘            │
│             │                           │                        │
│             │                           │ (QRS/QPS/QIX)          │
│             │                           │                        │
│             ▼                           │                        │
│  ┌──────────────────────┐              │                        │
│  │   App API (Hapi.js)  │              │                        │
│  │   (Business Logic)   │──────────────┘                        │
│  └──────────┬───────────┘  (REST/HTTP)                          │
│             │                    │                               │
│             ▼                    ▼                               │
│  ┌──────────────────┐   ┌────────────────────┐                 │
│  │  PostgreSQL DB   │   │   Qlik Service     │                 │
│  │                  │   │   (QES Wrapper)    │                 │
│  └──────────────────┘   └────────────────────┘                 │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Frontend Application (sih-atellica-qplus-frontend)

**Technology Stack**:
- React 18.2.0
- TypeScript 4.5.5
- Material-UI 5.11.8
- Databridge QPlus 2.1.0-beta.31 (Qlik Integration Library)
- Express.js (for serving the built application)

**Key Features**:
- Modern React-based single-page application
- Qlik Sense mashup integration for embedded analytics
- Siemens light theme implementation
- Responsive design for various screen sizes
- Configuration-driven page setup via `startup.json`

**Functionality**:
- Provides three main analytical views:
  - **Compliance Dashboard**: Real-time compliance metrics and KPIs
  - **Audit Module**: Comprehensive audit trail and investigation tools
  - **Reporting Interface**: Customizable reports and data exports
- **Direct Qlik Connection**: Uses Capability API via QPlus library to connect directly to Qlik Enterprise Server
- **Dual Communication Pattern**:
  - REST/HTTP calls to App API for CRUD operations (bookmarks, comments, user data)
  - WebSocket connection to Qlik Enterprise Server via Capability API for analytics and visualizations
- Dynamic Qlik app loading based on configuration
- Authentication integration with Qlik Sense (QES mode)
- Virtual proxy support for secure connections
- Real-time analytics updates through Qlik Capability API

**Port**: Runs on port 7005 (development)

### 2. Application API (sih-atellica-qplus-backend)

**Technology Stack**:
- Node.js (v16.5.0 - v21.0.0)
- TypeScript 5.3.3
- Hapi.js 21.3.0 (HTTP Server Framework)
- Knex.js 3.1.0 (SQL Query Builder)
- PostgreSQL 8.7.1
- Socket.IO 4.7.4 (Real-time communication)
- Winston 3.3.3 (Logging)
- JWT Authentication (@hapi/jwt)

**Key Features**:
- RESTful API architecture
- Dependency injection using TSyringe
- Auto-generated Swagger documentation
- Database migrations with Knex
- Pagination support (knex-paginate)
- Real-time updates via WebSockets
- Comprehensive logging with daily rotation
- OpenID Connect authentication support

**Functionality**:
- CRUD operations for all application entities (bookmarks, comments, users, datasets, reports)
- User management and authentication
- Bookmark management
- Comment system
- Tenant-based data isolation
- **Qlik Service Integration**: Consumes Qlik Service for operational tasks on Qlik side:
  - User authentication and synchronization with Qlik
  - Integration onboarding/offboarding
  - App attachment management
  - Task management (start/status monitoring)
  - User license deallocation
  - Session validation
  - User and app filtering
- API key-based service authentication
- Health check endpoints

**Architecture Patterns**:
- Controller-Service-Repository pattern
- DTO (Data Transfer Objects) for request/response handling
- Entity-based data modeling
- Transformer layer for data formatting
- Validators for input sanitization

**Port**: 3002 (mapped to 8080 internal)

### 3. Qlik Service (sih-atellica-qlik-service)

**Technology Stack**:
- Node.js (v16.5.0 - v21.0.0)
- TypeScript 5.3.3
- Hapi.js 21.3.0
- Enigma.js 2.7.0 (Qlik Engine API)
- qrs-interact 6.1.0 (Qlik Repository Service)
- WebSocket (ws 8.18.0)
- Winston 3.3.3 (Logging)

**Key Features**:
- Qlik Sense Enterprise integration
- Certificate-based authentication
- Session management
- App metadata retrieval
- Object and dimension management
- Real-time Qlik Engine communication

**Functionality**:
- **Backend Wrapper Service**: Provides abstraction layer for Qlik operational tasks (consumed by App API, NOT frontend)
- Qlik Repository Service (QRS) API interactions for administrative operations
- Qlik Engine Session (QIX) connections for data operations
- User authentication and session management in Qlik
- Integration lifecycle management (onboard/offboard)
- App attachment operations (upload/remove files to Qlik apps)
- Task execution and monitoring
- User management (license allocation, user removal, property sync)
- App filtering and metadata retrieval
- Virtual proxy routing
- Secure certificate management for QES communication
- Health monitoring

**Authentication**:
- Supports Qlik repository user authentication
- Engine API user authentication
- Virtual proxy-based routing

**Port**: 3001 (mapped to 8080 internal)

### 4. PostgreSQL Database

**Configuration**:
- PostgreSQL 12.8
- Default database: `pgdb`
- Credentials: root/root (development)
- Port: 5432
- Persistent storage via Docker volumes

**Purpose**:
- Stores application data, user information, bookmarks, comments
- Manages tenant configurations
- Audit trail storage
- Session management

## Technology Stack Summary

### Backend
- **Runtime**: Node.js 16.5.0+
- **Language**: TypeScript 5.x
- **Web Framework**: Hapi.js 21.x
- **Database**: PostgreSQL 12.8
- **ORM/Query Builder**: Knex.js 3.x
- **Real-time**: Socket.IO 4.7.4, WebSockets
- **Authentication**: JWT, OpenID Connect, Qlik Certificates

### Frontend
- **Framework**: React 18.2.0
- **Language**: TypeScript 4.5.5
- **UI Library**: Material-UI 5.11.8
- **Routing**: React Router DOM 6.8.1
- **State Management**: React Hooks
- **Analytics Integration**: Databridge QPlus

### Infrastructure
- **Containerization**: Docker, Docker Compose 3.3
- **Version Control**: Git with submodules
- **Development**: Hot-reload via tsc-watch

## Key Features & Capabilities

### 1. Analytics & Reporting
- Embedded Qlik Sense dashboards
- Interactive data visualizations
- Multi-page analytics (Compliance, Audit, Reporting)
- Real-time data refresh
- Custom theme support (Siemens branding)

### 2. Data Management
- RESTful API for data operations
- Tenant-based data isolation
- Database migrations for schema management
- Pagination for large datasets
- Full-text search capabilities

### 3. User Management
- Authentication and authorization
- Session management
- Multi-tenant support
- Role-based access control (implied by tenant structure)

### 4. Integration Capabilities
- Qlik Sense Enterprise integration
- Virtual proxy support
- Certificate-based authentication
- API key authentication for service-to-service communication
- WebSocket support for real-time updates

### 5. Development Features
- Auto-generated API documentation (Swagger)
- Dependency injection for better testability
- Comprehensive logging
- Environment-based configuration
- Hot-reload in development mode
- Jest testing framework

## Deployment Architecture

### Development Environment
- Uses Docker Compose for local orchestration
- Hot-reload enabled for all services
- Local PostgreSQL instance
- Development-specific logging

### Service Communication
```
Frontend (7005) ──► App API (3002) ──► Database (5432)
      │                  │
      │                  ▼
      │             Qlik Service (3001) ──► Qlik Sense Enterprise (QRS/QPS/QIX)
      │                                           ▲
      └───────────────────────────────────────────┘
              (Capability API - WebSocket)
```

**Communication Breakdown**:
- **Frontend → App API**: REST/HTTP for CRUD operations (bookmarks, comments, datasets, reports)
- **Frontend → Qlik Enterprise**: Direct WebSocket connection via Capability API for analytics visualizations
- **App API → Qlik Service**: REST/HTTP for Qlik operational tasks (user auth, integration management, task execution)
- **Qlik Service → Qlik Enterprise**: Certificate-based QRS/QPS/QIX API calls for administrative operations

### Configuration Management
- Environment variables via `.env` files
- Service-specific configuration
- Tenant configuration files (`tenants_develop.json`, `tenants_staging.json`)
- Frontend startup configuration (`startup.json`)

## Data Flow

1. **User Access & Initialization**:
   - User accesses frontend application
   - Application loads configuration from `startup.json` (virtual proxy, Qlik app IDs, default page)
   - QPlus library initializes with Capability API mode (QES) and virtual proxy settings
   - User authenticates via Qlik Sense Enterprise

2. **Analytics Interaction** (Frontend → Qlik Direct):
   - Frontend establishes WebSocket connection to Qlik Enterprise Server via Capability API
   - QPlus library loads Qlik apps dynamically based on configuration
   - User interacts with embedded Qlik visualizations (Compliance/Audit/Reporting dashboards)
   - Real-time analytics updates received through Capability API WebSocket connection
   - No intermediate service between frontend and Qlik for visualization rendering

3. **Application Data Operations** (Frontend → App API):
   - Frontend makes REST API calls to App API for CRUD operations:
     - Bookmarks management
     - Comments system
     - User preferences
     - Reports and datasets
   - App API validates requests, processes business logic
   - Data persisted/retrieved from PostgreSQL
   - Real-time updates pushed to frontend via Socket.IO when needed

4. **Qlik Administrative Operations** (App API → Qlik Service):
   - App API delegates Qlik operational tasks to Qlik Service:
     - User authentication and synchronization with Qlik
     - Integration lifecycle (onboard/offboard customers/tenants)
     - App file attachments (upload data files to Qlik apps)
     - Reload task execution and status monitoring
     - User license management (allocation/deallocation)
     - Session validation
   - Qlik Service communicates with Qlik Enterprise using:
     - QRS API (Qlik Repository Service) for administrative operations
     - QPS API (Qlik Proxy Service) for session management
     - QIX API (Qlik Engine) for data operations
   - Certificate-based authentication used for Qlik Service → Qlik Enterprise communication
   - API key authentication used for App API → Qlik Service communication

## Security Considerations

- Certificate-based authentication for Qlik integration
- JWT tokens for user authentication
- API key authentication for inter-service communication
- Environment-based secrets management
- PostgreSQL SSL support
- Session management with secure cookies
- OpenID Connect support for enterprise SSO

## Monitoring & Logging

- Winston logger with daily rotation
- Separate log files for core operations
- Configurable log levels (info, error, debug)
- Log file size and retention management
- Health check endpoints for all services

## DevOps & Deployment

### Version Control
- Git repository with submodules for each service
- Each component maintained in separate repository
- Main repository orchestrates all components

### Development Workflow
1. Clone repository and initialize submodules
2. Copy `.env.example` to `.env` and configure
3. Run `docker-compose up` to start all services
4. Access frontend at localhost:7005
5. API documentation available at service ports/documentation

### Service Management
- Windows service installation scripts included
- Docker-based deployment for cross-platform support
- Independent scaling of services possible

## Project Dependencies

### Build Tools
- NPM 9.0.0+
- TypeScript Compiler
- Docker & Docker Compose 20.10.8+
- Git 2.17.1+

### Third-Party Services
- Qlik Sense Enterprise Server
- SMTP server (for notification service integration)

## Configuration Files

- `.env` - Environment variables for all services
- `docker-compose.yml` - Service orchestration
- `startup.json` - Frontend application configuration
- `tenants_*.json` - Tenant-specific configurations
- `package.json` - Node.js dependencies per service

## API Documentation

Each service provides auto-generated Swagger documentation:
- App API: `http://localhost:3002/documentation`
- Qlik Service: `http://localhost:3001/documentation`

## Future Considerations

Based on the codebase structure, the platform is designed to support:
- Additional analytics modules
- Extended tenant management
- Notification service integration (infrastructure present)
- Gateway service for unified API access
- Horizontal scaling of services
- Additional authentication providers

## Getting Started

For detailed setup instructions, refer to the main [README.md](../README.md) file.

Quick start:
```bash
# Initialize submodules
git submodule update --init --remote

# Configure environment
cp .env.example .env

# Start all services
docker-compose up

# Run migrations (in separate terminal)
cd db-database-migrations
npm install
npm run create
npm run migrate
```

## Support & Maintenance

This project is maintained for Siemens Healthineers analytics operations. For technical support or questions, refer to the individual service README files or contact the development team.

---

**Last Updated**: December 2025
**Version**: 1.0.0
**Project Type**: Microservices Analytics Platform
**Primary Use Case**: Healthcare Analytics for Siemens Healthineers
