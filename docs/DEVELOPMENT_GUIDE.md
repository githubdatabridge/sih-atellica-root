# Development Guide

## Prerequisites

### Required Software

- **Git**: Version 2.17.1 or higher
- **Docker**: Version 20.10.8 or higher
- **Docker Compose**: Included with Docker Desktop
- **Node.js**: Version 16.5.0 to 20.x (for local development without Docker)
- **NPM**: Version 9.0.0 or higher

### Recommended Tools

- **VS Code** or **WebStorm** with TypeScript support
- **Postman** or **Insomnia** for API testing
- **PostgreSQL Client** (pgAdmin, DBeaver, or CLI) for database inspection
- **Git GUI** (optional): GitKraken, SourceTree, or GitHub Desktop

## Initial Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd db-siemens-dev
```

### 2. Initialize Submodules

This project uses Git submodules for each service:

```bash
git submodule update --init --remote
```

### 3. Configure Environment

Copy the example environment file and configure it:

```bash
cp .env.example .env
```

**Important Variables to Configure**:

```bash
# Database Configuration
DB_APP_API_DB_HOST=db
DB_APP_API_DB_PORT=5432
DB_APP_API_DB_USER=root
DB_APP_API_DB_PASS=root
DB_APP_API_DB_DATABASE=databridge_dev

# Qlik Sense Configuration
DB_APP_API_QS_HOST=your-qlik-server.com
DB_APP_API_QS_QIX_PORT=443
DB_APP_API_QS_VP=insight
DB_APP_API_QS_USER_DIRECTORY=INTERNAL
DB_APP_API_QS_USER_ID=sa_api

# API Keys (Generate secure keys for production)
DB_APP_API_API_KEY=your-api-key-here
DB_QLIK_API_KEY=your-qlik-api-key-here
```

### 4. Configure Docker Drive Sharing

**Windows Users**:
- Open Docker Desktop → Settings → Resources → File Sharing
- Ensure the drive containing the project is shared

**Mac Users**:
- Docker Desktop → Preferences → Resources → File Sharing
- Add the project directory if not already included

## Running the Application

### Start All Services

```bash
docker-compose up
```

This will start:
- PostgreSQL database on port 5432
- App API on port 3002
- Qlik Service on port 3001

For detached mode (background):
```bash
docker-compose up -d
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f sih-atellica-qplus-backend
docker-compose logs -f sih-atellica-qlik-service
```

### Stop All Services

```bash
docker-compose down
```

To remove volumes (database data):
```bash
docker-compose down -v
```

## Running Migrations

After services are up, run database migrations:

```bash
# Navigate to migrations directory (if exists)
cd db-database-migrations

# Install dependencies
npm install

# Create database
npm run create

# Run migrations
npm run migrate
```

## Frontend Development

### Start Frontend (Development Mode)

```bash
cd sih-atellica-qplus-frontend
npm install
npm start
```

The frontend will be available at `http://localhost:7005`

### Configure Frontend Startup

Edit `sih-atellica-qplus-frontend/public/startup.json`:

```json
{
    "vp": "localhost",
    "theme": "db-theme-siemens-light",
    "pages": [
        {
            "page": "compliance",
            "qlikAppId": "your-compliance-app-id"
        },
        {
            "page": "audit",
            "qlikAppId": "your-audit-app-id"
        },
        {
            "page": "reporting",
            "qlikAppId": "your-reporting-app-id"
        }
    ],
    "default": "compliance"
}
```

### Build Frontend

```bash
npm run build
```

## Backend Development

### Running Services Locally (Without Docker)

#### App API

```bash
cd sih-atellica-qplus-backend
cp .env.example .env
npm install
npm run dev  # Hot-reload development mode
```

Access:
- API: `http://localhost:8080`
- Swagger Docs: `http://localhost:8080/documentation`

#### Qlik Service

```bash
cd sih-atellica-qlik-service
cp .env.example .env
npm install
npm run dev
```

Access:
- API: `http://localhost:8080`
- Swagger Docs: `http://localhost:8080/documentation`

### Making Code Changes

#### Hot Reload

Both backend services use `tsc-watch` which automatically:
1. Recompiles TypeScript when files change
2. Restarts the Node.js server
3. Displays compilation errors

No manual restart needed during development.

#### Installing New Packages

**Inside Docker Container**:
```bash
# SSH into container
docker-compose exec sih-atellica-qplus-backend sh

# Install package
npm install package-name

# Exit container
exit
```

Or restart containers (npm install runs on startup):
```bash
docker-compose restart sih-atellica-qplus-backend
```

**Local Development**:
```bash
cd sih-atellica-qplus-backend
npm install package-name
```

## Database Management

### Connect to PostgreSQL

**From Host Machine**:
```bash
psql -h localhost -p 5432 -U root -d pgdb
# Password: root
```

