# Quick Start: Local Development Setup

Minimal guide to get the project running locally.

---

## Prerequisites

| Platform | Requirements |
|----------|--------------|
| **Windows** | WSL2 with Ubuntu, Docker Desktop, Node.js 16.5.0 - 20.x |
| **macOS** | Docker Desktop, Node.js 16.5.0 - 20.x, Homebrew (recommended) |
| **Linux** | Docker, Docker Compose, Node.js 16.5.0 - 20.x |

---

## Step 1: Clone & Initialize

```bash
git clone <repository-url> ~/sih-atellica-root
cd ~/sih-atellica-root
git submodule update --init --remote
```

---

## Step 2: Setup Certificates

> **IMPORTANT**: The `certificates/` folder is **not included** in the repository and must be created manually.

Create the following structure in the project root:

```
sih-atellica-root/
 └── certificates/
     ├── qlik/           # Qlik Sense certificates
     │   ├── client.pem
     │   ├── client_key.pem
     │   ├── root.pem
     │   └── ...
     └── server/         # Server SSL certificates
         ├── server.crt
         ├── server.key
         └── server.pfx
```

**To obtain certificates:**
- **Qlik certificates**: Contact your team lead
- **Server certificates**: Either request from team lead OR generate using `mkcert`:
  ```bash
  # Install mkcert (macOS)
  brew install mkcert && mkcert -install

  # Generate certificates
  cd certificates/server
  mkcert -key-file server.key -cert-file server.crt local.databridge.ch localhost 127.0.0.1
  ```

> See [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md#5-ssl-certificate-setup-for-local-development) for detailed certificate setup.

---

## Step 3: Add Host Entry

The application requires a custom hostname. Add it to your hosts file.

### **macOS / Linux**

```bash
# Add host entry (requires sudo)
sudo sh -c 'echo "127.0.0.1 local.databridge.ch" >> /etc/hosts'
```

Or manually edit:

```bash
sudo nano /etc/hosts
```

Add this line at the end:
```
127.0.0.1 local.databridge.ch
```

Save: `Ctrl+O`, then `Enter`, then `Ctrl+X` to exit.

### **Windows (PowerShell - Run as Administrator)**

1. Press `Win` key, type `PowerShell`
2. **Right-click** → **Run as administrator**
3. Run:

```powershell
Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "`n127.0.0.1 local.databridge.ch"
```

### **Windows (Notepad - Alternative)**

1. Press `Win` key, type `Notepad`
2. **Right-click** → **Run as administrator**
3. File → Open → `C:\Windows\System32\drivers\etc\hosts`
4. Add this line at the end:
   ```
   127.0.0.1 local.databridge.ch
   ```
5. Save and close

### Verify (All Platforms)

```bash
ping local.databridge.ch
```

Should return `127.0.0.1`

---

## Step 4: Start Services

### Option A: Interactive Start (Recommended)

```bash
cd ~/sih-atellica-root
./start.sh
```

Choose from:
- **1) Local Mode** - Best for development (hot reload, debugging)
- **2) Docker Mode** - Backend in Docker, frontend local
- **3) Full Docker** - Everything in containers

Press `Ctrl+C` to stop all services.

Or use direct commands:
```bash
./start.sh local    # Local development
./start.sh docker   # Docker backend
./start.sh full     # Full Docker
```

To stop:
```bash
./stop.sh           # Interactive mode (default) - select individual services
./stop.sh all       # Stop everything
./stop.sh menu      # Show full menu with all options
```

### Option B: Manual Start (Multiple Terminals)

**Terminal 1: Database**
```bash
cd ~/sih-atellica-root
docker-compose up db -d
```

**Terminal 2: Qlik Service**
```bash
cd ~/sih-atellica-root/sih-atellica-qlik-service
npm install
npm run dev
```

**Terminal 3: Backend**
```bash
cd ~/sih-atellica-root/sih-atellica-qplus-backend
npm install
npm run dev
```

**Terminal 4: Frontend**
```bash
cd ~/sih-atellica-root/sih-atellica-qplus-frontend
yarn install
yarn start
```

---

## Step 5: Access Services

| Service | URL |
|---------|-----|
| Frontend | https://local.databridge.ch:7005 |
| Backend API | https://local.databridge.ch:3002/documentation |
| Qlik Service | https://local.databridge.ch:3001/documentation |

---

## Step 6: Qlik Authentication (IMPORTANT!)

**You MUST log in to Qlik BEFORE using the frontend application.**

### Why?

The application uses Qlik's session cookie for authentication:
1. You log in to Qlik Hub → Qlik sets a session cookie
2. Frontend sends this cookie to Backend with each request
3. Backend validates your identity with Qlik
4. **Without this cookie → "Unauthorized" errors**

### Steps

1. Open your browser and go to:
   ```
   https://qs-internal.databridge.ch/localhost/hub/my/work
   ```

2. Log in with your Windows/Qlik credentials

3. Verify cookie is set:
   - Open Developer Tools (F12)
   - Application → Cookies
   - Look for `X-Qlik-Session-localhost`

4. Now open the frontend:
   ```
   https://local.databridge.ch:7005
   ```

### Session Expired?

If you get "Unauthorized" errors, your Qlik session has expired. Just log in to Qlik Hub again.

---

## Troubleshooting

### Port already in use
```bash
lsof -i :3002  # Find process
kill -9 <PID>  # Kill it
```

### Database connection failed
```bash
docker-compose ps        # Check if db is running
docker-compose restart db
```

### Submodule errors
```bash
cd ~/sih-atellica-root/<submodule>
git remote set-head origin main
```

### Certificate warnings in browser
The included certificates should work automatically. If you see certificate warnings:
- Make sure you're accessing `https://local.databridge.ch:7005` (not `localhost`)
- Try accepting the certificate warning once
- See [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md#5-ssl-certificate-setup-for-local-development) for manual certificate setup

---

## Quick Reference

```bash
# Daily workflow - start services
./start.sh              # Interactive menu
./start.sh local        # Direct: local mode

# Stop services (interactive mode is default)
./stop.sh               # Interactive: select individual services to stop
./stop.sh all           # Direct: stop everything
./stop.sh local         # Direct: stop local mode services
./stop.sh menu          # Show full menu with all options

# View logs (while services are running)
tail -f logs/backend.log
tail -f logs/qlik-service.log
tail -f logs/frontend.log

# Quick Qlik login (open in browser)
open "https://qs-internal.databridge.ch/localhost/hub/my/work"  # macOS
xdg-open "https://qs-internal.databridge.ch/localhost/hub/my/work"  # Linux
start "https://qs-internal.databridge.ch/localhost/hub/my/work"  # Windows
```

### Stop Script - Interactive Mode

Running `./stop.sh` shows running services with status indicators:

```
Running services:

  Local Services:
    ● 1) Frontend (port 7005)
    ○ 2) Backend (port 3002)
    ● 3) Qlik Service (port 3001)

  Docker Containers:
    ● 4) Database
    ○ 5) Backend (Docker)

  ● = Running  ○ = Not running

Enter service numbers to stop (e.g., '1 2 4'):
```

- Enter numbers: `1 2 4` or `1,2,4`
- Enter `a` to stop all running services
- Enter `q` to quit

---

## TL;DR (After Initial Setup)

```bash
# 1. Login to Qlik first (in browser)
https://qs-internal.databridge.ch/localhost/hub/my/work

# 2. Start services
./start.sh local

# 3. Open frontend
https://local.databridge.ch:7005
```
