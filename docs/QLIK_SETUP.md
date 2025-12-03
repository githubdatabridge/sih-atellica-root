# Qlik Sense Enterprise Setup Guide

Complete guide for setting up and integrating with Qlik Sense Enterprise Server for the SIH Atellica Connect Analytics Component.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Certificate Setup](#certificate-setup)
- [Qlik Management Console Configuration](#qlik-management-console-configuration)
- [Virtual Proxy Setup](#virtual-proxy-setup)
- [Testing Qlik Connection](#testing-qlik-connection)
- [Frontend Qlik Integration](#frontend-qlik-integration)
- [Backend Qlik Integration](#backend-qlik-integration)
- [Troubleshooting](#troubleshooting)

## Overview

The SIH Analytics platform integrates with Qlik Sense Enterprise in **two ways**:

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
         │             │                 │ (Capability API
         │             │                 │  WebSocket)
   ┌─────┴──┐          │            ┌────┴──────────┐
   │  Qlik  │          │            │   Frontend    │
   │ Service│◄─────────┘            │   (QPlus)     │
   │ (3001) │                       └───────────────┘
   └────────┘
```

**Two Integration Patterns**:

1. **Frontend → Qlik (Direct via Capability API)**:
   - WebSocket connection from browser to Qlik
   - Used for: Analytics visualizations, dashboards
   - Library: QPlus (@databridge/qplus)
   - Auth: Qlik session cookies

2. **Qlik Service → Qlik (Certificate-based)**:
   - REST API calls using certificates
   - Used for: Administrative operations (user sync, app management, tasks)
   - Libraries: qrs-interact, enigma.js
   - Auth: X.509 client certificates

## Prerequisites

### Required Access

- [ ] Access to Qlik Management Console (QMC)
- [ ] Administrator or RootAdmin role in Qlik
- [ ] Ability to export certificates
- [ ] Network access to Qlik server ports: 443, 4242, 4243
- [ ] VPN connection (if required by your organization)

### Qlik Server Information Needed

Collect the following information from your Qlik administrator:

| Information | Example | Where to Find |
|-------------|---------|---------------|
| Qlik Server Hostname | `qs-i-dev.databridge.ch` | Network admin or QMC |
| QIX Port (Engine) | `443` | QMC → Virtual Proxies |
| QRS Port (Repository) | `4242` | QMC → Virtual Proxies |
| QPS Port (Proxy) | `4243` | QMC → Virtual Proxies |
| Virtual Proxy Prefix | `insight` or `localhost` | QMC → Virtual Proxies |
| Service Account User ID | `sa_api` | QMC → Users |
| Service Account Directory | `INTERNAL` | QMC → Users |

## Certificate Setup

Qlik Service requires X.509 certificates to authenticate with Qlik Sense Enterprise.

### Certificate Types

Two options available:

1. **CA Certificates** (Recommended) - Separate files:
   - `root.pem` - Root CA certificate
   - `client.pem` - Client certificate
   - `client_key.pem` - Client private key

2. **PFX Certificate** - Single file:
   - `client.pfx` - Combined certificate with password

### Exporting Certificates from Qlik QMC

#### Step 1: Access Qlik Management Console

```bash
https://your-qlik-server/qmc
```

Log in with administrator credentials.

#### Step 2: Navigate to Certificates

1. Go to **QMC** → **Certificates**
2. Click **Export Certificates**

![QMC Certificates Section](https://help.qlik.com/en-US/sense-admin/images/certificates.png)

#### Step 3: Export Certificate Bundle

1. **Machine name**: Enter a meaningful name (e.g., `sih-analytics-service`)
2. **Certificate password**: Leave empty or set a password
3. **Include secret key**: ✅ Check this box
4. **Export format**: Choose based on your preference:
   - **Windows**: Select PFX
   - **Linux/Mac**: Select PEM (recommended)
5. Click **Export certificates**

#### Step 4: Download Certificate Files

A ZIP file will be downloaded containing:

**For PEM format**:
```
client.pem          # Client certificate
client_key.pem      # Private key
root.pem            # Root CA certificate
server.pem          # Server certificate (not needed)
server_key.pem      # Server key (not needed)
```

**For PFX format**:
```
client.pfx          # Combined certificate
```

### Installing Certificates in Qlik Service

#### Step 1: Create Certificates Directory

```bash
cd sih-atellica-qlik-service
mkdir -p src/certificates/qlik
```

#### Step 2: Copy Certificate Files

**For PEM format** (recommended):
```bash
# Copy certificates from downloaded ZIP to service directory
cp /path/to/downloaded/client.pem src/certificates/qlik/
cp /path/to/downloaded/client_key.pem src/certificates/qlik/
cp /path/to/downloaded/root.pem src/certificates/qlik/
```

**For PFX format**:
```bash
cp /path/to/downloaded/client.pfx src/certificates/qlik/
```

#### Step 3: Set Correct Permissions (Linux/Mac)

```bash
chmod 600 src/certificates/qlik/client_key.pem
chmod 644 src/certificates/qlik/client.pem
chmod 644 src/certificates/qlik/root.pem
```

#### Step 4: Configure Qlik Service .env

**For PEM certificates**:
```bash
QS_CERT_TYPE=ca
QS_CA_PATH=./src/certificates/qlik/root.pem
QS_KEY_PATH=./src/certificates/qlik/client_key.pem
QS_CERT_PATH=./src/certificates/qlik/client.pem
```

**For PFX certificate**:
```bash
QS_CERT_TYPE=pfx
QS_PFX_PATH=./src/certificates/qlik/client.pfx
QS_PFX_PASS=your-certificate-password
```

#### Step 5: Configure Service Account

```bash
QS_REPOSITORY_USER_ID=sa_repository
QS_REPOSITORY_USER_DIRECTORY=INTERNAL
QS_ENGINE_USER_ID=sa_api
QS_ENGINE_USER_DIRECTORY=INTERNAL
```

### Certificate Directory Structure

After setup, your directory should look like:

```
sih-atellica-qlik-service/
├── src/
│   └── certificates/
│       ├── qlik/
│       │   ├── client.pem
│       │   ├── client_key.pem
│       │   └── root.pem
│       └── server/          # Optional: for HTTPS server
│           ├── server.crt
│           └── server.key
├── .env
└── ...
```

## Qlik Management Console Configuration

### Creating Service Accounts

The application needs service accounts in Qlik for backend operations.

#### Step 1: Create Repository Service Account

1. **QMC** → **Users**
2. Click **Create new**
3. Fill in details:
   - **User ID**: `sa_repository`
   - **User directory**: `INTERNAL`
   - **Name**: `Repository Service Account`
4. Click **Apply**

#### Step 2: Create Engine API Service Account

1. **QMC** → **Users**
2. Click **Create new**
3. Fill in details:
   - **User ID**: `sa_api`
   - **User directory**: `INTERNAL`
   - **Name**: `Engine API Service Account`
4. Click **Apply**

#### Step 3: Assign Security Rules

**Create custom security rule** or modify existing:

1. **QMC** → **Security rules**
2. Find or create rule for service accounts
3. Add conditions:
   ```
   user.userId = "sa_api" AND user.userDirectory = "INTERNAL"
   user.userId = "sa_repository" AND user.userDirectory = "INTERNAL"
   ```
4. Grant permissions:
   - Read, Update, Create, Delete on Apps
   - Read on Streams
   - Execute on Tasks

## Virtual Proxy Setup

Virtual proxies enable authentication and routing for the frontend.

### Creating a Virtual Proxy

#### Step 1: Navigate to Virtual Proxies

1. **QMC** → **Virtual proxies**
2. Click **Create new**

#### Step 2: Configure Identification

- **Description**: `Insight Analytics Virtual Proxy`
- **Prefix**: `insight` (or `localhost` for dev)
- **Session cookie header name**: `X-Qlik-Session-Insight`

#### Step 3: Configure Authentication

**Authentication method**: Choose based on your setup

**Option A: Windows Authentication** (Most common):
- **Authentication method**: `Windows`
- **Windows authentication pattern**: Leave default
- **Allow login by session cookie**: ✅ Check

**Option B: Header Authentication** (SSO):
- **Authentication method**: `Header`
- **Header authentication header name**: `X-Authenticated-User`
- **Header authentication dynamic user directory**: Choose directory

#### Step 4: Configure Session Settings

- **Session inactivity timeout**: `30` minutes
- **Session timeout**: `480` minutes (8 hours)
- **Session cookie domain**: `.yourdomain.com`

#### Step 5: Configure Load Balancing

- **Load balancing nodes**: Select Qlik Sense Engine nodes
- **Add** all available nodes

#### Step 6: Configure CORS (Important!)

Add allowed origins for frontend:
```
https://localhost:7005
https://your-production-domain.com
```

**Websocket origin whitelist pattern**:
```
https://localhost:7005
https://*.yourdomain.com
```

#### Step 7: Associate with Proxy

1. **QMC** → **Proxies**
2. Select your proxy
3. **Virtual proxies**: Add the newly created virtual proxy
4. **Apply**

### Testing Virtual Proxy

Access Qlik Hub via virtual proxy:
```
https://qlik-server/insight/hub
```

Should redirect to login and show Qlik Hub.

## Testing Qlik Connection

### Test Backend Connection (Qlik Service)

#### Test 1: Qlik Service Health Check

```bash
curl http://localhost:3001/health
```

Expected: `{"status": "ok"}`

#### Test 2: QRS API Connection

From inside Qlik Service container:

```bash
# SSH into container
docker-compose exec sih-atellica-qlik-service sh

# Test QRS connection
curl -X GET "https://qlik-server:4242/qrs/about" \
  --cert /usr/src/app/src/certificates/qlik/client.pem \
  --key /usr/src/app/src/certificates/qlik/client_key.pem \
  --cacert /usr/src/app/src/certificates/qlik/root.pem \
  --header "X-Qlik-User: UserDirectory=INTERNAL;UserId=sa_repository"
```

Expected: JSON response with Qlik server information.

#### Test 3: Check Qlik Service Logs

```bash
docker-compose logs sih-atellica-qlik-service | grep -i "error\|certificate"
```

Should not show certificate errors.

### Test Frontend Connection (Capability API)

#### Test 1: Access Frontend

```
https://localhost:7005
```

Should load without errors.

#### Test 2: Check Browser Console

Open Developer Tools → Console

Look for:
- ✅ Qlik Capability API loaded
- ✅ WebSocket connection established
- ✅ Qlik apps loaded
- ❌ No CORS errors
- ❌ No authentication errors

#### Test 3: Verify Qlik Visualization

Navigate to Compliance/Audit/Reporting pages.

Should see Qlik visualizations render.

## Frontend Qlik Integration

The frontend connects directly to Qlik using the Capability API via QPlus library.

### Configuration Files

#### 1. Frontend .env

```bash
REACT_APP_QLIK_HOST_NAME=qs-i-dev.databridge.ch
REACT_APP_QLIK_VP=insight
REACT_APP_QLIK_QPS_ENDPOINT=https://qs-i-dev.databridge.ch
REACT_APP_QLIK_GLOBAL_EVENTS=closed,warning,error
REACT_APP_QLIK_APP_EVENTS=closed,warning,error
```

#### 2. startup.json

Location: `sih-atellica-qplus-frontend/src/app/json/startup.json`

```json
{
  "vp": "insight",
  "theme": "db-theme-siemens-light",
  "pages": [
    {
      "page": "compliance",
      "qlikAppId": "4e2d4117-f850-496b-8eb4-df1ff570c961"
    }
  ],
  "default": "compliance"
}
```

### Getting Qlik App IDs

#### Method 1: From QMC

1. **QMC** → **Apps**
2. Click on your app
3. Copy **App ID** (GUID) from URL or details pane

Example: `4e2d4117-f850-496b-8eb4-df1ff570c961`

#### Method 2: From Hub URL

When viewing app in Hub, URL contains app ID:
```
https://qlik-server/sense/app/4e2d4117-f850-496b-8eb4-df1ff570c961
                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

#### Method 3: Via QRS API

```bash
curl -X GET "https://qlik-server:4242/qrs/app/full" \
  --cert client.pem \
  --key client_key.pem \
  --cacert root.pem | jq '.[] | {name: .name, id: .id}'
```

### QPlus Configuration

QPlus library configuration in `qlikConfig.ts`:

```typescript
{
  qAuthMode: QplusAuthModeEnum.QES,         // Qlik Enterprise Server mode
  qApi: QplusApiEnum.CAPABILITY_API,        // Use Capability API
  qConfig: {
    host: hostname,                         // From REACT_APP_QLIK_HOST_NAME
    identity: qplusUtilService.generateIdendity(),
    prefix: virtualProxy                    // From startup.json vp
  },
  qTheme: theme,                            // From startup.json theme
  qApps: qlikApps                           // From startup.json pages
}
```

## Backend Qlik Integration

Backend uses Qlik Service for administrative operations.

### App API → Qlik Service Communication

App API calls Qlik Service via HTTP:

```typescript
// Example: User authentication with Qlik
await qlikService.auth(authHeader, {
  userInfo: {
    userDirectory: "Siemens",
    userId: "john.doe",
    attributes: [{ customerId: "customer1" }]
  },
  qsInfo: {
    ssl: false,
    vp: "insight",
    host: "qs-i-dev.databridge.ch",
    qrsPort: 4242,
    qpsPort: 4243
  }
});
```

### Qlik Service Operations

Common operations available:

| Operation | Endpoint | Purpose |
|-----------|----------|---------|
| User Auth | `POST /user/auth` | Authenticate user with Qlik |
| User Sync | `POST /user/sync` | Sync user properties |
| Integration Onboard | `POST /integration` | Onboard new customer |
| App Attach | `POST /app/attach` | Upload data file to app |
| Task Start | `POST /task/start` | Trigger reload task |
| Task Status | `POST /task/status` | Check task status |
| User List | `POST /user/list/{appId}` | Get users for app |
| Session End | `POST /user/{sessionId}/end` | End user session |

## Troubleshooting

### Certificate Issues

#### Error: "Certificate verification failed"

**Cause**: Incorrect certificate paths or corrupted certificates

**Solution**:
```bash
# Verify certificate files exist
ls -la sih-atellica-qlik-service/src/certificates/qlik/

# Check .env paths match actual files
cat sih-atellica-qlik-service/.env | grep QS_CERT

# Re-export certificates from QMC if needed
```

#### Error: "DEPTH_ZERO_SELF_SIGNED_CERT"

**Cause**: Node.js rejecting self-signed certificates

**Solution**:
```bash
# In sih-atellica-qlik-service/.env
NODE_TLS_REJECT_UNAUTHORIZED=0  # Development only!
```

**Production**: Get proper CA-signed certificates.

#### Error: "Certificate passphrase required"

**Cause**: Encrypted certificate without passphrase

**Solution**:
```bash
# In sih-atellica-qlik-service/.env
QLIK_CERT_PASSPHRASE=your-cert-password
```

### Connection Issues

#### Error: "ECONNREFUSED" on port 4242/4243

**Cause**: Cannot reach Qlik server

**Checklist**:
- [ ] VPN connected?
- [ ] Correct hostname in config?
- [ ] Firewall allows ports 4242, 4243, 443?
- [ ] Qlik server running?

```bash
# Test connectivity
ping qs-i-dev.databridge.ch
telnet qs-i-dev.databridge.ch 4242
```

#### Error: "Virtual proxy not found"

**Cause**: Virtual proxy prefix mismatch

**Solution**:
```bash
# Check virtual proxy in QMC
# Match prefix in:
# - Frontend .env: REACT_APP_QLIK_VP
# - startup.json: vp
# - Tenant config: (virtual proxy is in URL)
```

### Frontend Issues

#### Qlik visualizations not loading

**Check**:
1. Browser console for errors
2. Network tab for failed requests
3. Qlik app IDs are correct
4. User has access to apps in Qlik

```javascript
// Browser console should show:
// ✅ "Capability API loaded"
// ✅ "App opened successfully"
// ❌ No 403 Forbidden errors
```

#### CORS errors in browser

**Solution**:
Add frontend URL to Virtual Proxy **CORS whitelist**:
1. **QMC** → **Virtual proxies** → Your proxy
2. **Host white list**: Add `https://localhost:7005`
3. **Apply**

#### Session expired errors

**Solution**:
1. Check virtual proxy session timeout settings
2. Verify session cookie domain matches
3. Check browser cookie settings

### Backend Issues

#### Qlik Service cannot authenticate

**Check**:
```bash
# View Qlik Service logs
docker-compose logs sih-atellica-qlik-service

# Look for:
# - Certificate loading errors
# - Authentication failures
# - User directory/ID mismatches
```

**Verify**:
- Service account exists in Qlik (QMC → Users)
- Security rules grant access
- User directory and ID match exactly (case-sensitive)

#### Tasks not starting

**Cause**: Service account lacks task execution permission

**Solution**:
1. **QMC** → **Security rules**
2. Find rule for service accounts
3. Add **Execute** permission on **Tasks**
4. Apply

## Security Best Practices

### Certificate Management

1. **Store certificates securely**:
   - Never commit certificates to git
   - Use `.gitignore` for certificate directories
   - Store production certificates in secret management (Azure Key Vault, AWS Secrets Manager)

2. **Rotate certificates regularly**:
   - Export new certificates from QMC
   - Replace old certificates
   - Restart Qlik Service

3. **Use strong passwords**:
   - If using PFX, use strong passphrase
   - Store passphrase in environment variable

### Network Security

1. **Use VPN** for production Qlik access
2. **Restrict firewall** rules to specific IPs
3. **Enable TLS** for all connections in production
4. **Use HTTPS** for frontend

### Access Control

1. **Limit service account** permissions to minimum required
2. **Use separate accounts** for different environments (dev/staging/prod)
3. **Audit service account** usage regularly

---

For more information:
- [Configuration Guide](./CONFIGURATION_GUIDE.md) - Full configuration reference
- [Qlik Sense Help](https://help.qlik.com/en-US/sense-developer/) - Official Qlik documentation
- [Development Guide](./DEVELOPMENT_GUIDE.md) - Development workflow

**Last Updated**: December 2025
