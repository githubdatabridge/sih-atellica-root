# Architecture Documentation

## System Architecture

The SIH Atellica Connect Analytics Component follows a modern microservices architecture pattern, designed for scalability, maintainability, and clear separation of concerns.

## Architectural Patterns

### 1. Microservices Architecture

The system is decomposed into three independent services:

- **Frontend Service**: User interface and presentation layer
- **Application API**: Business logic and data management
- **Qlik Service**: Analytics integration middleware

**Benefits**:
- Independent deployment and scaling
- Technology flexibility per service
- Fault isolation
- Clear boundaries and responsibilities

### 2. Layered Architecture (App API & Qlik Service)

Each backend service follows a layered architecture:

```
┌─────────────────────────────────┐
│     Controllers (HTTP Layer)    │  ← Route handling, request/response
├─────────────────────────────────┤
│        Actions/Services         │  ← Business logic
├─────────────────────────────────┤
│   Repositories/Data Access      │  ← Data persistence
├─────────────────────────────────┤
│      Entities/Models            │  ← Domain models
└─────────────────────────────────┘
```

#### Controller Layer
- **Location**: `src/controllers/`
- **Responsibility**: HTTP request handling, routing, response formatting
- **Pattern**: Uses `hapi-decorators` for declarative route definitions
- **Features**:
  - Swagger documentation via Joi validators
  - Request validation
  - Error handling
  - Response transformation

#### Service/Action Layer
- **Location**: `src/services/`, `src/actions/`
- **Responsibility**: Business logic, orchestration
- **Pattern**: Dependency injection via TSyringe
- **Features**:
  - Reusable business operations
  - Transaction management
  - External service integration
  - Complex data processing

#### Repository Layer
- **Location**: `src/repositories/`
- **Responsibility**: Data access and persistence
- **Pattern**: Repository pattern with Knex.js
- **Features**:
  - CRUD operations
  - Query building
  - Pagination
  - Transaction support

#### Entity/Model Layer
- **Location**: `src/entities/`, `src/model/`
- **Responsibility**: Domain object definitions
- **Features**:
  - Data structure definition
  - Type safety
  - Validation rules

### 3. Frontend Architecture (React)

```
┌─────────────────────────────────────────────────────────────┐
│                      App Component                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                 │
│  │Compliance│  │  Audit   │  │ Reporting│                 │
│  │   Page   │  │   Page   │  │   Page   │                 │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                 │
│       │             │              │                        │
│       └─────────────┴──────────────┘                        │
│                     │                                       │
│              ┌──────▼──────────────────┐                   │
│              │  QPlus Provider         │                   │
│              │  (Capability API)       │                   │
│              └──────┬──────────────────┘                   │
│                     │                                       │
│       ┌─────────────┼─────────────┐                        │
│       │             │             │                        │
│       ▼             ▼             ▼                        │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                   │
│  │  Qlik   │  │  Qlik   │  │   App   │                   │
│  │ Mashup  │  │  Apps   │  │   API   │                   │
│  │WebSocket│  │ (Direct)│  │  (HTTP) │                   │
│  └─────────┘  └─────────┘  └─────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

**Key Components**:
- React Router for navigation
- Material-UI for consistent UI components
- **QPlus library** (`@databridge/qplus`): Wrapper for Qlik Capability API
  - Direct WebSocket connection to Qlik Enterprise Server
  - QES (Qlik Enterprise Server) authentication mode
  - Dynamic Qlik app loading
  - Virtual proxy configuration
- Configuration-driven page setup via `startup.json`
- **Dual Communication Pattern**:
  - Qlik Capability API for analytics (direct to Qlik Enterprise)
  - REST API calls to App API for application data (bookmarks, comments, etc.)

## Communication Patterns

### 1. Synchronous Communication (REST)

**Frontend ↔ App API**:
```
GET /api/bookmarks
POST /api/comments
PUT /api/users/{id}
DELETE /api/resource/{id}
```

**App API ↔ Qlik Service**:
```
GET /qlik/apps
POST /qlik/sessions
GET /qlik/metadata
```

### 2. Real-time Communication (WebSocket)

**Frontend ↔ App API**:
- Socket.IO for real-time updates
- Event-based notifications
- Live data synchronization for application events

**Frontend ↔ Qlik Enterprise (Direct)**:
- **Qlik Capability API** via WebSocket (NOT through Qlik Service)
- Direct connection from browser to Qlik Enterprise Server
- Real-time analytics updates and visualizations
- Session management through QPlus library
- QES authentication mode with virtual proxy

### 3. Certificate-based Authentication

**Qlik Service ↔ Qlik Sense**:
- X.509 certificate authentication
- Mutual TLS
- Virtual proxy routing

## Data Flow Patterns

### 1. Analytics Data Flow (Frontend → Qlik Direct)

```
User Action
    │
    ▼
