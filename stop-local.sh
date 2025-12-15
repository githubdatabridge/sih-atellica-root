#!/bin/bash

# SIH Atellica Local Development Stop Script
# Stops all services: Database, Qlik Service, Backend, Frontend

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stopping SIH Atellica services...${NC}"
echo ""

# Stop Node.js services by port
stop_service_on_port() {
    local port=$1
    local name=$2
    local pid=$(lsof -ti :$port 2>/dev/null)

    if [ ! -z "$pid" ]; then
        echo -e "Stopping $name (PID: $pid) on port $port..."
        kill $pid 2>/dev/null || true
        echo -e "${GREEN}$name stopped${NC}"
    else
        echo -e "$name not running on port $port"
    fi
}

# Stop services
stop_service_on_port 7005 "Frontend"
stop_service_on_port 3002 "Backend"
stop_service_on_port 3001 "Qlik Service"

# Stop database
echo ""
echo "Stopping Database..."
cd "$ROOT_DIR"
docker-compose stop db 2>/dev/null && echo -e "${GREEN}Database stopped${NC}" || echo "Database not running"

echo ""
echo -e "${GREEN}All services stopped.${NC}"
