# Configuration Guide

Complete guide to configuring the SIH Atellica Connect Analytics Component for development and production environments.

## Table of Contents

- [Overview](#overview)
- [Service Configuration Files](#service-configuration-files)
- [Tenant Configuration](#tenant-configuration)
- [Frontend Startup Configuration](#frontend-startup-configuration)
- [Environment Variables Reference](#environment-variables-reference)
- [Configuration Best Practices](#configuration-best-practices)
- [Common Configuration Scenarios](#common-configuration-scenarios)

## Overview

The SIH Analytics platform uses a **decentralized configuration approach**. Each service manages its own configuration through:

1. **`.env` files** - Environment-specific variables (service-level)
2. **Tenant configuration JSON** - Multi-tenant setup (App API)
3. **Startup configuration JSON** - Frontend initialization (Frontend)

```
Configuration Architecture:
├── sih-atellica-qplus-backend/
│   ├── .env                        # Service environment variables
│   └── src/
│       ├── configuration_develop.json    # Development tenant config
│       └── configuration_staging.json    # Staging tenant config
├── sih-atellica-qlik-service/
│   └── .env                        # Service environment variables
└── sih-atellica-qplus-frontend/
    ├── .env                        # Build-time environment variables
    └── src/app/json/
        └── startup.json            # Runtime initialization config
```

## Service Configuration Files

### App API Configuration (sih-atellica-qplus-backend/.env)

The App API is the most configuration-heavy service, connecting to both the database and Qlik Service.

#### Create Configuration File

```bash
cd sih-atellica-qplus-backend
cp .env.example .env
```

#### Essential Variables

**Database Connection**:
```bash
# DB_HOST=localhost           # Use 'db' for Docker, 'localhost' for local
# DB_PORT=5432
# DB_USER=root
# DB_PASS=root
# DB_DATABASE=databridge_dev
# DB_SSL=false
```

**Qlik Service Integration**:
```bash
# QLIK_SERVICE_HOST=http://sih-atellica-qlik-service    # Docker service name
# QLIK_SERVICE_PORT=8080
```

**API Authentication**:
```bash
API_KEY=your-secure-api-key-here    # IMPORTANT: Generate unique key!
```

**Tenant Configuration**:
```bash
# TENANT_FILE_PATH=src/
# TENANT_FILE_NAME=configuration_develop.json    # Or configuration_staging.json
# TENANT_FILE_ONLY=false                   # false = also load from DB
```

**Logging**:
```bash
# LOG_DIR=logs
# LOG_FILE_TYPE=file    # file | database | null (both)
# LOG_LEVEL=info        # info | debug | error | warn
# LOG_CORE_FILE=core.log
# LOG_DATE_PATTERN=YYYY-MM-DD
# LOG_MAX_SIZE=20m
# LOG_MAX_FILES=14d
```

**JWT Configuration** (for Qlik Cloud):
```bash
# JWT_AUDIENCE=qlik.api/login/jwt-session
# JWT_ISSUER=your-tenant.qlikcloud.com
# JWT_EXPIRES_IN=21600    # 6 hours in seconds
```

**Server Configuration**:
```bash
# HOST=0.0.0.0
# PORT=8080
# SSL=false
# TITLE=App Api
# VERSION=v1
```

**TLS/Certificate Settings**:
```bash
NODE_TLS_REJECT_UNAUTHORIZED=0    # Set to 1 in production!

# SERVER_CERT_PATH=./build/certificates/server
# SERVER_CERT_FILE_NAME='server.crt'
# SERVER_KEY_FILE_NAME='server.key'
```

### Qlik Service Configuration (sih-atellica-qlik-service/.env)

The Qlik Service requires certificate paths and Qlik Enterprise connection details.

#### Create Configuration File

```bash
cd sih-atellica-qlik-service
cp .env.example .env
```

#### Essential Variables

**Qlik Sense Enterprise Authentication**:
```bash
# QS_REPOSITORY_USER_ID=sa_repository
# QS_REPOSITORY_USER_DIRECTORY=INTERNAL
# QS_ENGINE_USER_ID=sa_api
# QS_ENGINE_USER_DIRECTORY=INTERNAL
```

**Certificate Configuration**:
```bash
# QS_CERT_TYPE=ca    # 'ca' for separate files, 'pfx' for single file

# For 'ca' type (recommended):
# QS_CA_PATH=./src/certificates/qlik/root.pem
# QS_KEY_PATH=./src/certificates/qlik/client_key.pem
# QS_CERT_PATH=./src/certificates/qlik/client.pem

# For 'pfx' type:
# QS_PFX_PATH=./src/certificates/qlik/client.pfx
# QS_PFX_PASS=certificate-password
```

**Server Configuration**:
```bash
# HOST=0.0.0.0
# PORT=8080
# TITLE=Qlik Service
# VERSION=v1
# SSL=false
```

**Gateway Configuration** (if using API gateway):
```bash
# GATEWAY_HOST=your-gateway-host.com
# GATEWAY_PATH=/qlik/
```

**TLS Settings**:
```bash
# NODE_TLS_REJECT_UNAUTHORIZED=1    # 1 for production
# QLIK_CERT_PASSPHRASE=              # If certificates are encrypted
```

### Frontend Configuration (sih-atellica-qplus-frontend/.env)

Frontend environment variables are injected at **build time**, not runtime.

#### Create Configuration File

```bash
cd sih-atellica-qplus-frontend
cp .env.example .env
```

#### Essential Variables

**Qlik Connection**:
```bash
REACT_APP_QLIK_HOST_NAME=qs-i-dev.databridge.ch
REACT_APP_QLIK_VP=localhost
REACT_APP_QLIK_QPS_ENDPOINT=https://qs-i-dev.databridge.ch
```

**Tenant & App Identification**:
```bash
REACT_APP_TENANT_ID=single_hardcoded_for_now
REACT_APP_CUSTOMER_ID=hardcoded_for_now
REACT_APP_MASHUP_APP_ID=insight_poc
```

**Backend API Endpoints**:
```bash
REACT_APP_INSIGHT_APP_API=https://localhost:3002
REACT_APP_INSIGHT_SOCKET_PATH=/socket.io
```

**Qlik Events**:
```bash
REACT_APP_QLIK_GLOBAL_EVENTS=closed,warning,error
REACT_APP_QLIK_APP_EVENTS=closed,warning,error
```

**Theme**:
```bash
REACT_APP_DEFAULT_THEME=db-theme-siemens-light
```

**Development Server**:
```bash
PORT=7005
HOST=localhost
HTTPS=true
SKIP_PREFLIGHT_CHECK=true
FAST_REFRESH=true
```

## Tenant Configuration

Tenant configuration defines the multi-tenant structure, mapping tenants → customers → apps → Qlik apps.

### File Location

```
sih-atellica-qplus-backend/src/
├── configuration_develop.json    # Development environment
└── configuration_staging.json    # Staging environment
```

### Tenant Structure

```json
[
  {
    "id": "tenant-unique-id",
    "name": "Tenant Display Name",
    "host": "qlik-server.domain.com",
    "port": 4242,
    "apiKey": {
      "id": "api-key-id",
      "exp": "MM/DD/YYYY",
      "value": "jwt-token-here"
    },
    "customers": [
      {
        "id": "customer-id",
        "name": "Customer Name",
        "spaceId": "qlik-space-id",
        "apps": [
          {
            "id": "mashup-app-id",
            "name": "Mashup App Name",
            "qlikApps": [
              {
                "id": "qlik-app-guid",
                "name": "Qlik App Name"
              }
            ],
            "callbackUrl": "https://localhost:7005/return"
          }
        ]
      }
    ],
    "authType": "windows",
    "idProvider": null
  }
]
```

### Tenant Configuration Fields

| Field | Description | Example |
|-------|-------------|---------|
| `id` | Unique tenant identifier | `"2GgxmrcJqlqFqh3G6qyOzW6azMMlKHJn"` |
| `name` | Tenant display name | `"Siemens Healthineers"` |
| `host` | Qlik Sense Enterprise server | `"qs-i-dev.databridge.ch"` |
| `port` | QRS port (usually 4242) | `4242` |
| `apiKey` | Qlik Cloud API key (for Cloud tenants) | See API key structure |
| `customers` | Array of customer configurations | See customer structure |
| `authType` | Authentication type | `"windows"`, `"cloud"`, `"header"` |
| `idProvider` | Identity provider (for OIDC) | `null` or IDP config |

### Customer Configuration Fields

| Field | Description | Example |
|-------|-------------|---------|
| `id` | Unique customer identifier | `"siemens-healthcare"` |
| `name` | Customer display name | `"Siemens Healthcare Division"` |
| `spaceId` | Qlik Cloud space ID (Cloud only) | `"60a77186e14619000152ad15"` |
| `apps` | Array of mashup app configurations | See app structure |

### App Configuration Fields

| Field | Description | Example |
|-------|-------------|---------|
| `id` | Mashup app identifier (matches frontend) | `"insight_poc"` |
| `name` | App display name | `"Insight POC App"` |
| `qlikApps` | Array of Qlik app GUIDs | See Qlik app structure |
| `callbackUrl` | Redirect URL after authentication | `"https://localhost:7005/return"` |

### Qlik App Fields

| Field | Description | Example |
|-------|-------------|---------|
| `id` | Qlik app GUID | `"4e2d4117-f850-496b-8eb4-df1ff570c961"` |
| `name` | Qlik app name | `"Compliance Dashboard"` |

### Example: Complete Tenant Configuration

```json
[
  {
    "id": "siemens-tenant-001",
    "name": "Siemens Healthineers",
    "host": "qs-i-prod.siemens.com",
    "port": 4242,
    "customers": [
      {
        "id": "healthcare-division",
        "name": "Healthcare Division",
        "apps": [
          {
            "id": "compliance_app",
            "name": "Compliance Application",
            "qlikApps": [
              {
                "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
                "name": "Compliance Dashboard"
              }
            ],
            "callbackUrl": "https://compliance.siemens.com/return"
          },
          {
            "id": "audit_app",
            "name": "Audit Application",
            "qlikApps": [
              {
                "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
                "name": "Audit Dashboard"
              }
            ],
            "callbackUrl": "https://audit.siemens.com/return"
          }
        ]
      }
    ],
    "authType": "windows",
    "idProvider": null
  }
]
```

### Adding a New Tenant

1. **Get Qlik server details**:
   - Server hostname
   - QRS port (usually 4242)
   - Virtual proxy prefix (if used)

2. **Create tenant entry** in `configuration_develop.json`:
   ```json
   {
     "id": "new-tenant-id",
     "name": "New Tenant Name",
     "host": "qlik-server.domain.com",
     "port": 4242,
     "customers": [],
     "authType": "windows",
     "idProvider": null
   }
   ```

3. **Add customers and apps** as needed

4. **Restart App API**:
   ```bash
   docker-compose restart sih-atellica-qplus-backend
   ```

### Authentication Types

**Windows Authentication** (`"windows"`):
- Uses Windows domain authentication
- Requires virtual proxy with Windows auth configured
- Session cookies managed by Qlik Proxy

**Cloud Authentication** (`"cloud"`):
- Uses Qlik Cloud OAuth/OIDC
- Requires API key in tenant config
- JWT tokens for session management

**Header Authentication** (`"header"`):
- Custom header-based authentication
- Requires identity provider configuration
- Used for SSO integrations

## Frontend Startup Configuration

The frontend uses `startup.json` for runtime initialization with Qlik app IDs and pages.

### File Location

```
sih-atellica-qplus-frontend/src/app/json/startup.json
```

### Startup Structure

```json
{
  "vp": "localhost",
  "theme": "db-theme-siemens-light",
  "pages": [
    {
      "page": "compliance",
      "qlikAppId": "4e2d4117-f850-496b-8eb4-df1ff570c961"
    },
    {
      "page": "audit",
      "qlikAppId": "96d1506e-4b0e-424b-8b8c-0a2d42c97e69"
    },
    {
      "page": "reporting",
      "qlikAppId": "4e2d4117-f850-496b-8eb4-df1ff570c961"
    }
  ],
  "default": "compliance"
}
```

### Startup Configuration Fields

| Field | Description | Example |
|-------|-------------|---------|
| `vp` | Virtual proxy prefix | `"localhost"`, `"insight"`, `""` |
| `theme` | QPlus theme name | `"db-theme-siemens-light"` |
| `pages` | Array of page configurations | See page structure |
| `default` | Default page to load | `"compliance"` |

### Page Configuration

| Field | Description | Example |
|-------|-------------|---------|
| `page` | Page route/identifier | `"compliance"`, `"audit"` |
| `qlikAppId` | Qlik app GUID for this page | `"a1b2c3d4-..."` |

### How to Get Qlik App IDs

1. **Open Qlik Management Console (QMC)**:
   - Navigate to `https://qlik-server/qmc`

2. **Go to Apps section**:
   - QMC → Apps

3. **Find your app**:
   - Click on the app name
   - Copy the GUID from the URL or app details

4. **Or use QRS API**:
   ```bash
   curl -X GET "https://qlik-server:4242/qrs/app/full" \
     --cert client.pem \
     --key client_key.pem \
     --cacert root.pem
   ```

### Available Themes

- `db-theme-siemens-light` - Siemens light theme (default)
- `db-theme-siemens-dark` - Siemens dark theme
- Custom themes can be added via QPlus configuration

### Adding a New Page

1. **Add page to startup.json**:
   ```json
   {
     "page": "newpage",
     "qlikAppId": "your-qlik-app-guid-here"
   }
   ```

2. **Create page component** in frontend:
   ```
   sih-atellica-qplus-frontend/src/app/dashboards/newpage/
   ```

3. **Add route** in `RouteApp.tsx`

4. **Rebuild frontend**:
   ```bash
   npm run build
   ```

## Environment Variables Reference

### App API Variables (Complete List)

```bash
# Server Configuration
HOST=0.0.0.0
PORT=8080
SSL=false
TITLE=App Api
VERSION=v1
APP_NAME=Siemens

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=root
DB_PASS=root
DB_DATABASE=databridge_dev
DB_SSL=false

# Qlik Service Integration
QLIK_SERVICE_HOST=http://sih-atellica-qlik-service
QLIK_SERVICE_PORT=8080

# Authentication
API_KEY=your-api-key-here
QLIK_APP_SESSION_HEADER=X-Qlik-Session

# Tenant Configuration
TENANT_FILE_PATH=src/
TENANT_FILE_NAME=configuration_develop.json
TENANT_FILE_ONLY=false

# JWT (Qlik Cloud)
JWT_AUDIENCE=qlik.api/login/jwt-session
JWT_ISSUER=your-tenant.qlikcloud.com
JWT_EXPIRES_IN=21600
STATE_SECRET=your-state-secret-here

# Logging
LOG_DIR=logs
LOG_FILE_TYPE=file
LOG_LEVEL=info
LOG_CORE_FILE=core.log
LOG_DATE_PATTERN=YYYY-MM-DD
LOG_MAX_SIZE=20m
LOG_MAX_FILES=14d

# TLS/SSL
NODE_TLS_REJECT_UNAUTHORIZED=0
SERVER_CERT_PATH=./build/certificates/server
SERVER_CERT_FILE_NAME=server.crt
SERVER_KEY_FILE_NAME=server.key

# Windows Service
SVC_DOMAIN=
SVC_ACCOUNT=
SVC_PWD=

# Roles & Scopes
DEFAULT_ROLES=
DEFAULT_SCOPES=
ROLES_MAPPER=dataconsumer=>admin;consumer=>user

# Environment
NODE_ENV=development
DOMAIN_NAME=
```

### Qlik Service Variables (Complete List)

```bash
# Server Configuration
HOST=0.0.0.0
PORT=8080
TITLE=Qlik Service
VERSION=v1
SSL=false
APP_NAME=DB-Q-SERVICE

# Qlik Authentication
QS_REPOSITORY_USER_ID=sa_repository
QS_REPOSITORY_USER_DIRECTORY=INTERNAL
QS_ENGINE_USER_ID=sa_api
QS_ENGINE_USER_DIRECTORY=INTERNAL

# Certificates
QS_CERT_TYPE=ca
QS_CA_PATH=./src/certificates/qlik/root.pem
QS_KEY_PATH=./src/certificates/qlik/client_key.pem
QS_CERT_PATH=./src/certificates/qlik/client.pem
QS_PFX_PATH=
QS_PFX_PASS=
QLIK_CERT_PASSPHRASE=

# Database (if needed)
DB_HOST=localhost
DB_PORT=5432
DB_USER=root
DB_PASS=root
DB_DATABASE=databridge_dev
DB_SSL=false

# Gateway
GATEWAY_HOST=
GATEWAY_PATH=

# TLS/SSL
NODE_TLS_REJECT_UNAUTHORIZED=1

# Windows Service
SVC_DOMAIN=
SVC_ACCOUNT=
SVC_PWD=
```

## Configuration Best Practices

### Security

1. **Never commit .env files**:
   ```bash
   # .gitignore should include:
   .env
   .env.local
   .env.*.local
   ```

2. **Generate unique API keys**:
   ```bash
   # Use strong random keys
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   ```

3. **Use environment-specific files**:
   - `.env.development`
   - `.env.staging`
   - `.env.production`

4. **Enable TLS in production**:
   ```bash
   NODE_TLS_REJECT_UNAUTHORIZED=1
   SSL=true
   ```

### Tenant Management

1. **Use separate files per environment**:
   - `configuration_develop.json` - Local development
   - `configuration_staging.json` - Staging environment
   - `configuration_production.json` - Production

2. **Validate JSON before deployment**:
   ```bash
   node -e "JSON.parse(require('fs').readFileSync('configuration_develop.json'))"
   ```

3. **Document tenant changes** in commit messages

4. **Test new tenants** in development first

### Frontend Configuration

1. **Rebuild after .env changes**:
   ```bash
   npm run build
   ```

2. **Validate Qlik app IDs** before deployment

3. **Test virtual proxy** configuration

## Common Configuration Scenarios

### Scenario 1: New Developer Setup (Local Development)

```bash
# 1. Copy environment files
cp sih-atellica-qplus-backend/.env.example sih-atellica-qplus-backend/.env
cp sih-atellica-qlik-service/.env.example sih-atellica-qlik-service/.env
cp sih-atellica-qplus-frontend/.env.example sih-atellica-qplus-frontend/.env

# 2. Edit App API .env (usually defaults are fine)
# Just set API_KEY to something unique

# 3. Edit Qlik Service .env
# Set certificate paths if you have Qlik certificates

# 4. Edit Frontend .env
# Set REACT_APP_QLIK_HOST_NAME to your Qlik server

# 5. Start services
docker-compose up
```

### Scenario 2: Connecting to Different Qlik Environment

**Edit App API tenant config** (`sih-atellica-qplus-backend/src/configuration_develop.json`):
```json
{
  "host": "new-qlik-server.domain.com",
  "port": 4242
}
```

**Edit Qlik Service certificates**:
```bash
# Copy new certificates to sih-atellica-qlik-service/src/certificates/qlik/
```

**Edit Frontend .env**:
```bash
REACT_APP_QLIK_HOST_NAME=new-qlik-server.domain.com
```

**Restart services**:
```bash
docker-compose restart
```

### Scenario 3: Adding New Qlik Apps

1. **Get Qlik app GUID** from QMC

2. **Update frontend startup.json**:
   ```json
   {
     "page": "newdashboard",
     "qlikAppId": "new-app-guid-here"
   }
   ```

3. **Update tenant config** (if needed):
   ```json
   {
     "qlikApps": [
       {
         "id": "new-app-guid-here",
         "name": "New Dashboard"
       }
     ]
   }
   ```

4. **Rebuild and restart**:
   ```bash
   cd sih-atellica-qplus-frontend
   npm run build
   cd ..
   docker-compose restart
   ```

### Scenario 4: Multi-Tenant Production Setup

**Create production tenant file** (`configuration_production.json`):
```json
[
  {
    "id": "tenant-1",
    "name": "Tenant One",
    "host": "qlik-prod-1.domain.com",
    "customers": [...]
  },
  {
    "id": "tenant-2",
    "name": "Tenant Two",
    "host": "qlik-prod-2.domain.com",
    "customers": [...]
  }
]
```

**Configure App API .env**:
```bash
TENANT_FILE_NAME=configuration_production.json
NODE_ENV=production
```

---

For more information:
- [Qlik Setup Guide](./QLIK_SETUP.md) - Certificate setup and Qlik integration
- [Development Guide](./DEVELOPMENT_GUIDE.md) - Development workflow
- [Architecture Documentation](./ARCHITECTURE.md) - System architecture

**Last Updated**: December 2025