Frontend Component
    │
    ▼
QPlus Provider (Capability API)
    │
    ▼
Qlik Enterprise Server (Direct WebSocket)
    │
    ├──► QIX Engine API (Data & Objects)
    │
    ├──► Load Qlik Apps
    │
    ▼
Qlik Mashup Rendering in Browser

Note: NO intermediate service - frontend connects directly to Qlik
```

### 2. Application Data Flow

```
User Request
    │
    ▼
Frontend
    │
    ▼
App API Controller
    │
    ├──► Validation (Joi)
    │
    ├──► Authentication/Authorization
    │
    ▼
Service Layer
    │
    ├──► Business Logic
    │
    ▼
Repository Layer
    │
    ▼
Database
```

### 3. Qlik Administrative Operations Flow (App API → Qlik Service)

```
Backend Operation Trigger
    │
    ▼
App API Service Layer
    │
    ├──► QlikService (HTTP Client)
    │         │
    │         ├──► POST /user/auth (User sync)
    │         ├──► POST /integration (Onboard tenant)
    │         ├──► POST /app/attach (Upload files)
    │         ├──► POST /task/start (Trigger reload)
    │         ├──► DELETE /user (Remove user)
    │         │
    │         ▼
    │    Qlik Service (Wrapper)
    │         │
    │         ├──► QRS API (Repository operations)
    │         ├──► QPS API (Proxy/session operations)
    │         ├──► QIX API (Engine operations)
    │         │
    │         ▼
    │    Qlik Enterprise Server
    │         │
    │         ▼
    │    Operation Response
    │         │
    │         ▼
    └──► Process Response
    │
    ▼
Business Logic Completion

Note: This flow is for backend administrative operations,
      NOT for frontend analytics visualization
```

## Dependency Injection

Both backend services use TSyringe for dependency injection:

**Benefits**:
- Loose coupling
- Testability
- Lifecycle management
- Easy mocking for tests

**Implementation Example**:
```typescript
// Service registration
container.register('DatabaseService', {
  useClass: DatabaseService
});

// Service consumption
@injectable()
class UserService {
  constructor(
    @inject('DatabaseService') private db: DatabaseService
  ) {}
}
```

## Database Architecture

### Schema Organization

```
PostgreSQL Database
│
├── Application Tables
│   ├── users
│   ├── tenants
│   ├── sessions
│   └── audit_logs
│
├── Feature Tables
│   ├── bookmarks
│   ├── comments
│   └── notifications
│
└── Configuration Tables
    ├── tenant_config
    └── app_settings
