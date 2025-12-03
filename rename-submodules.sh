#!/bin/bash

# Script to rename submodule directories
# This automates the renaming process for the SIH Atellica naming convention

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Submodule Rename Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check for uncommitted changes
echo -e "${YELLOW}Step 1: Checking for uncommitted changes...${NC}"
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}✗ You have uncommitted changes in the root repository.${NC}"
    echo -e "${RED}  Please commit or stash your changes before renaming.${NC}"
    exit 1
fi

# Check submodules for uncommitted changes
echo -e "${YELLOW}Step 2: Checking submodules for uncommitted changes...${NC}"
for submodule in "sih-atellica-qlik-service" "sih-atellica-qplus-backend" "sih-atellica-qplus-frontend"; do
    if [ -d "$submodule" ]; then
        cd "$submodule"
        if ! git diff-index --quiet HEAD --; then
            echo -e "${RED}✗ Submodule '$submodule' has uncommitted changes.${NC}"
            echo -e "${RED}  Please commit or stash changes before renaming.${NC}"
            cd ..
            exit 1
        fi
        cd ..
    fi
done

echo -e "${GREEN}✓ No uncommitted changes detected${NC}"
echo ""

# Confirm with user
echo -e "${YELLOW}This script will rename:${NC}"
echo "  sih-atellica-qplus-backend        → sih-atellica-qplus-api"
echo "  sih-atellica-qlik-service           → sih-atellica-qlik-service"
echo "  sih-atellica-qplus-frontend  → sih-atellica-qplus-frontend"
echo ""
echo -e "${YELLOW}This will update:${NC}"
echo "  - .gitmodules"
echo "  - Git submodule configuration"
echo "  - docker-compose.yml"
echo "  - checkout-base-branches.sh"
echo "  - All documentation files"
echo ""
echo -e "${RED}WARNING: This is a significant change!${NC}"
echo -e "${RED}Team members will need to update their local clones.${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Rename cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Starting rename process...${NC}"
echo ""

# Step 3: Update .gitmodules
echo -e "${YELLOW}Step 3: Updating .gitmodules...${NC}"
sed -i 's|path = sih-atellica-qlik-service|path = sih-atellica-qlik-service|g' .gitmodules
sed -i 's|path = sih-atellica-qplus-backend|path = sih-atellica-qplus-api|g' .gitmodules
sed -i 's|path = sih-atellica-qplus-frontend|path = sih-atellica-qplus-frontend|g' .gitmodules
git add .gitmodules
echo -e "${GREEN}✓ .gitmodules updated${NC}"

# Step 4: Move submodule directories using git mv
echo -e "${YELLOW}Step 4: Moving submodule directories...${NC}"

if [ -d "sih-atellica-qlik-service" ]; then
    git mv sih-atellica-qlik-service sih-atellica-qlik-service
    echo -e "${GREEN}✓ Renamed sih-atellica-qlik-service → sih-atellica-qlik-service${NC}"
fi

if [ -d "sih-atellica-qplus-backend" ]; then
    git mv sih-atellica-qplus-backend sih-atellica-qplus-api
    echo -e "${GREEN}✓ Renamed sih-atellica-qplus-backend → sih-atellica-qplus-api${NC}"
fi

if [ -d "sih-atellica-qplus-frontend" ]; then
    git mv sih-atellica-qplus-frontend sih-atellica-qplus-frontend
    echo -e "${GREEN}✓ Renamed sih-atellica-qplus-frontend → sih-atellica-qplus-frontend${NC}"
fi

# Step 5: Update docker-compose.yml
echo -e "${YELLOW}Step 5: Updating docker-compose.yml...${NC}"
sed -i 's|sih-atellica-qlik-service|sih-atellica-qlik-service|g' docker-compose.yml
sed -i 's|sih-atellica-qplus-backend|sih-atellica-qplus-api|g' docker-compose.yml
git add docker-compose.yml
echo -e "${GREEN}✓ docker-compose.yml updated${NC}"

# Step 6: Update checkout-base-branches.sh
echo -e "${YELLOW}Step 6: Updating checkout-base-branches.sh...${NC}"
sed -i 's|sih-atellica-qlik-service|sih-atellica-qlik-service|g' checkout-base-branches.sh
sed -i 's|sih-atellica-qplus-backend|sih-atellica-qplus-api|g' checkout-base-branches.sh
sed -i 's|sih-atellica-qplus-frontend|sih-atellica-qplus-frontend|g' checkout-base-branches.sh
git add checkout-base-branches.sh
echo -e "${GREEN}✓ checkout-base-branches.sh updated${NC}"

# Step 7: Update README.md
echo -e "${YELLOW}Step 7: Updating README.md...${NC}"
sed -i 's|sih-atellica-qlik-service|sih-atellica-qlik-service|g' README.md
sed -i 's|sih-atellica-qplus-backend|sih-atellica-qplus-api|g' README.md
sed -i 's|sih-atellica-qplus-frontend|sih-atellica-qplus-frontend|g' README.md
git add README.md
echo -e "${GREEN}✓ README.md updated${NC}"

# Step 8: Update all docs
echo -e "${YELLOW}Step 8: Updating documentation files...${NC}"
for doc in docs/*.md; do
    if [ -f "$doc" ]; then
        sed -i 's|sih-atellica-qlik-service|sih-atellica-qlik-service|g' "$doc"
        sed -i 's|sih-atellica-qplus-backend|sih-atellica-qplus-api|g' "$doc"
        sed -i 's|sih-atellica-qplus-frontend|sih-atellica-qplus-frontend|g' "$doc"
        git add "$doc"
    fi
done
echo -e "${GREEN}✓ Documentation updated${NC}"

# Step 9: Show status
echo ""
echo -e "${YELLOW}Step 9: Reviewing changes...${NC}"
git status

# Step 10: Commit
echo ""
echo -e "${YELLOW}Step 10: Creating commit...${NC}"
git commit -m "refactor: rename submodule directories to sih-atellica naming convention

- Rename sih-atellica-qplus-backend → sih-atellica-qplus-api
- Rename sih-atellica-qlik-service → sih-atellica-qlik-service
- Rename sih-atellica-qplus-frontend → sih-atellica-qplus-frontend
- Update docker-compose.yml service names and paths
- Update documentation references
- Update helper scripts

🤖 Generated with Claude Code"

echo -e "${GREEN}✓ Changes committed${NC}"

# Final summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Rename completed successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the changes: git show HEAD"
echo "2. Push to remote: git push origin main"
echo "3. Notify team members to update their local clones"
echo "4. See docs/RENAMING_SUBMODULES.md for team member instructions"
echo ""
echo -e "${YELLOW}To verify:${NC}"
echo "  git submodule status"
echo "  ./checkout-base-branches.sh"
echo "  docker-compose up"
echo ""
