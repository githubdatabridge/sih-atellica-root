# Database Guide

Complete guide to database setup, migrations, schema, and operations for the SIH Atellica Connect Analytics Component.

## Table of Contents

- [Overview](#overview)
- [Database Architecture](#database-architecture)
- [Initial Setup](#initial-setup)
- [Migrations](#migrations)
- [Schema Reference](#schema-reference)
- [Database Operations](#database-operations)
- [Backup and Restore](#backup-and-restore)
- [Performance Optimization](#performance-optimization)
- [Troubleshooting](#troubleshooting)

## Overview

The SIH Analytics platform uses **PostgreSQL 12.8** as its primary database, managed through Docker Compose with persistent storage.

### Database Stack

```
┌─────────────────────────────────┐
│     App API (Hapi.js)           │
│  - Knex.js Query Builder        │
│  - Repository Pattern            │
│  - Database Migrations           │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│   PostgreSQL 12.8 (Docker)      │
│  - Port: 5432                   │
│  - Database: pgdb               │
│  - User: root                   │
│  - Persistent Volume            │
└─────────────────────────────────┘
```

### Key Technologies

- **Database**: PostgreSQL 12.8
- **Query Builder**: Knex.js 3.1.0
- **Migrations**: Knex migrations
- **ORM Pattern**: Repository pattern (not full ORM)
- **Connection Pool**: Built-in Knex pooling

## Database Architecture

### Connection Configuration

Database connection is configured in App API:

**Location**: `sih-atellica-qplus-backend/src/lib/database/DatabaseService.ts`

**Environment Variables**:
```bash
DB_HOST=db              # 'db' for Docker, 'localhost' for local
DB_PORT=5432
DB_USER=root
DB_PASS=root
DB_DATABASE=databridge_dev
DB_SSL=false
```

### Database Schema Organization

```
PostgreSQL Database: pgdb
│
├── User & Authentication
│   └── (Managed via Qlik authentication)
│
├── Application Data
│   ├── actions               # User action tracking
│   ├── comments              # Comment system
│   ├── reactions             # Reactions to comments
│   ├── app_user_preferences  # User preferences
│   └── feedbacks             # User feedback
│
├── Qlik Integration
│   ├── qlik_states          # Saved Qlik selections
│   └── visualizations       # Visualization metadata
│
├── Analytics & Reporting
│   ├── datasets             # Dataset definitions
│   ├── reports              # Report configurations
│   ├── users_reports        # User-report associations
│   ├── pinwalls             # Pinwall collections
│   └── pinwall_qlik_states  # Pinwall Qlik states
│
└── Metadata
    ├── createdAt (all tables)
    ├── updatedAt (all tables)
    └── deletedAt (all tables) - Soft delete support
```

## Initial Setup

### Using Docker Compose (Recommended)

Database is automatically created when starting services:

```bash
# Start all services including database
docker-compose up
```

Docker Compose configuration (`docker-compose.yml`):
```yaml
db:
  image: postgres:12.8
  volumes:
    - "./data:/var/lib/postgresql/data"
  restart: always
  ports:
    - "5432:5432"
  environment:
    POSTGRES_USER: root
    POSTGRES_PASSWORD: root
    POSTGRES_DB: pgdb
```

### Manual Setup (Local PostgreSQL)

If running PostgreSQL locally instead of Docker:

#### 1. Install PostgreSQL

**macOS**:
```bash
brew install postgresql@12
brew services start postgresql@12
```

**Ubuntu/Debian**:
```bash
sudo apt-get update
sudo apt-get install postgresql-12
sudo systemctl start postgresql
```

**Windows**:
Download from [PostgreSQL Downloads](https://www.postgresql.org/download/windows/)

#### 2. Create Database

```bash
# Connect to PostgreSQL
psql -U postgres

# Create user
CREATE USER root WITH PASSWORD 'root';

# Create database
CREATE DATABASE pgdb OWNER root;

# Grant privileges
GRANT ALL PRIVILEGES ON DATABASE pgdb TO root;

# Exit
\q
```

#### 3. Configure App API

Update `sih-atellica-qplus-backend/.env`:
```bash
DB_HOST=localhost
DB_PORT=5432
DB_USER=root
DB_PASS=root
DB_DATABASE=pgdb
DB_SSL=false
```

### Verify Database Connection

```bash
# Using psql
psql -h localhost -p 5432 -U root -d pgdb
# Password: root

# Or with Docker
docker-compose exec db psql -U root -d pgdb
```

Should connect successfully and show PostgreSQL prompt:
```
pgdb=#
```

## Migrations

The project uses **Knex.js migrations** for database schema management.

### Migration File Location

```
sih-atellica-qplus-backend/
└── src/
    └── database/
        ├── migrations/
        │   ├── 20200511074854-create-actions.ts
        │   ├── 20200511075423-create-comments.ts
        │   ├── 20200511084439-create-reactions.ts
        │   └── ... (more migrations)
        └── knexfile.ts
```

### Running Migrations

#### First Time Setup

```bash
cd sih-atellica-qplus-backend
npm install

# Run all pending migrations
npm run migrate
```

Or if you have a separate migrations service:
```bash
cd db-database-migrations
npm install
npm run create   # Creates database if it doesn't exist
npm run migrate  # Runs all migrations
```

#### Check Migration Status

```bash
# See which migrations have run
npx knex migrate:list --knexfile src/database/knexfile.ts
```

Output shows:
```
Batch 1 - run: 2020-05-11
  20200511074854-create-actions.ts
  20200511075423-create-comments.ts
  20200511084439-create-reactions.ts
...
```

### Creating New Migrations

#### 1. Generate Migration File

```bash
cd sih-atellica-qplus-backend

# Create new migration
npm run migration:make -- create_my_table
```

This creates a new file:
```
src/database/migrations/YYYYMMDDHHMMSS-create_my_table.ts
```

#### 2. Write Migration

Edit the generated file:

```typescript
import { Knex } from 'knex';

const tableName = 'my_table';

export async function up(knex: Knex): Promise<void> {
    await knex.schema.createTable(tableName, (table) => {
        table.increments('id').primary();
        table.string('name', 255).notNullable();
        table.text('description').nullable();
        table.integer('userId').notNullable();
        table.boolean('isActive').defaultTo(true);

        // Common timestamps (required pattern)
        table.timestamp('createdAt', { useTz: false })
            .defaultTo(knex.fn.now())
            .notNullable();
        table.timestamp('updatedAt', { useTz: false })
            .defaultTo(knex.fn.now())
            .notNullable();
        table.timestamp('deletedAt', { useTz: false })
            .nullable();  // Soft delete support

        // Foreign keys
        table.foreign('userId')
            .references('id')
            .inTable('users')
            .onDelete('CASCADE');

        // Indexes
        table.index('userId');
        table.index('isActive');
    });
}

export async function down(knex: Knex): Promise<void> {
    await knex.schema.dropTableIfExists(tableName);
}
```

#### 3. Run Migration

```bash
npm run migrate
```

#### 4. Rollback (If Needed)

```bash
# Rollback last batch
npx knex migrate:rollback --knexfile src/database/knexfile.ts

# Rollback all
npx knex migrate:rollback --all --knexfile src/database/knexfile.ts
```

### Migration Best Practices

1. **Always include up and down**:
   - `up()`: Apply changes
   - `down()`: Revert changes

2. **Use timestamps**:
   - `createdAt`, `updatedAt`, `deletedAt` (soft delete)

3. **Add indexes** for frequently queried columns:
   ```typescript
   table.index('userId');
   table.index(['tenantId', 'customerId']); // Composite index
   ```

4. **Foreign key constraints**:
   ```typescript
   table.foreign('commentId')
       .references('id')
       .inTable('comments')
       .onDelete('CASCADE');
   ```

5. **Test rollback** before deploying:
   ```bash
   npm run migrate      # Apply
   npm run rollback     # Revert
   npm run migrate      # Apply again
   ```

6. **Never modify existing migrations**:
   - Create new migration to alter tables
   - Keep migration history intact

### Migration Naming Convention

Format: `YYYYMMDDHHMMSS-description.ts`

Examples:
- `20200511074854-create-actions.ts` - Create table
- `20211014094959-change-reports-qlik-state-id-as-optional.ts` - Alter table
- `20211029120958-add-customerId.ts` - Add column
- `20211102164408-add-reporid-in-actions.ts` - Add column

## Schema Reference

### Core Tables

#### actions
Tracks user actions on comments (views, etc.)

```sql
CREATE TABLE actions (
    id SERIAL PRIMARY KEY,
    appUserId VARCHAR(255) NOT NULL,
    commentId INTEGER NOT NULL,
    reportId INTEGER,                    -- Added later
    viewedAt TIMESTAMP,
    createdAt TIMESTAMP DEFAULT NOW() NOT NULL,
    updatedAt TIMESTAMP DEFAULT NOW() NOT NULL,
    deletedAt TIMESTAMP
);
```

**Indexes**: `commentId`, `appUserId`

#### comments
Comment system for reports/visualizations

```sql
CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    appUserId VARCHAR(255) NOT NULL,
    text TEXT NOT NULL,
    reportId INTEGER,                    -- Added later
    createdAt TIMESTAMP DEFAULT NOW() NOT NULL,
    updatedAt TIMESTAMP DEFAULT NOW() NOT NULL,
    deletedAt TIMESTAMP
);
```

**Indexes**: `appUserId`, `reportId`

#### reactions
User reactions to comments (like, dislike, etc.)

```sql
CREATE TABLE reactions (
    id SERIAL PRIMARY KEY,
    appUserId VARCHAR(255) NOT NULL,
    commentId INTEGER NOT NULL,
    type VARCHAR(50) NOT NULL,           -- 'like', 'dislike', etc.
    createdAt TIMESTAMP DEFAULT NOW() NOT NULL,
    updatedAt TIMESTAMP DEFAULT NOW() NOT NULL,
    deletedAt TIMESTAMP,
    FOREIGN KEY (commentId) REFERENCES comments(id) ON DELETE CASCADE
);
```

**Indexes**: `commentId`, `appUserId`

#### visualizations
Qlik visualization metadata

```sql
CREATE TABLE visualizations (
    id SERIAL PRIMARY KEY,
    qlikId VARCHAR(255) NOT NULL,
    type VARCHAR(100),
    createdAt TIMESTAMP DEFAULT NOW() NOT NULL,
    updatedAt TIMESTAMP DEFAULT NOW() NOT NULL,
    deletedAt TIMESTAMP
);
```

#### qlik_states
Saved Qlik selection states

```sql
CREATE TABLE qlik_states (
    id SERIAL PRIMARY KEY,
    state TEXT NOT NULL,                 -- JSON string of Qlik state
    createdAt TIMESTAMP DEFAULT NOW() NOT NULL,
    updatedAt TIMESTAMP DEFAULT NOW() NOT NULL,
    deletedAt TIMESTAMP
);
```

#### app_user_preferences
User-specific application preferences

```sql
CREATE TABLE app_user_preferences (
    id SERIAL PRIMARY KEY,
    appUserId VARCHAR(255) NOT NULL,
    preferences JSONB,                   -- Flexible JSON preferences
    createdAt TIMESTAMP DEFAULT NOW() NOT NULL,
    updatedAt TIMESTAMP DEFAULT NOW() NOT NULL,
    deletedAt TIMESTAMP
);
```

**Indexes**: `appUserId`

#### feedbacks
User feedback collection

```sql
CREATE TABLE feedbacks (
    id SERIAL PRIMARY KEY,
    appUserId VARCHAR(255) NOT NULL,
    feedback TEXT NOT NULL,
    rating INTEGER,
    createdAt TIMESTAMP DEFAULT NOW() NOT NULL,
    updatedAt TIMESTAMP DEFAULT NOW() NOT NULL,
    deletedAt TIMESTAMP
);
```

### Analytics Tables

#### datasets
Dataset definitions for reports

```sql
CREATE TABLE datasets (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    customerId VARCHAR(255) NOT NULL,    -- Multi-tenant support
    dimensions JSONB,                    -- Qlik dimensions
    measures JSONB,                      -- Qlik measures
    filters JSONB,                       -- Qlik filters
    createdAt TIMESTAMP DEFAULT NOW() NOT NULL,
    updatedAt TIMESTAMP DEFAULT NOW() NOT NULL,
    deletedAt TIMESTAMP
);
```

**Indexes**: `customerId`, `name`

#### reports
Report configurations

```sql
CREATE TABLE reports (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    datasetId INTEGER,
    qlikStateId INTEGER,                 -- NULLABLE (optional)
    customerId VARCHAR(255) NOT NULL,
    isFavourite BOOLEAN DEFAULT FALSE,   -- User favorite flag
    createdAt TIMESTAMP DEFAULT NOW() NOT NULL,
    updatedAt TIMESTAMP DEFAULT NOW() NOT NULL,
    deletedAt TIMESTAMP,
    FOREIGN KEY (datasetId) REFERENCES datasets(id),
    FOREIGN KEY (qlikStateId) REFERENCES qlik_states(id)
);
```

**Indexes**: `customerId`, `datasetId`, `isFavourite`

#### users_reports
Many-to-many relationship between users and reports

```sql
CREATE TABLE users_reports (
    id SERIAL PRIMARY KEY,
    appUserId VARCHAR(255) NOT NULL,
    reportId INTEGER NOT NULL,
    createdAt TIMESTAMP DEFAULT NOW() NOT NULL,
    updatedAt TIMESTAMP DEFAULT NOW() NOT NULL,
    deletedAt TIMESTAMP,
    FOREIGN KEY (reportId) REFERENCES reports(id) ON DELETE CASCADE
);
```

**Indexes**: `appUserId`, `reportId`

#### pinwalls
Pinwall (collections) for organizing content

```sql
CREATE TABLE pinwalls (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    appUserId VARCHAR(255) NOT NULL,
    customerId VARCHAR(255) NOT NULL,
    isFavourite BOOLEAN DEFAULT FALSE,
    createdAt TIMESTAMP DEFAULT NOW() NOT NULL,
    updatedAt TIMESTAMP DEFAULT NOW() NOT NULL,
    deletedAt TIMESTAMP
);
```

**Indexes**: `appUserId`, `customerId`, `isFavourite`

#### pinwall_qlik_states
Qlik states associated with pinwalls

```sql
CREATE TABLE pinwall_qlik_states (
    id SERIAL PRIMARY KEY,
    pinwallId INTEGER NOT NULL,
    qlikStateId INTEGER NOT NULL,
    createdAt TIMESTAMP DEFAULT NOW() NOT NULL,
    updatedAt TIMESTAMP DEFAULT NOW() NOT NULL,
    deletedAt TIMESTAMP,
    FOREIGN KEY (pinwallId) REFERENCES pinwalls(id) ON DELETE CASCADE,
    FOREIGN KEY (qlikStateId) REFERENCES qlik_states(id) ON DELETE CASCADE
);
```

**Indexes**: `pinwallId`, `qlikStateId`

### Schema Diagram (ER Diagram)

```
┌─────────────┐
│   comments  │
│─────────────│
│ id (PK)     │
│ appUserId   │──┐
│ text        │  │
│ reportId    │──┼────┐
└─────────────┘  │    │
       │         │    │
       ▼         │    │
┌─────────────┐  │    │
│  reactions  │  │    │
│─────────────│  │    │
│ id (PK)     │  │    │
│ commentId   │──┘    │
│ appUserId   │       │
│ type        │       │
└─────────────┘       │
                      │
                      ▼
┌─────────────┐  ┌──────────┐
│   reports   │  │ datasets │
│─────────────│  │──────────│
│ id (PK)     │  │ id (PK)  │
│ name        │  │ name     │
│ datasetId   │──│ ...      │
│ qlikStateId │─┐└──────────┘
│ customerId  │ │
│ isFavourite │ │
└─────────────┘ │
       │        │
       ▼        │
┌──────────────┐│  ┌──────────────┐
│users_reports ││  │ qlik_states  │
│──────────────││  │──────────────│
│ appUserId    ││  │ id (PK)      │
│ reportId     ││  │ state (JSON) │
└──────────────┘│  └──────────────┘
                └────────┘
```

## Database Operations

### Connecting to Database

#### From Host Machine

```bash
# Using psql
psql -h localhost -p 5432 -U root -d pgdb
# Password: root

# Or specify password in connection string
PGPASSWORD=root psql -h localhost -p 5432 -U root -d pgdb
```

#### From Docker Container

```bash
docker-compose exec db psql -U root -d pgdb
```

#### Using GUI Client

**DBeaver / pgAdmin / TablePlus**:
- Host: `localhost`
- Port: `5432`
- Database: `pgdb`
- Username: `root`
- Password: `root`

### Common SQL Queries

#### List All Tables

```sql
SELECT tablename
FROM pg_catalog.pg_tables
WHERE schemaname = 'public';
```

#### Describe Table Structure

```sql
\d comments
-- or
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'comments';
```

#### Check Table Row Counts

```sql
SELECT
    schemaname,
    tablename,
    n_live_tup as row_count
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;
```

#### View Recent Comments

```sql
SELECT id, appUserId, text, reportId, createdAt
FROM comments
WHERE deletedAt IS NULL
ORDER BY createdAt DESC
LIMIT 10;
```

#### Find Soft-Deleted Records

```sql
SELECT COUNT(*)
FROM comments
WHERE deletedAt IS NOT NULL;
```

#### Active Reports by Customer

```sql
SELECT customerId, COUNT(*) as report_count
FROM reports
WHERE deletedAt IS NULL
GROUP BY customerId
ORDER BY report_count DESC;
```

### Database Maintenance

#### Vacuum (Reclaim Storage)

```sql
-- Vacuum all tables
VACUUM;

-- Vacuum specific table
VACUUM comments;

-- Full vacuum (more thorough, locks table)
VACUUM FULL;
```

#### Analyze (Update Statistics)

```sql
-- Analyze all tables
ANALYZE;

-- Analyze specific table
ANALYZE comments;
```

#### Reindex

```sql
-- Reindex specific table
REINDEX TABLE comments;

-- Reindex entire database
REINDEX DATABASE pgdb;
```

## Backup and Restore

### Backup Database

#### Full Database Backup

```bash
# From host machine
docker-compose exec db pg_dump -U root pgdb > backup_$(date +%Y%m%d_%H%M%S).sql

# Or with compression
docker-compose exec db pg_dump -U root pgdb | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

#### Backup Specific Tables

```bash
docker-compose exec db pg_dump -U root -t comments -t reactions pgdb > tables_backup.sql
```

#### Scheduled Backups (cron)

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * cd /path/to/db-siemens-dev && docker-compose exec -T db pg_dump -U root pgdb | gzip > /backups/db_$(date +\%Y\%m\%d).sql.gz
```

### Restore Database

#### Restore from Backup

```bash
# Stop services first
docker-compose down

# Start only database
docker-compose up -d db

# Wait for database to be ready
sleep 5

# Restore from backup
docker-compose exec -T db psql -U root pgdb < backup_20231201_140000.sql

# Or from compressed backup
gunzip -c backup_20231201_140000.sql.gz | docker-compose exec -T db psql -U root pgdb

# Restart all services
docker-compose up -d
```

#### Restore to New Database

```bash
# Create new database
docker-compose exec db psql -U root -c "CREATE DATABASE pgdb_restore;"

# Restore to new database
docker-compose exec -T db psql -U root pgdb_restore < backup.sql
```

### Export/Import CSV

#### Export Table to CSV

```sql
\copy comments TO '/tmp/comments.csv' WITH CSV HEADER;
```

```bash
# Or from command line
docker-compose exec db psql -U root -d pgdb -c "\copy comments TO '/tmp/comments.csv' WITH CSV HEADER"
```

#### Import CSV to Table

```sql
\copy comments FROM '/tmp/comments.csv' WITH CSV HEADER;
```

## Performance Optimization

### Index Optimization

#### Check Missing Indexes

```sql
-- Find tables without indexes on foreign keys
SELECT
    tc.table_name,
    kcu.column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE tablename = tc.table_name
    AND indexdef LIKE '%' || kcu.column_name || '%'
);
```

#### View Table Indexes

```sql
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'comments';
```

#### Create Index

```sql
-- Single column index
CREATE INDEX idx_comments_reportid ON comments(reportId);

-- Composite index
CREATE INDEX idx_reports_customer_date ON reports(customerId, createdAt);

-- Partial index (for common queries)
CREATE INDEX idx_active_reports ON reports(customerId)
WHERE deletedAt IS NULL;
```

### Query Performance

#### Explain Query Plan

```sql
EXPLAIN ANALYZE
SELECT c.*, r.name as report_name
FROM comments c
JOIN reports r ON c.reportId = r.id
WHERE c.deletedAt IS NULL
ORDER BY c.createdAt DESC
LIMIT 10;
```

#### Identify Slow Queries

```sql
-- Enable query logging in PostgreSQL config
-- Then check logs for slow queries

-- Or use pg_stat_statements extension
SELECT
    calls,
    total_time,
    mean_time,
    query
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

### Connection Pool Tuning

Configure in `sih-atellica-qplus-backend/.env` or knexfile:

```typescript
{
  pool: {
    min: 2,
    max: 10,
    acquireTimeoutMillis: 30000,
    idleTimeoutMillis: 30000
  }
}
```

## Troubleshooting

### Connection Issues

#### Error: "Connection refused"

**Cause**: Database container not running

**Solution**:
```bash
# Check if database is running
docker-compose ps db

# Start database
docker-compose up -d db

# Check logs
docker-compose logs db
```

#### Error: "Authentication failed"

**Cause**: Incorrect credentials

**Solution**:
```bash
# Check .env file matches docker-compose.yml
cat sih-atellica-qplus-backend/.env | grep DB_
cat docker-compose.yml | grep POSTGRES
```

### Migration Issues

#### Error: "Migration table locked"

**Cause**: Previous migration failed

**Solution**:
```sql
-- Connect to database
psql -h localhost -p 5432 -U root -d pgdb

-- Check lock status
SELECT * FROM pg_locks WHERE relation::regclass::text LIKE '%knex%';

-- Force unlock (if safe)
DELETE FROM knex_migrations_lock WHERE is_locked = 1;
```

#### Error: "Migration already exists"

**Cause**: Duplicate migration name

**Solution**:
Rename migration file with unique timestamp.

### Performance Issues

#### Slow Queries

**Diagnosis**:
```sql
-- Check table sizes
SELECT
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check for missing indexes
EXPLAIN ANALYZE [your slow query];
```

**Solution**:
- Add indexes on frequently queried columns
- Use pagination for large result sets
- Optimize JOIN operations

#### Out of Disk Space

**Check disk usage**:
```bash
docker system df
df -h ./data
```

**Clean up**:
```bash
# Remove old Docker volumes
docker volume prune

# Vacuum database
docker-compose exec db psql -U root -d pgdb -c "VACUUM FULL;"
```

### Data Issues

#### Orphaned Records

**Find orphaned comments** (reportId doesn't exist):
```sql
SELECT c.*
FROM comments c
LEFT JOIN reports r ON c.reportId = r.id
WHERE c.reportId IS NOT NULL AND r.id IS NULL;
```

**Fix**:
```sql
-- Option 1: Delete orphaned records
DELETE FROM comments
WHERE reportId NOT IN (SELECT id FROM reports WHERE deletedAt IS NULL)
AND reportId IS NOT NULL;

-- Option 2: Set to NULL
UPDATE comments
SET reportId = NULL
WHERE reportId NOT IN (SELECT id FROM reports WHERE deletedAt IS NULL);
```

---

For more information:
- [Development Guide](./DEVELOPMENT_GUIDE.md) - Development workflow
- [Configuration Guide](./CONFIGURATION_GUIDE.md) - Configuration reference
- [PostgreSQL Documentation](https://www.postgresql.org/docs/12/) - Official PostgreSQL docs

**Last Updated**: December 2025
