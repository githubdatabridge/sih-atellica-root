# Renaming Submodule Directories

This guide explains how to rename the submodule directories to align with the new naming convention.

## Proposed Changes

| Current Name | New Name |
|--------------|----------|
| `sih-atellica-qplus-backend` | `sih-atellica-qplus-api` |
| `sih-atellica-qlik-service` | `sih-atellica-qlik-service` |
| `sih-atellica-qplus-frontend` | `sih-atellica-qplus-frontend` |

## Prerequisites

**IMPORTANT**: Before starting:
1. Commit and push any uncommitted changes in ALL repositories (root and submodules)
2. Ensure you're on the correct base branches (run `./checkout-base-branches.sh`)
3. Ensure all team members are aware of this change
4. Choose a maintenance window - this will require everyone to re-clone or update

## Manual Steps

### Step 1: Update .gitmodules

Edit `.gitmodules` to change the `path` field for each submodule:

```ini
[submodule "sih-atellica-qlik-service"]
    path = sih-atellica-qlik-service  # Changed from sih-atellica-qlik-service
    url = https://github.com/githubdatabridge/sih-atellica-qlik-service.git
    branch = siemens-develop
[submodule "sih-atellica-qplus-backend"]
    path = sih-atellica-qplus-api  # Changed from sih-atellica-qplus-backend
    url = https://github.com/githubdatabridge/sih-atellica-qplus-backend.git
    branch = siemens-develop
[submodule "sih-atellica-qplus-frontend"]
    path = sih-atellica-qplus-frontend  # Changed from sih-atellica-qplus-frontend
    url = https://github.com/githubdatabridge/sih-atellica-qplus-frontend
    branch = main
```

### Step 2: Update Git Configuration

```bash
# Stage the .gitmodules changes
git add .gitmodules

# Move each submodule to new location
git mv sih-atellica-qlik-service sih-atellica-qlik-service
git mv sih-atellica-qplus-backend sih-atellica-qplus-api
git mv sih-atellica-qplus-frontend sih-atellica-qplus-frontend
```

### Step 3: Update docker-compose.yml

Update all references in `docker-compose.yml`:

```yaml
services:
  sih-atellica-qlik-service:  # Renamed service
    build:
      context: "."
      dockerfile: "./sih-atellica-qlik-service/Dockerfile.dev"  # Updated path
    environment:
      - DB_HOST=db
    ports:
      - "3001:8080"
    depends_on:
      - db
    volumes:
      - ./sih-atellica-qlik-service:/usr/src/app  # Updated path
      - sih-atellica-qlik-service-node_modules:/usr/src/app/node_modules  # Updated volume

  sih-atellica-qplus-api:  # Renamed service
    build:
      context: "./sih-atellica-qplus-api/"  # Updated path
      dockerfile: "Dockerfile.dev"
    environment:
      - DB_HOST=db
    ports:
      - "3002:8080"
    depends_on:
      - db
    volumes:
      - ./sih-atellica-qplus-api:/usr/src/app  # Updated path
      - sih-atellica-qplus-api-node_modules:/usr/src/app/node_modules  # Updated volume

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

volumes:
  sih-atellica-qlik-service-node_modules:  # Updated volume name
  sih-atellica-qplus-api-node_modules:  # Updated volume name
```

### Step 4: Update checkout-base-branches.sh

Update the script to use new directory names:

```bash
# Change all occurrences:
# sih-atellica-qlik-service → sih-atellica-qlik-service
# sih-atellica-qplus-backend → sih-atellica-qplus-api
# sih-atellica-qplus-frontend → sih-atellica-qplus-frontend
```

### Step 5: Update Documentation

Update all documentation files in `docs/` directory:
- README.md
- PROJECT_OVERVIEW.md
- ARCHITECTURE.md
- DEVELOPMENT_GUIDE.md
- CONFIGURATION_GUIDE.md
- QLIK_SETUP.md
- DATABASE.md

Search and replace old directory names with new ones.

### Step 6: Update Environment File Paths

Update README.md sections that reference .env file paths:

```bash
# Old
cp sih-atellica-qplus-backend/.env.example sih-atellica-qplus-backend/.env
cp sih-atellica-qlik-service/.env.example sih-atellica-qlik-service/.env

# New
cp sih-atellica-qplus-api/.env.example sih-atellica-qplus-api/.env
cp sih-atellica-qlik-service/.env.example sih-atellica-qlik-service/.env
```

### Step 7: Commit Changes

```bash
# Stage all changes
git add .gitmodules docker-compose.yml checkout-base-branches.sh README.md docs/

# Commit the rename
git commit -m "refactor: rename submodule directories to sih-atellica naming convention

- Rename sih-atellica-qplus-backend → sih-atellica-qplus-api
- Rename sih-atellica-qlik-service → sih-atellica-qlik-service
- Rename sih-atellica-qplus-frontend → sih-atellica-qplus-frontend
- Update docker-compose.yml service names and paths
- Update documentation references
- Update helper scripts"

# Push changes
git push origin main
```

## For Team Members: Updating After Rename

After the rename is pushed, team members need to update their local repositories:

### Option 1: Fresh Clone (Recommended)

```bash
# Backup any uncommitted work
# Then delete and re-clone
cd ..
rm -rf db-siemens-dev
git clone --recurse-submodules <repository-url>
cd db-siemens-dev
./checkout-base-branches.sh
```

### Option 2: Update Existing Clone (Advanced)

```bash
# Commit or stash any local changes first
git stash

# Pull the changes
git pull origin main

# Sync submodules to new paths
git submodule sync
git submodule update --init --recursive

# Restore your changes
git stash pop
```

## Rollback (If Needed)

If something goes wrong:

```bash
# Revert the commit
git revert HEAD

# Or reset to previous state (WARNING: loses uncommitted changes)
git reset --hard HEAD~1

# Update submodules
git submodule sync
git submodule update --init --recursive
```

## Verification

After renaming, verify everything works:

```bash
# Check submodule status
git submodule status

# Check directory structure
ls -la

# Test Docker services
docker-compose up

# Run checkout script
./checkout-base-branches.sh
```

## Notes

- **Docker volumes**: Existing Docker volumes keep their old names and will be recreated with new names on first run
- **Submodule URLs**: URLs remain the same, only local directory paths change
- **Git history**: Git tracks the rename, so history is preserved
- **CI/CD pipelines**: May need updates if they reference old paths

## Impact Analysis

Files that will be updated:
- `.gitmodules` - Submodule path configuration
- `docker-compose.yml` - Service names, paths, volumes
- `checkout-base-branches.sh` - Directory references
- `README.md` - All directory references
- `docs/*.md` - All documentation files
- `.git/config` - Git's internal submodule config (handled by git mv)
- `.git/modules/` - Git's internal submodule data (handled by git mv)
