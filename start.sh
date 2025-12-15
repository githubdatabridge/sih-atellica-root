#!/bin/bash

# SIH Atellica Development Startup Script
# Interactive script to choose between local or Docker deployment

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/logs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Create logs directory
mkdir -p "$LOG_DIR"

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

# Cleanup function for local mode
cleanup_local() {
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

# Cleanup function for docker mode
cleanup_docker() {
    echo ""
    echo -e "${YELLOW}Shutting down Docker services...${NC}"

    # Kill frontend if running locally
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi

    cd "$ROOT_DIR"
    docker-compose down

    echo -e "${GREEN}All services stopped.${NC}"
    exit 0
}

# Cleanup function for full docker mode
cleanup_full_docker() {
    echo ""
    echo -e "${YELLOW}Shutting down all Docker services...${NC}"

    cd "$ROOT_DIR"
    docker-compose --profile full down

    echo -e "${GREEN}All services stopped.${NC}"
    exit 0
}

# Start services locally (npm run dev)
start_local() {
    trap cleanup_local SIGINT SIGTERM

    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Starting in LOCAL mode${NC}"
    echo -e "${BLUE}  (Database in Docker, Services via npm)${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""

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

    print_success_message "LOCAL"

    # Keep script running and wait for Ctrl+C
    wait
}

# Start services in Docker containers
start_docker() {
    trap cleanup_docker SIGINT SIGTERM

    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Starting in DOCKER mode${NC}"
    echo -e "${BLUE}  (All backend services in containers)${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""

    # 1. Start all Docker services
    echo -e "${YELLOW}[1/2] Starting Docker services...${NC}"
    cd "$ROOT_DIR"
    docker-compose up -d

    # Wait for services to be ready
    echo "Waiting for services to be ready..."
    sleep 5

    # Wait for database
    echo "Checking Database..."
    until docker-compose exec -T db pg_isready -U root -d sih_qplus >/dev/null 2>&1; do
        sleep 1
    done
    echo -e "${GREEN}Database is ready on port 5432${NC}"

    # Wait for Qlik Service
    wait_for_port 3001 "Qlik Service"

    # Wait for Backend
    wait_for_port 3002 "Backend"
    echo ""

    # 2. Start Frontend locally (not in Docker for hot reload)
    echo -e "${YELLOW}[2/2] Starting Frontend locally...${NC}"
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

    print_success_message "DOCKER"

    # Keep script running and wait for Ctrl+C
    wait
}

# Start all services in Docker containers (including frontend)
start_full_docker() {
    trap cleanup_full_docker SIGINT SIGTERM

    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Starting in FULL DOCKER mode${NC}"
    echo -e "${BLUE}  (All services in containers)${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""

    # Start all Docker services including frontend
    echo -e "${YELLOW}Starting all Docker services...${NC}"
    cd "$ROOT_DIR"
    docker-compose --profile full up -d

    # Wait for services to be ready
    echo "Waiting for services to be ready..."
    sleep 5

    # Wait for database
    echo "Checking Database..."
    until docker-compose exec -T db pg_isready -U root -d sih_qplus >/dev/null 2>&1; do
        sleep 1
    done
    echo -e "${GREEN}Database is ready on port 5432${NC}"

    # Wait for Qlik Service
    wait_for_port 3001 "Qlik Service"

    # Wait for Backend
    wait_for_port 3002 "Backend"

    # Wait for Frontend
    wait_for_port 7005 "Frontend"
    echo ""

    print_success_message "FULL DOCKER"

    # Follow logs
    echo -e "${YELLOW}Following Docker logs (Ctrl+C to stop)...${NC}"
    docker-compose --profile full logs -f
}

# Print success message
print_success_message() {
    local mode=$1

    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  All services started successfully!${NC}"
    echo -e "${GREEN}  Mode: $mode${NC}"
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
}

# Main menu
show_menu() {
    clear
    echo -e "${CYAN}============================================${NC}"
    echo -e "${CYAN}     SIH Atellica - Development Setup${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo ""
    echo -e "How would you like to run the services?"
    echo ""
    echo -e "  ${GREEN}1)${NC} Local Mode"
    echo -e "     Database in Docker, services run via npm"
    echo -e "     ${YELLOW}Best for: debugging, hot reload, IDE integration${NC}"
    echo ""
    echo -e "  ${GREEN}2)${NC} Docker Mode (Backend only)"
    echo -e "     Backend services in Docker, frontend local"
    echo -e "     ${YELLOW}Best for: testing backend in containers with frontend hot reload${NC}"
    echo ""
    echo -e "  ${GREEN}3)${NC} Full Docker Mode"
    echo -e "     All services in Docker containers"
    echo -e "     ${YELLOW}Best for: testing production-like environment${NC}"
    echo ""
    echo -e "  ${GREEN}4)${NC} Exit"
    echo ""
}

# Main script
main() {
    # Check for command line argument
    if [ "$1" == "local" ] || [ "$1" == "1" ]; then
        start_local
        exit 0
    elif [ "$1" == "docker" ] || [ "$1" == "2" ]; then
        start_docker
        exit 0
    elif [ "$1" == "full" ] || [ "$1" == "full-docker" ] || [ "$1" == "3" ]; then
        start_full_docker
        exit 0
    fi

    # Show interactive menu
    show_menu

    while true; do
        read -p "Enter your choice [1-4]: " choice
        case $choice in
            1)
                echo ""
                start_local
                break
                ;;
            2)
                echo ""
                start_docker
                break
                ;;
            3)
                echo ""
                start_full_docker
                break
                ;;
            4)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please enter 1, 2, 3, or 4.${NC}"
                ;;
        esac
    done
}

main "$@"
