# Local Development Setup Runbook

This guide walks you through setting up the project for local development with **PostgreSQL in Docker** and **all services running locally** (not in Docker containers).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1: Clone and Setup Repository](#step-1-clone-and-setup-repository)
- [Step 2: Start PostgreSQL Database](#step-2-start-postgresql-database)
- [Step 3: Setup and Run Qlik Service](#step-3-setup-and-run-qlik-service)
- [Step 4: Setup and Run QPlus Backend](#step-4-setup-and-run-qplus-backend)
- [Step 5: Setup and Run Frontend](#step-5-setup-and-run-frontend)
- [Step 6: Verify Setup](#step-6-verify-setup)
- [Debugging Services](#debugging-services)
- [Common Issues](#common-issues)
- [Daily Development Workflow](#daily-development-workflow)

---

## Prerequisites

### Required Software

- **Node.js**: v16.5.0 to v20.x
  ```bash
  node --version  # Should be 16.5.0 <= version < 21.0.0
  ```

- **NPM**: v9.0.0 or higher
  ```bash
  npm --version  # Should be >= 9.0.0
  ```

- **Docker & Docker Compose**: For PostgreSQL database
  ```bash
  docker --version
  docker-compose --version
  ```

- **Git**: v2.17.1 or higher
  ```bash
  git --version
  ```

### Recommended Tools

- **VS Code** with extensions:
  - ESLint
  - Prettier
  - TypeScript and JavaScript Language Features
- **PostgreSQL Client**: pgAdmin, DBeaver, or `psql` CLI
- **API Testing**: Postman or Insomnia

---

## Step 1: Clone and Setup Repository

### 1.1 Clone the Repository

```bash
cd ~/
git clone <repository-url> sih-atellica-root
cd sih-atellica-root
```

### 1.2 Initialize Git Submodules

This project uses submodules for each service:

```bash
git submodule update --init --remote
```

Verify submodules were cloned:

```bash
ls -la
# You should see:
# - sih-atellica-qlik-service/
# - sih-atellica-qplus-backend/
# - sih-atellica-qplus-frontend/
```

---

## Step 2: Start PostgreSQL Database

### 2.1 Start Only the Database Container

Instead of starting all services with `docker-compose up`, start only the database:

```bash
cd ~/sih-atellica-root
docker-compose up db -d
```

**Explanation:**
- `db` - Only starts the PostgreSQL container
- `-d` - Runs in detached mode (background)

### 2.2 Verify Database is Running

```bash
docker-compose ps
```

You should see:

```
NAME                           IMAGE           STATUS        PORTS
sih-atellica-root-db-1        postgres:12.8   Up            0.0.0.0:5432->5432/tcp
```

### 2.3 Connect to Database (Optional Verification)

```bash
# Using docker exec
docker-compose exec db psql -U root -d sih_qplus

# Or from your host (if you have psql installed)
psql -h localhost -p 5432 -U root -d sih_qplus
# Password: root
```

**Database Credentials:**
- Host: `localhost`
- Port: `5432`
- User: `root`
- Password: `root`
- Database: `sih_qplus`

### 2.4 Run Database Migrations

```bash
cd ~/sih-atellica-root/sih-atellica-qplus-backend

# Install dependencies if not already done
npm install

# Run migrations
npx knex migrate:latest --knexfile ./src/database/knexfile.ts
```

**Expected Output:**
```
Batch 1 run: 13 migrations
✅ Migrations completed successfully
```

---

## Step 3: Setup and Run Qlik Service

### 3.1 Navigate to Qlik Service Directory

```bash
cd ~/sih-atellica-root/sih-atellica-qlik-service
```

### 3.2 Install Dependencies

```bash
npm install
```

### 3.3 Configure Environment Variables

Check the `.env` file exists:

```bash
cat .env
```

**Required Configuration:**

```bash
PORT=3003
TITLE=SIH Qlik Service
TZ=Etc/Universal
QS_CERT_TYPE=pfx
QS_PFX_PATH=/path/to/your/qlik/client.pfx
APP_NAME=SihQlikService
LOG_TYPE=file
```

**Important:** Update `QS_PFX_PATH` to point to your Qlik certificate file.

### 3.4 Build the Service

```bash
npm run build
```

### 3.5 Start the Service

**Option A: Production Mode**
```bash
npm start
```

**Option B: Development Mode (Hot Reload)**
```bash
npm run dev
```

The service will be available at: **http://localhost:3003**

### 3.6 Verify Qlik Service

Open a new terminal and test:

```bash
curl http://localhost:3003/documentation
```

You should see the Swagger documentation page.

---

## Step 4: Setup and Run QPlus Backend

### 4.1 Navigate to Backend Directory

```bash
cd ~/sih-atellica-root/sih-atellica-qplus-backend
```

### 4.2 Install Dependencies

```bash
npm install
```

### 4.3 Configure Environment Variables

Verify the `.env` file:

```bash
cat .env
```

**Required Configuration:**

```bash
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=root
DB_PASS=root
DB_DATABASE=sih_qplus

# Qlik Service Configuration
QLIK_SERVICE_HOST=http://localhost
QLIK_SERVICE_PORT=3003

# Server Configuration
NODE_ENV=staging
PORT=3002
TITLE=Sih Qplus Backend
TZ=Etc/Universal
APP_NAME=SihQplusApi
LOG_TYPE=file

# Tenant Configuration
TENANT_FILE_PATH=./
DEFAULT_ROLES=user
DEFAULT_SCOPES=user:default,datasets:read
```

**Important Settings:**
- `DB_HOST=localhost` - Connects to Docker PostgreSQL
- `QLIK_SERVICE_PORT=3003` - Must match Qlik Service port
- `PORT=3002` - Backend API port

### 4.4 Verify Tenant Configuration File

Check that the tenant configuration file exists:

```bash
ls -la tenants.json
```

If missing, create a basic configuration:

```json
{
  "tenants": [
    {
      "tenant_id": "sih",
      "customer_id": "sih",
      "mashup_app_id": "qplus",
      "tenant_name": "sih",
      "qlik": {
        "hostname": "qs-internal.databridge.ch"
      }
    }
  ]
}
```

### 4.5 Build the Service

```bash
npm run build
```

### 4.6 Start the Backend

**Option A: Production Mode**
```bash
npm start
```

**Option B: Development Mode (Hot Reload)**
```bash
npm run watch
```

The service will be available at: **http://localhost:3002**

### 4.7 Verify Backend Service

Open a new terminal and test:

```bash
# Check Swagger documentation
curl http://localhost:3002/documentation

# Check health endpoint (if available)
curl http://localhost:3002/api/health
```

---

## Step 5: Setup and Run Frontend

### 5.1 Navigate to Frontend Directory

```bash
cd ~/sih-atellica-root/sih-atellica-qplus-frontend
```

### 5.2 Install Dependencies

```bash
npm install
# or
yarn install
```

### 5.3 Configure Environment Variables

Verify the `.env` file:

```bash
cat .env
```

**Required Configuration:**

```bash
VITE_QLIK_HOST_NAME=qs-internal.databridge.ch
VITE_TENANT_ID=sih
VITE_CUSTOMER_ID=sih
VITE_MASHUP_APP_ID=qplus
VITE_QPLUS_APP_API=http://localhost:3002
VITE_LOGIN_URL=https://qs-internal.databridge.ch/anonym/extensions/sh-mash-login/index.html
VITE_DEFAULT_THEME=qplus-sih-theme-light
VITE_QLIK_GLOBAL_EVENTS=closed,warning,error
VITE_QLIK_APP_EVENTS=closed,warning,error
VITE_INSIGHT_SOCKET_PATH=/socket.io
VITE_ROUTER=Hash
VITE_APP_VERSION=v1.0.0-beta.60

## Development config
PORT=7001
HTTPS=true
SKIP_PREFLIGHT_CHECK=true
FAST_REFRESH=true

## SSL_CERT
SSL_CRT_FILE=./cert/localhost.crt
SSL_KEY_FILE=./cert/localhost.key
```

**Important Settings:**
- `VITE_QPLUS_APP_API=http://localhost:3002` - Points to backend API
- `PORT=7001` - Frontend port
- `HTTPS=true` - Requires SSL certificates (see below)

### 5.4 Setup SSL Certificates (for HTTPS)

If `HTTPS=true`, you need certificates:

```bash
# Create cert directory
mkdir -p cert

# Option 1: Using OpenSSL (self-signed)
cd cert
openssl req -x509 -newkey rsa:2048 -keyout localhost.key -out localhost.crt -days 365 -nodes -subj "/CN=localhost"
cd ..

# Option 2: Using mkcert (trusted by browser)
# See DEVELOPMENT_GUIDE.md for mkcert setup
```

**Or disable HTTPS temporarily:**

Edit `.env`:
```bash
HTTPS=false
```

### 5.5 Configure Public Config Files

Update public configuration files to match `.env`:

```bash
# Copy config from .env to public configs
cat > public/config.json <<EOF
{
    "VITE_QLIK_HOST_NAME": "qs-internal.databridge.ch",
    "VITE_TENANT_ID": "sih",
    "VITE_CUSTOMER_ID": "sih",
    "VITE_MASHUP_APP_ID": "qplus",
    "VITE_INSIGHT_APP_API": "http://localhost:3002",
    "VITE_LOGIN_URL": "https://qs-internal.databridge.ch/anonym/extensions/sh-mash-login/index.html",
    "VITE_DEFAULT_THEME": "qplus-sih-theme-light",
    "VITE_QLIK_GLOBAL_EVENTS": "closed,warning,error",
    "VITE_QLIK_APP_EVENTS": "closed,warning,error",
    "VITE_INSIGHT_SOCKET_PATH": "/socket.io",
    "VITE_ROUTER": "Hash"
}
EOF
```

### 5.6 Setup Qlik Authentication Cookie (Critical for Local Development)

**IMPORTANT:** Before starting the frontend, you need to set up Qlik authentication cookies to work with localhost. In production, this isn't needed because the frontend and Qlik server share the same root domain. For local development, follow these steps:

#### Step 1: Enable Third-Party Cookies in Browser

**Chrome/Edge:**
1. Go to `chrome://settings/cookies` (or `edge://settings/cookies`)
2. Select **"Allow all cookies"** or **"Block third-party cookies in Incognito"**
3. Make sure third-party cookies are **NOT blocked**

**Firefox:**
1. Go to `about:preferences#privacy`
2. Under "Enhanced Tracking Protection", select **"Standard"** or **"Custom"**
3. Ensure "Cookies" is not set to block all third-party cookies

#### Step 2: Login to Qlik Sense and Obtain Cookie

1. **Open your browser** and navigate to:
   ```
   https://qs-internal.databridge.ch/localhost/hub
   ```

2. **Login with your Qlik credentials**
   - You should see the Qlik Sense Hub

3. **Cookie will be set** by Qlik Sense server
   - The cookie domain will be `.qs-internal.databridge.ch`

#### Step 3: Modify Cookie Domain to localhost

1. **Open Browser Developer Tools:**
   - Press **F12** or **Right-click → Inspect**

2. **Navigate to Application/Storage tab:**
   - **Chrome/Edge**: Click on **"Application"** tab → **"Cookies"** → `https://qs-internal.databridge.ch`
   - **Firefox**: Click on **"Storage"** tab → **"Cookies"** → `https://qs-internal.databridge.ch`

3. **Find the Qlik authentication cookie:**
   - Look for cookies with names like:
     - `X-Qlik-Session-*`
     - `QlikTicket`
     - Or other Qlik-related session cookies

4. **Modify the cookie domain:**
   - **Chrome/Edge:**
     - Double-click on the **Domain** field of the cookie
     - Change from `.qs-internal.databridge.ch` to `localhost`
     - Press **Enter** to save

   - **Firefox:**
     - Right-click on the cookie → **"Edit"**
     - Change the **Domain** field to `localhost`
     - Click **"Save"**

5. **Verify the change:**
   - The cookie should now appear under `localhost` domain
   - The value and expiration should remain the same

#### Step 4: Important Notes

**Why is this needed?**
- Qlik cookies are set for the Qlik server domain (qs-internal.databridge.ch)
- Your localhost frontend needs to send these cookies to the backend
- Browsers won't send cookies cross-domain unless manually adjusted
- In production, this problem doesn't exist (same domain)

**Cookie Expiration:**
- If the cookie expires, repeat these steps
- Qlik session cookies typically last several hours
- You'll know it expired when the frontend shows authentication errors

**Security Note:**
- This is **only for local development**
- Never modify production cookies
- The modified cookie only works on your local machine

**Troubleshooting:**
- If cookies aren't visible, try refreshing the Qlik hub page
- Some browsers require you to delete the old cookie first before adding with new domain
- Make sure you're logged into Qlik before modifying cookies

### 5.7 Start the Frontend

```bash
# Using npm
npm start

# Using yarn
yarn start
```

The frontend will be available at:
- **HTTPS**: https://localhost:7001
- **HTTP**: http://localhost:7001

### 5.8 Verify Frontend

Open your browser and navigate to:
- https://localhost:7001 (or http://localhost:7001)

You should see the application login/landing page.

---

## Step 6: Verify Setup

### 6.1 Check All Services are Running

Open 4 terminal windows and verify:

**Terminal 1: PostgreSQL**
```bash
docker-compose ps
# STATUS should show "Up"
```

**Terminal 2: Qlik Service**
```bash
curl http://localhost:3003/documentation
# Should return Swagger HTML
```

**Terminal 3: Backend API**
```bash
curl http://localhost:3002/documentation
# Should return Swagger HTML
```

**Terminal 4: Frontend**
```bash
curl http://localhost:7001
# Should return HTML (or open in browser)
```

### 6.2 Test Full Stack Integration

**Test Backend → Database:**
```bash
curl http://localhost:3002/api/tenants
# Should return tenant data
```

**Test Backend → Qlik Service:**
```bash
curl http://localhost:3002/api/qlik/health
# Should return Qlik service health status
```

### 6.3 Service URLs Summary

| Service              | URL                                  | Swagger Docs                                |
|----------------------|--------------------------------------|---------------------------------------------|
| PostgreSQL Database  | `localhost:5432`                     | N/A                                         |
| Qlik Service         | http://localhost:3003                | http://localhost:3003/documentation         |
| QPlus Backend API    | http://localhost:3002                | http://localhost:3002/documentation         |
| Frontend             | https://localhost:7001               | N/A                                         |

---

## Debugging Services

### Debug QPlus Backend in VS Code

1. Open VS Code in the backend directory:
   ```bash
   cd ~/sih-atellica-root/sih-atellica-qplus-backend
   code .
   ```

2. Press **F5** or go to **Run and Debug** (Ctrl+Shift+D)

3. Select **"Debug with ts-node (Direct TypeScript)"**

4. Set breakpoints and start debugging

**Debug Configurations Available:**
- `Debug with ts-node (Direct TypeScript)` - Fastest, no build step
- `Debug Project (Compiled)` - Debugs compiled JavaScript

### Debug Qlik Service in VS Code

1. Open VS Code in the qlik service directory:
   ```bash
   cd ~/sih-atellica-root/sih-atellica-qlik-service
   code .
   ```

2. Press **F5** and select **"Debug Qlik Service with ts-node"**

### View Service Logs

**Qlik Service:**
```bash
cd ~/sih-atellica-root/sih-atellica-qlik-service
tail -f logs/core.log
```

**Backend API:**
```bash
cd ~/sih-atellica-root/sih-atellica-qplus-backend
tail -f logs/core.log
```

---

## Common Issues

### Issue 1: Port Already in Use

**Error:** `EADDRINUSE: address already in use :::3002`

**Solution:**

```bash
# Find process using the port
lsof -i :3002          # Mac/Linux
netstat -ano | grep 3002  # WSL

# Kill the process
kill -9 <PID>
```

### Issue 2: Database Connection Failed

**Error:** `connect ECONNREFUSED 127.0.0.1:5432`

**Solutions:**

1. **Verify database is running:**
   ```bash
   docker-compose ps
   ```

2. **Restart database:**
   ```bash
   docker-compose restart db
   ```

3. **Check `.env` file has correct credentials:**
   ```bash
   DB_HOST=localhost  # NOT 'db' for local development
   DB_PORT=5432
   DB_USER=root
   DB_PASS=root
   ```

### Issue 3: Migration Errors

**Error:** `Knex: run $ npm install pg`

**Solution:**
```bash
cd ~/sih-atellica-root/sih-atellica-qplus-backend
npm install pg
```

**Error:** `relation "table_name" does not exist`

**Solution:** Run migrations
```bash
npx knex migrate:latest --knexfile ./src/database/knexfile.ts
```

### Issue 4: Frontend CORS Errors

**Error:** `CORS policy: No 'Access-Control-Allow-Origin' header`

**Solutions:**

1. **Verify backend is running on correct port:**
   ```bash
   curl http://localhost:3002/documentation
   ```

2. **Check frontend `.env` has correct API URL:**
   ```bash
   VITE_QPLUS_APP_API=http://localhost:3002  # Should match backend PORT
   ```

3. **Restart frontend after .env changes:**
   ```bash
   # Stop frontend (Ctrl+C)
   yarn start
   ```

### Issue 5: SSL Certificate Errors

**Error:** `ERR_SSL_PROTOCOL_ERROR` or `Your connection is not private`

**Solutions:**

**Option A: Disable HTTPS (Quickest)**
```bash
# Edit .env
HTTPS=false
PORT=7001

# Restart frontend
```

**Option B: Accept Self-Signed Certificate**
- Click "Advanced" in browser
- Click "Proceed to localhost (unsafe)"

**Option C: Install Trusted Certificates**
- See frontend SSL setup section above
- Use mkcert for trusted certificates

### Issue 6: Qlik Service Connection Failed

**Error:** Cannot connect to Qlik Sense Server

**Solutions:**

1. **Verify Qlik certificate path:**
   ```bash
   ls -la ~/sih-atellica-root/sih-atellica-qlik-service/certificates/qlik/
   # Should contain client.pfx
   ```

2. **Update `.env` with correct path:**
   ```bash
   QS_PFX_PATH=/full/path/to/client.pfx
   ```

3. **Verify Qlik server is accessible:**
   ```bash
   curl https://qs-internal.databridge.ch/hub
   ```

### Issue 7: TypeScript Compilation Errors

**Error:** `error TS2307: Cannot find module`

**Solution:**
```bash
cd <service-directory>
rm -rf node_modules build
npm install
npm run build
```

### Issue 8: Qlik Authentication Errors / Frontend Shows "Unauthorized"

**Error:** Frontend shows authentication errors, "Unauthorized", or fails to load Qlik content

**Common Symptoms:**
- Frontend loads but Qlik visualizations don't appear
- Console shows 401 Unauthorized errors
- "Session expired" messages
- Qlik API calls failing

**Root Cause:** Qlik authentication cookie is not set up correctly for localhost

**Solution:**

1. **Verify third-party cookies are enabled:**
   - Chrome/Edge: `chrome://settings/cookies` → Allow all cookies
   - Firefox: `about:preferences#privacy` → Standard protection

2. **Re-setup Qlik authentication cookie:**
   - Go to: https://qs-internal.databridge.ch/localhost/hub
   - Login with your credentials
   - Open Developer Tools (F12)
   - Go to **Application → Cookies** (Chrome/Edge) or **Storage → Cookies** (Firefox)
   - Find Qlik session cookies (X-Qlik-Session-*, QlikTicket)
   - **Change the domain from `.qs-internal.databridge.ch` to `localhost`**

3. **Verify cookie was set correctly:**
   ```bash
   # In browser console, check cookies
   document.cookie
   ```
   - You should see Qlik-related cookies for localhost domain

4. **Check cookie expiration:**
   - Qlik cookies expire after several hours
   - If expired, repeat the cookie setup process (Step 2)

5. **Clear browser cache if needed:**
   ```bash
   # Or use browser: Ctrl+Shift+Delete
   ```

6. **Restart frontend:**
   ```bash
   cd ~/sih-atellica-root/sih-atellica-qplus-frontend
   # Stop with Ctrl+C
   yarn start
   ```

**Important:** This is a known limitation of local development with cross-domain cookies. In production environments, this issue doesn't occur because the frontend and Qlik server share the same root domain.

**See also:** Step 5.6 in the frontend setup section for detailed cookie setup instructions.

---

## Daily Development Workflow

### Starting Development (Every Day)

```bash
# 1. Start PostgreSQL
cd ~/sih-atellica-root
docker-compose up db -d

# 2. Start Qlik Service (Terminal 1)
cd ~/sih-atellica-root/sih-atellica-qlik-service
npm run dev

# 3. Start Backend API (Terminal 2)
cd ~/sih-atellica-root/sih-atellica-qplus-backend
npm run watch
```

**IMPORTANT: Before starting the frontend**, set up the Qlik authentication cookie if not done already or if expired:
1. Go to: https://qs-internal.databridge.ch/localhost/hub and login
2. Open Developer Tools (F12) → Application/Storage → Cookies
3. Change Qlik cookie domain from `.qs-internal.databridge.ch` to `localhost`
4. Verify third-party cookies are enabled in browser

(See Step 5.6 for detailed instructions)

```bash
# 4. Start Frontend (Terminal 3)
cd ~/sih-atellica-root/sih-atellica-qplus-frontend
yarn start
```

### Stopping Development

```bash
# Stop all node services: Ctrl+C in each terminal

# Stop PostgreSQL
docker-compose stop db

# Or stop and remove database data
docker-compose down -v
```

### Making Code Changes

**Backend Changes:**
- Services auto-reload with `npm run dev` or `npm run watch`
- No manual restart needed

**Frontend Changes:**
- Vite hot-reloads automatically
- Browser refreshes automatically

**Database Schema Changes:**
1. Create migration:
   ```bash
   cd ~/sih-atellica-root/sih-atellica-qplus-backend
   npm run migration:make -- descriptive_name
   ```

2. Edit migration file in `src/database/migrations/`

3. Run migration:
   ```bash
   npx knex migrate:latest --knexfile ./src/database/knexfile.ts
   ```

### Testing Changes

**Manual API Testing:**
```bash
# Test endpoint
curl -X POST http://localhost:3002/api/bookmarks \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Bookmark","qsBookmarkId":"abc123"}'
```

**Using Postman:**
- Import collections from `sih-atellica-qplus-backend/tests/postman/`
- Update base URL to `http://localhost:3002`

---

## Additional Resources

- [Main README](../README.md) - Project overview and architecture
- [Development Guide](./DEVELOPMENT_GUIDE.md) - Comprehensive development documentation
- [Database Documentation](./DATABASE.md) - Database schema and migrations
- [Qlik Setup Guide](./QLIK_SETUP.md) - Qlik Sense integration details

---

## Quick Reference Commands

```bash
# Database
docker-compose up db -d              # Start PostgreSQL
docker-compose exec db psql -U root -d sih_qplus  # Connect to database
npx knex migrate:latest --knexfile ./src/database/knexfile.ts  # Run migrations

# Qlik Service
cd ~/sih-atellica-root/sih-atellica-qlik-service
npm run dev                          # Start with hot-reload
npm start                            # Start production mode

# Backend API
cd ~/sih-atellica-root/sih-atellica-qplus-backend
npm run watch                        # Start with hot-reload
npm start                            # Start production mode

# Frontend
cd ~/sih-atellica-root/sih-atellica-qplus-frontend
yarn start                           # Start development server
yarn build                           # Build for production

# Verify Services
curl http://localhost:3003/documentation  # Qlik Service Swagger
curl http://localhost:3002/documentation  # Backend API Swagger
curl http://localhost:7001                # Frontend
```

---

**Need Help?** Refer to individual service README files or contact the development team.