**Using Docker**:
```bash
docker-compose exec db psql -U root -d pgdb
```

### Common Database Commands

```sql
-- List databases
\l

-- List tables
\dt

-- Describe table
\d table_name

-- Query data
SELECT * FROM users LIMIT 10;
```

### Database Backup

```bash
docker-compose exec db pg_dump -U root pgdb > backup.sql
```

### Database Restore

```bash
docker-compose exec -T db psql -U root pgdb < backup.sql
```

### Create New Migration

```bash
cd sih-atellica-qplus-backend
npm run migration:make -- migration_name
```

This creates a new migration file in `src/database/migrations/`

## Testing

### Running Tests

#### App API Tests

```bash
cd sih-atellica-qplus-backend
npm test
```

#### Running API Tests with Docker

```bash
cd sih-atellica-qplus-backend/tests/requirements

# Create test environment
cp .env.example .env

# Run tests
docker-compose -f ./docker-compose-test-local.yml -p db-qplus-test up \
  --build --abort-on-container-exit --exit-code-from qplus-app-api-test
```

#### Frontend Tests

```bash
cd sih-atellica-qplus-frontend
npm test
```

### Testing with Postman

Import Postman collections from:
- `sih-atellica-qplus-backend/tests/postman/`

Available collections:
- `sih-atellica-qplus-backend.postman_collection.json` - Main API tests
- `sih-atellica-qplus-backend-bookmarks.postman_collection.json` - Bookmark tests
- `sih-atellica-qplus-backend-comments.postman_collection.json` - Comment tests

## API Development

### Creating a New Endpoint

#### 1. Define Entity (if needed)

Create `src/entities/MyEntity.ts`:
```typescript
export interface MyEntity {
  id: number;
  name: string;
  createdAt: Date;
}
```

#### 2. Create Repository

Create `src/repositories/MyEntityRepository.ts`:
```typescript
import { injectable } from 'tsyringe';
import { DatabaseService } from '../lib/database/DatabaseService';

@injectable()
export class MyEntityRepository {
  constructor(private db: DatabaseService) {}

  async findAll(): Promise<MyEntity[]> {
    return this.db.knex('my_entities').select('*');
  }

  async create(data: Partial<MyEntity>): Promise<MyEntity> {
    const [entity] = await this.db.knex('my_entities')
      .insert(data)
      .returning('*');
    return entity;
  }
}
```

#### 3. Create Service

Create `src/services/MyEntityService.ts`:
```typescript
import { injectable } from 'tsyringe';
import { MyEntityRepository } from '../repositories/MyEntityRepository';

@injectable()
export class MyEntityService {
  constructor(private repository: MyEntityRepository) {}

  async getAll(): Promise<MyEntity[]> {
    return this.repository.findAll();
  }

  async create(data: Partial<MyEntity>): Promise<MyEntity> {
    // Business logic here
    return this.repository.create(data);
  }
}
```

#### 4. Create Controller

Create `src/controllers/MyEntityController.ts`:
```typescript
import { Request, ResponseToolkit } from '@hapi/hapi';
import { controller, httpGet, httpPost } from 'hapi-decorators';
import { injectable } from 'tsyringe';
import Joi from 'joi';
import { MyEntityService } from '../services/MyEntityService';

@controller('/api/my-entities')
@injectable()
export class MyEntityController {
  constructor(private service: MyEntityService) {}

  @httpGet('/')
  async getAll(request: Request, h: ResponseToolkit) {
    const entities = await this.service.getAll();
    return h.response(entities).code(200);
  }

  @httpPost('/')
  async create(request: Request, h: ResponseToolkit) {
    const entity = await this.service.create(request.payload);
    return h.response(entity).code(201);
  }
}
```

#### 5. Register Controller

In `src/index.ts`, ensure the controller is imported (auto-discovery via decorators).

### API Documentation

Swagger documentation is auto-generated from Joi validators:

```typescript
@httpPost('/', {
  options: {
    description: 'Create a new entity',
    tags: ['api', 'entities'],
    validate: {
      payload: Joi.object({
        name: Joi.string().required().description('Entity name'),
        description: Joi.string().optional()
      })
    },
    response: {
      schema: Joi.object({
        id: Joi.number(),
        name: Joi.string(),
        createdAt: Joi.date()
      })
    }
  }
})
```

## Debugging

### VS Code Configuration

Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "attach",
      "name": "Docker: Attach to App API",
      "port": 9229,
      "address": "localhost",
      "localRoot": "${workspaceFolder}/sih-atellica-qplus-backend",
      "remoteRoot": "/usr/src/app",
      "protocol": "inspector",
      "restart": true
    }
  ]
}
```

Enable debugging in `docker-compose.yml`:

```yaml
sih-atellica-qplus-backend:
  command: node --inspect=0.0.0.0:9229 build/index.js
  ports:
    - "9229:9229"
