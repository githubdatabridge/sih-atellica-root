#!/bin/bash

# SIH Atellica Local Development Startup Script
# Starts all services: Database, Qlik Service, Backend, Frontend

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/logs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create logs directory
mkdir -p "$LOG_DIR"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  SIH Atellica - Local Development Setup${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Function to check if a port is in use
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to wait for a port to be available
wait_for_port() {
    local port=$1
    local service=$2
    local max_attempts=30
    local attempt=0

    while ! check_port $port; do
        attempt=$((attempt + 1))
        if [ $attempt -ge $max_attempts ]; then
            echo -e "${RED}Timeout waiting for $service on port $port${NC}"
            return 1
        fi
        sleep 1
    done
    echo -e "${GREEN}$service is ready on port $port${NC}"
}

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Shutting down services...${NC}"

    # Kill background processes
    if [ ! -z "$QLIK_PID" ]; then
        kill $QLIK_PID 2>/dev/null || true
    fi
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi

    # Stop database
    cd "$ROOT_DIR"
    docker-compose stop db 2>/dev/null || true

    echo -e "${GREEN}All services stopped.${NC}"
    exit 0
}

# Trap Ctrl+C
trap cleanup SIGINT SIGTERM

# 1. Start Database
echo -e "${YELLOW}[1/4] Starting Database...${NC}"
cd "$ROOT_DIR"
docker-compose up db -d

# Wait for database to be ready
echo "Waiting for PostgreSQL to be ready..."
sleep 3
until docker-compose exec -T db pg_isready -U root -d sih_qplus >/dev/null 2>&1; do
    sleep 1
done
echo -e "${GREEN}Database is ready on port 5432${NC}"
echo ""

# 2. Start Qlik Service
echo -e "${YELLOW}[2/4] Starting Qlik Service...${NC}"
cd "$ROOT_DIR/sih-atellica-qlik-service"

if [ ! -d "node_modules" ]; then
    echo "Installing Qlik Service dependencies..."
    npm install
fi

npm run dev > "$LOG_DIR/qlik-service.log" 2>&1 &
QLIK_PID=$!
echo "Qlik Service PID: $QLIK_PID"
wait_for_port 3001 "Qlik Service"
echo ""

# 3. Start Backend
echo -e "${YELLOW}[3/4] Starting Backend...${NC}"
cd "$ROOT_DIR/sih-atellica-qplus-backend"

if [ ! -d "node_modules" ]; then
    echo "Installing Backend dependencies..."
    npm install
fi

npm run dev > "$LOG_DIR/backend.log" 2>&1 &
BACKEND_PID=$!
echo "Backend PID: $BACKEND_PID"
wait_for_port 3002 "Backend"
echo ""

# 4. Start Frontend
echo -e "${YELLOW}[4/4] Starting Frontend...${NC}"
cd "$ROOT_DIR/sih-atellica-qplus-frontend"

if [ ! -d "node_modules" ]; then
    echo "Installing Frontend dependencies..."
    npm install
fi

npm start > "$LOG_DIR/frontend.log" 2>&1 &
FRONTEND_PID=$!
echo "Frontend PID: $FRONTEND_PID"
wait_for_port 7005 "Frontend"
echo ""

# Done
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  All services started successfully!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "Services:"
echo -e "  Frontend:     ${BLUE}https://local.databridge.ch:7005${NC}"
echo -e "  Backend API:  ${BLUE}https://local.databridge.ch:3002/documentation${NC}"
echo -e "  Qlik Service: ${BLUE}https://local.databridge.ch:3001/documentation${NC}"
echo ""
echo -e "Logs directory: ${YELLOW}$LOG_DIR${NC}"
echo -e "  - qlik-service.log"
echo -e "  - backend.log"
echo -e "  - frontend.log"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"
echo ""

# Keep script running and wait for Ctrl+C
wait
