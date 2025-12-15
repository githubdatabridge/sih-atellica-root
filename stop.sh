#!/bin/bash

# SIH Atellica Development Stop Script
# Interactive script to stop local or Docker services

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Stop service on a specific port
stop_service_on_port() {
    local port=$1
    local name=$2
    local pid=$(lsof -ti :$port 2>/dev/null)

    if [ ! -z "$pid" ]; then
        echo -e "Stopping $name (PID: $pid) on port $port..."
        kill $pid 2>/dev/null || true
        sleep 1
        # Force kill if still running
        pid=$(lsof -ti :$port 2>/dev/null)
        if [ ! -z "$pid" ]; then
            kill -9 $pid 2>/dev/null || true
        fi
        echo -e "${GREEN}$name stopped${NC}"
    else
        echo -e "$name not running on port $port"
    fi
}

# Stop local services
stop_local() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Stopping LOCAL services${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""

    # Stop Node.js services
    echo -e "${YELLOW}Stopping Node.js services...${NC}"
    stop_service_on_port 7005 "Frontend"
    stop_service_on_port 3002 "Backend"
    stop_service_on_port 3001 "Qlik Service"
    echo ""

    # Stop database
    echo -e "${YELLOW}Stopping Database...${NC}"
    cd "$ROOT_DIR"
    docker-compose stop db 2>/dev/null && echo -e "${GREEN}Database stopped${NC}" || echo "Database not running"

    echo ""
    echo -e "${GREEN}All local services stopped.${NC}"
}

# Stop Docker services (backend only)
stop_docker() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Stopping DOCKER services (backend)${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""

    # Stop frontend if running locally
    echo -e "${YELLOW}Stopping Frontend (local)...${NC}"
    stop_service_on_port 7005 "Frontend"
    echo ""

    # Stop all Docker services
    echo -e "${YELLOW}Stopping Docker containers...${NC}"
    cd "$ROOT_DIR"
    docker-compose down

    echo ""
    echo -e "${GREEN}All Docker services stopped.${NC}"
}

# Stop Full Docker services (including frontend)
stop_full_docker() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Stopping FULL DOCKER services${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""

    # Stop all Docker services including frontend
    echo -e "${YELLOW}Stopping all Docker containers...${NC}"
    cd "$ROOT_DIR"
    docker-compose --profile full down

    echo ""
    echo -e "${GREEN}All Docker services stopped.${NC}"
}

# Stop all services (both modes)
stop_all() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Stopping ALL services${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""

    # Stop all Node.js services on ports
    echo -e "${YELLOW}Stopping all Node.js services...${NC}"
    stop_service_on_port 7005 "Frontend"
    stop_service_on_port 3002 "Backend"
    stop_service_on_port 3001 "Qlik Service"
    echo ""

    # Stop all Docker services (including full profile)
    echo -e "${YELLOW}Stopping all Docker containers...${NC}"
    cd "$ROOT_DIR"
    docker-compose --profile full down 2>/dev/null || true
    docker-compose down 2>/dev/null || true

    echo ""
    echo -e "${GREEN}All services stopped.${NC}"
}

# Main menu
show_menu() {
    clear
    echo -e "${CYAN}============================================${NC}"
    echo -e "${CYAN}     SIH Atellica - Stop Services${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo ""
    echo -e "Which services would you like to stop?"
    echo ""
    echo -e "  ${GREEN}1)${NC} Local Mode services"
    echo -e "     Stops npm processes and database container"
    echo ""
    echo -e "  ${GREEN}2)${NC} Docker Mode services (backend only)"
    echo -e "     Stops backend Docker containers + local frontend"
    echo ""
    echo -e "  ${GREEN}3)${NC} Full Docker Mode services"
    echo -e "     Stops all Docker containers including frontend"
    echo ""
    echo -e "  ${GREEN}4)${NC} All services"
    echo -e "     Stops everything (both local and Docker)"
    echo ""
    echo -e "  ${GREEN}5)${NC} Exit"
    echo ""
}

# Main script
main() {
    # Check for command line argument
    if [ "$1" == "local" ] || [ "$1" == "1" ]; then
        stop_local
        exit 0
    elif [ "$1" == "docker" ] || [ "$1" == "2" ]; then
        stop_docker
        exit 0
    elif [ "$1" == "full" ] || [ "$1" == "full-docker" ] || [ "$1" == "3" ]; then
        stop_full_docker
        exit 0
    elif [ "$1" == "all" ] || [ "$1" == "4" ]; then
        stop_all
        exit 0
    fi

    # Show interactive menu
    show_menu

    while true; do
        read -p "Enter your choice [1-5]: " choice
        case $choice in
            1)
                echo ""
                stop_local
                break
                ;;
            2)
                echo ""
                stop_docker
                break
                ;;
            3)
                echo ""
                stop_full_docker
                break
                ;;
            4)
                echo ""
                stop_all
                break
                ;;
            5)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please enter 1, 2, 3, 4, or 5.${NC}"
                ;;
        esac
    done
}

main "$@"