```

### Migration Strategy

- Knex.js migrations for version control
- Sequential migrations with rollback support
- Environment-specific seeds
- Schema versioning

### Data Isolation

- Tenant-based data separation
- Row-level security considerations
- Tenant ID in all application tables

## Security Architecture

### 1. Authentication Layers

```
┌─────────────────────────────────────────┐
│         User Authentication             │
│  (OpenID Connect / Qlik Sense Auth)     │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      JWT Token Management (App API)     │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│   Certificate Auth (Qlik Integration)   │
└─────────────────────────────────────────┘
```

### 2. Authorization

- JWT payload contains user claims
- Tenant context extracted from token
- Row-level data filtering by tenant
- API key authentication for service-to-service

### 3. Data Security

- Environment variables for secrets
- Certificate storage for Qlik authentication
- PostgreSQL SSL connections
- API key rotation support

## Scalability Considerations

### Horizontal Scaling

**Current Architecture Supports**:
- Multiple Frontend instances (stateless)
- Multiple App API instances (with load balancer)
- Multiple Qlik Service instances (session affinity required)
- Database read replicas for reporting

**Scaling Strategy**:
```
Load Balancer
    │
    ├──► Frontend Instance 1
    ├──► Frontend Instance 2
    └──► Frontend Instance N

Load Balancer
    │
    ├──► App API Instance 1
    ├──► App API Instance 2
    └──► App API Instance N
         │
         ▼
    PostgreSQL (Primary + Replicas)
```

### Vertical Scaling

- PostgreSQL can scale vertically
- Node.js services benefit from more CPU cores
- Memory allocation for concurrent connections

### Caching Strategy (Future)

- Redis for session management
- API response caching
- Qlik metadata caching
- Application configuration caching

## Error Handling Architecture

### 1. Error Propagation

```
Error Origin
    │
    ▼
Service Layer (Log & Transform)
    │
    ▼
Controller Layer (HTTP Status Code)
    │
    ▼
Frontend (User-friendly Message)
```

### 2. Logging Strategy

- Winston for structured logging
- Daily rotating log files
- Log levels: error, warn, info, debug
- Centralized logging (future: ELK stack)

### 3. Error Types

- **Validation Errors**: 400 Bad Request
- **Authentication Errors**: 401 Unauthorized
- **Authorization Errors**: 403 Forbidden
- **Not Found**: 404 Not Found
- **Business Logic Errors**: 422 Unprocessable Entity
- **Server Errors**: 500 Internal Server Error

## Configuration Management

### Environment-based Configuration

```
.env (Development)
    │
    ├──► DB_APP_API_* (App API config)
    ├──► DB_QLIK_SERVICE_* (Qlik Service config)
    ├──► DB_* (Database config)
    └──► Common settings
```

### Configuration Hierarchy

1. Environment variables (highest priority)
2. Service-specific config files
3. Tenant configuration files
4. Default values (lowest priority)

## Monitoring & Observability

### Health Checks

Each service provides health check endpoints:
- `/health` - Basic health status
- `/ping` - Service availability
- `/documentation` - API documentation

### Metrics (Future Consideration)

- Request/response times
- Error rates
- Database query performance
- Memory and CPU usage
- Active sessions

### Logging

- Request/response logging
- Error logging with stack traces
- Database query logging
- External service call logging

## Deployment Architecture

### Docker Compose (Development)

```yaml
services:
  sih-atellica-qplus-backend:
    - Depends on: db
    - Port: 3002
    - Volume: source code mounted

  sih-atellica-qlik-service:
    - Depends on: db
    - Port: 3001
    - Volume: source code mounted

  db (PostgreSQL):
    - Port: 5432
    - Volume: data persistence
