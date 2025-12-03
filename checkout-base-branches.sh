#!/bin/bash

# Script to checkout base branches for main repo and all submodules
# This ensures you're on the correct base branches for development

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Checking out base branches${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to checkout branch in a repo
checkout_branch() {
    local repo_path=$1
    local branch=$2
    local repo_name=$3

    echo -e "${YELLOW}Processing: ${repo_name}${NC}"

    cd "$repo_path"

    # Fetch latest from remote
    echo "  Fetching latest changes..."
    git fetch origin --quiet || {
        echo -e "  ${RED}✗ Failed to fetch from remote${NC}"
        return 1
    }

    # Check if branch exists locally
    if git show-ref --verify --quiet refs/heads/"$branch"; then
        echo "  Checking out existing local branch: $branch"
        git checkout "$branch" --quiet
    else
        # Check if branch exists on remote
        if git show-ref --verify --quiet refs/remotes/origin/"$branch"; then
            echo "  Creating local branch from remote: $branch"
            git checkout -b "$branch" origin/"$branch" --quiet
        else
            echo -e "  ${RED}✗ Branch '$branch' not found locally or on remote${NC}"
            return 1
        fi
    fi

    # Pull latest changes
    echo "  Pulling latest changes..."
    git pull origin "$branch" --quiet || {
        echo -e "  ${YELLOW}⚠ Could not pull (you may have local changes)${NC}"
    }

    # Show current status
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    echo -e "  ${GREEN}✓ On branch: $current_branch${NC}"
    echo ""
}

# Store the root directory
ROOT_DIR=$(pwd)

# 1. Checkout main branch in root repo
echo -e "${BLUE}1. Main Repository${NC}"
checkout_branch "$ROOT_DIR" "main" "sih-atellica-root"

# 2. Checkout base branches in submodules
echo -e "${BLUE}2. Submodule: sih-atellica-qlik-service${NC}"
if [ -d "$ROOT_DIR/sih-atellica-qlik-service" ]; then
    checkout_branch "$ROOT_DIR/sih-atellica-qlik-service" "main" "sih-atellica-qlik-service"
else
    echo -e "  ${RED}✗ Submodule directory not found. Run 'git submodule update --init' first${NC}"
    echo ""
fi

echo -e "${BLUE}3. Submodule: sih-atellica-qplus-backend${NC}"
if [ -d "$ROOT_DIR/sih-atellica-qplus-backend" ]; then
    checkout_branch "$ROOT_DIR/sih-atellica-qplus-backend" "main" "sih-atellica-qplus-backend"
else
    echo -e "  ${RED}✗ Submodule directory not found. Run 'git submodule update --init' first${NC}"
    echo ""
fi

echo -e "${BLUE}4. Submodule: sih-atellica-qplus-frontend${NC}"
if [ -d "$ROOT_DIR/sih-atellica-qplus-frontend" ]; then
    checkout_branch "$ROOT_DIR/sih-atellica-qplus-frontend" "main" "sih-atellica-qplus-frontend"
else
    echo -e "  ${RED}✗ Submodule directory not found. Run 'git submodule update --init' first${NC}"
    echo ""
fi

# Return to root directory
cd "$ROOT_DIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ All base branches checked out!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Summary:"
echo -e "  SIH Atellica Root:             ${GREEN}main${NC}"
echo -e "  SIH Atellica Qlik Service:     ${GREEN}main${NC}"
echo -e "  SIH Atellica Qplus Backend:    ${GREEN}main${NC} (includes migrations)"
echo -e "  SIH Atellica Qplus Frontend:   ${GREEN}main${NC}"
echo ""
echo -e "${YELLOW}Note: If you have uncommitted changes, they are preserved on their respective branches.${NC}"