```

### Logging

Both services use Winston logger:

```typescript
import { logger } from './lib/logger';

logger.info('Info message');
logger.error('Error message', { error: err });
logger.debug('Debug message', { data: someData });
```

Logs are written to:
- Console (development)
- `logs/core.log` (file system)
- Daily rotation configured

## Qlik Integration Development

### Certificate Setup

1. Export certificates from Qlik Sense QMC
2. Place in `sih-atellica-qlik-service/src/certificates/`
3. Update `.env`:

```bash
DB_QLIK_SERVICE_QS_REPOSITORY_USER_ID=sa_repository
DB_QLIK_SERVICE_QS_REPOSITORY_USER_DIRECTORY=INTERNAL
DB_QLIK_SERVICE_QS_ENGINE_USER_ID=sa_api
DB_QLIK_SERVICE_QS_ENGINE_USER_DIRECTORY=INTERNAL
```

### Testing Qlik Connection

```bash
curl http://localhost:3001/api/qlik/health
```

## Code Style & Best Practices

### TypeScript

- Use strict type checking
- Avoid `any` type
- Define interfaces for all data structures
- Use async/await over promises

### Naming Conventions

- **Files**: PascalCase for classes (`UserService.ts`), camelCase for utilities (`stringHelper.ts`)
- **Classes**: PascalCase (`UserService`)
- **Functions**: camelCase (`getUserById`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_RETRIES`)
- **Interfaces**: PascalCase (`IUserRepository` or `UserEntity`)

### Error Handling

```typescript
import Boom from '@hapi/boom';

// Validation error
throw Boom.badRequest('Invalid input');

// Not found
throw Boom.notFound('User not found');

// Unauthorized
throw Boom.unauthorized('Invalid token');

// Server error
throw Boom.internal('Something went wrong', { originalError: err });
```

## Git Workflow

### Working with Submodules

```bash
# Update all submodules to latest
git submodule update --remote

# Update specific submodule
cd sih-atellica-qplus-backend
git pull origin main

# Commit submodule changes in main repo
cd ..
git add sih-atellica-qplus-backend
git commit -m "Update app API submodule"
```

### Branch Strategy

- `main` - Production-ready code
- `develop` - Integration branch
- `feature/feature-name` - Feature branches
- `bugfix/bug-description` - Bug fix branches

### Commit Messages

```
feat: Add user authentication endpoint
fix: Resolve database connection timeout
docs: Update API documentation
refactor: Simplify bookmark service logic
test: Add unit tests for user service
```

## Troubleshooting

### Common Issues

#### Port Already in Use

```bash
# Find process using port
lsof -i :3002  # Mac/Linux
netstat -ano | findstr :3002  # Windows

# Kill process or change port in docker-compose.yml
```

#### Database Connection Failed

- Ensure database container is running: `docker-compose ps`
- Check database credentials in `.env`
- Verify database is created: `docker-compose exec db psql -U root -l`

#### Qlik Connection Failed

- Verify Qlik Sense server is accessible
- Check certificate files exist and are valid
- Verify virtual proxy configuration
- Test connection: `curl https://your-qlik-server/hub`

#### Node Modules Issues

```bash
# Remove and reinstall
docker-compose down
docker volume rm db-siemens-dev_db-insight-app-api-node_modules
docker-compose up --build
```

#### TypeScript Compilation Errors

```bash
# Clean build directory
rm -rf sih-atellica-qplus-backend/build
cd sih-atellica-qplus-backend
npm run tsc
```

## Performance Optimization

### Database Query Optimization

- Use indexes for frequently queried columns
- Avoid N+1 queries (use joins or eager loading)
- Use pagination for large datasets
- Monitor slow queries

### API Optimization

- Enable response compression
- Implement caching where appropriate
- Use connection pooling
- Minimize payload size

### Frontend Optimization

- Code splitting
- Lazy loading routes
- Optimize Qlik mashup loading
- Minimize bundle size

## Useful Commands

```bash
# View running containers
docker-compose ps

# Restart specific service
docker-compose restart sih-atellica-qplus-backend

# View service logs (last 100 lines)
docker-compose logs --tail=100 sih-atellica-qplus-backend

# Execute command in container
docker-compose exec sih-atellica-qplus-backend npm run migration:make -- new_migration

# Clean up Docker
docker system prune -a  # Remove all unused containers, networks, images

# Check TypeScript compilation
npm run tsc -- --noEmit

# Format code (if Prettier is configured)
npm run format
```

## Additional Resources

- [Hapi.js Documentation](https://hapi.dev/)
- [Qlik Engine API](https://help.qlik.com/en-US/sense-developer/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [React Documentation](https://react.dev/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

For questions or issues, please refer to individual service README files or contact the development team.