```

### Production Deployment (Recommended)

- Kubernetes for orchestration
- Docker containers for services
- Managed PostgreSQL (Azure Database, AWS RDS)
- Load balancers for traffic distribution
- Ingress controllers for routing
- TLS termination at load balancer

## Integration Architecture

### Qlik Sense Integration

```
┌──────────────────────────────────────────────────────────┐
│               Qlik Sense Enterprise Server               │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌─────────────────┐       │
│  │   QRS    │  │   QPS    │  │  QIX (Engine)   │       │
│  │  (4242)  │  │  (4243)  │  │     (443)       │       │
│  └─────▲────┘  └─────▲────┘  └────────▲────────┘       │
│        │             │                 │                 │
└────────┼─────────────┼─────────────────┼─────────────────┘
         │             │                 │
         │             │                 │
         │        ┌────┴────┐            │
         │        │         │            │
         │        │         │            │ (Capability API
         │        │         │            │  WebSocket)
   ┌─────┴──┐     │    ┌────┴────────────┴────────┐
   │  Qlik  │     │    │      Frontend (React)    │
   │ Service│◄────┘    │   (QPlus + Capability)   │
   │ (3001) │          └────────────┬──────────────┘
   └────▲───┘                       │
        │                           │ (REST/HTTP)
        │                           │
   ┌────┴─────────────────┐         │
   │    App API (3002)    │◄────────┘
   └──────────────────────┘
```

**Integration Breakdown**:

**QRS (Qlik Repository Service)** - Port 4242:
- App metadata and configuration
- User and license management
- Content library management
- **Consumed by**: Qlik Service (via certificate auth)

**QPS (Qlik Proxy Service)** - Port 4243:
- Session management and validation
- Virtual proxy routing
- Load balancing
- **Consumed by**: Qlik Service (via certificate auth)

**QIX (Qlik Engine API)** - Port 443:
- Data model access
- Visualization rendering
- Real-time analytics updates
- **Consumed by**:
  - Frontend (via Capability API/WebSocket - QPlus library)
  - Qlik Service (via Enigma.js for administrative operations)

**Two Integration Patterns**:

1. **Frontend → Qlik (Capability API)**:
   - Direct WebSocket connection for analytics
   - No middleware between browser and Qlik
   - Uses QPlus library wrapper
   - QES authentication mode
   - Real-time visualization rendering

2. **App API → Qlik Service → Qlik (Administrative)**:
   - HTTP REST calls for operational tasks
   - Certificate-based authentication
   - User sync, integration management, task execution
   - Uses QRS/QPS/QIX APIs via libraries (qrs-interact, enigma.js)

## Best Practices Implemented

1. **Separation of Concerns**: Clear boundaries between layers
2. **Dependency Injection**: Loose coupling, high testability
3. **Configuration Management**: Environment-based configuration
4. **Error Handling**: Consistent error responses
5. **Logging**: Comprehensive logging strategy
6. **API Documentation**: Auto-generated Swagger docs
7. **Type Safety**: TypeScript throughout
8. **Database Migrations**: Version-controlled schema changes
9. **Containerization**: Docker for consistent environments
10. **Git Submodules**: Independent service repositories

## Technology Decisions

| Requirement | Technology Choice | Rationale |
|-------------|------------------|-----------|
| Web Framework | Hapi.js | Strong typing support, plugin ecosystem, enterprise-ready |
| Frontend Framework | React | Component reusability, large ecosystem, team familiarity |
| Database | PostgreSQL | ACID compliance, JSON support, robust querying |
| Analytics Platform | Qlik Sense | Business requirement, powerful analytics, embedding support |
| Containerization | Docker | Consistency, portability, easy local development |
| Language | TypeScript | Type safety, better IDE support, fewer runtime errors |
| DI Container | TSyringe | Lightweight, TypeScript-native, decorator support |

## Future Architecture Enhancements

1. **API Gateway**: Unified entry point for all services
2. **Message Queue**: RabbitMQ/Redis for async processing
3. **Caching Layer**: Redis for performance optimization
4. **Service Mesh**: Istio for advanced service-to-service communication
5. **Monitoring**: Prometheus + Grafana for metrics
6. **Centralized Logging**: ELK stack for log aggregation
7. **CI/CD Pipeline**: Automated testing and deployment
8. **Feature Flags**: Dynamic feature toggling
9. **Rate Limiting**: API throttling and protection
10. **GraphQL API**: Alternative to REST for flexible queries

---

This architecture is designed to be maintainable, scalable, and aligned with modern microservices best practices while meeting the specific needs of the SIH Atellica Connect Analytics platform.
