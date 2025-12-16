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

# Check if a service is running
is_service_running() {
    local port=$1
    local pid=$(lsof -ti :$port 2>/dev/null)
    [ ! -z "$pid" ]
}

is_docker_container_running() {
    local container=$1
    docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${container}$"
}

# Get running status indicator
get_status() {
    if [ "$1" = "true" ]; then
        echo -e "${GREEN}●${NC}"
    else
        echo -e "${RED}○${NC}"
    fi
}

# Interactive service selection
stop_interactive() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Interactive Service Stop${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""

    # Check which services are running
    local frontend_running=false
    local backend_running=false
    local qlik_running=false
    local db_running=false
    local docker_backend_running=false
    local docker_qlik_running=false
    local docker_frontend_running=false

    is_service_running 7005 && frontend_running=true
    is_service_running 3002 && backend_running=true
    is_service_running 3001 && qlik_running=true
    is_docker_container_running "sih-atellica-root-db-1" && db_running=true
    is_docker_container_running "sih-atellica-root-backend-1" && docker_backend_running=true
    is_docker_container_running "sih-atellica-root-qlik-service-1" && docker_qlik_running=true
    is_docker_container_running "sih-atellica-root-frontend-1" && docker_frontend_running=true

    echo -e "${CYAN}Running services:${NC}"
    echo ""
    echo -e "  ${YELLOW}Local Services:${NC}"
    echo -e "    $(get_status $frontend_running) 1) Frontend (port 7005)"
    echo -e "    $(get_status $backend_running) 2) Backend (port 3002)"
    echo -e "    $(get_status $qlik_running) 3) Qlik Service (port 3001)"
    echo ""
    echo -e "  ${YELLOW}Docker Containers:${NC}"
    echo -e "    $(get_status $db_running) 4) Database"
    echo -e "    $(get_status $docker_backend_running) 5) Backend (Docker)"
    echo -e "    $(get_status $docker_qlik_running) 6) Qlik Service (Docker)"
    echo -e "    $(get_status $docker_frontend_running) 7) Frontend (Docker)"
    echo ""
    echo -e "  ${GREEN}●${NC} = Running  ${RED}○${NC} = Not running"
    echo ""
    echo -e "  ${GREEN}a)${NC} Stop all running services"
    echo -e "  ${GREEN}q)${NC} Back to main menu"
    echo ""
    echo -e "Enter service numbers to stop (e.g., '1 2 4' or '1,2,4'):"
    read -p "> " selection

    if [ "$selection" = "q" ] || [ "$selection" = "Q" ]; then
        return
    fi

    if [ "$selection" = "a" ] || [ "$selection" = "A" ]; then
        echo ""
        [ "$frontend_running" = "true" ] && stop_service_on_port 7005 "Frontend (local)"
        [ "$backend_running" = "true" ] && stop_service_on_port 3002 "Backend (local)"
        [ "$qlik_running" = "true" ] && stop_service_on_port 3001 "Qlik Service (local)"
        [ "$db_running" = "true" ] && { cd "$ROOT_DIR"; docker-compose stop db 2>/dev/null && echo -e "${GREEN}Database stopped${NC}"; }
        [ "$docker_backend_running" = "true" ] && { docker stop sih-atellica-root-backend-1 2>/dev/null && echo -e "${GREEN}Backend (Docker) stopped${NC}"; }
        [ "$docker_qlik_running" = "true" ] && { docker stop sih-atellica-root-qlik-service-1 2>/dev/null && echo -e "${GREEN}Qlik Service (Docker) stopped${NC}"; }
        [ "$docker_frontend_running" = "true" ] && { docker stop sih-atellica-root-frontend-1 2>/dev/null && echo -e "${GREEN}Frontend (Docker) stopped${NC}"; }
        echo ""
        echo -e "${GREEN}Done!${NC}"
        return
    fi

    # Parse selection (handle both space and comma separated)
    selection=$(echo "$selection" | tr ',' ' ')

    echo ""
    for num in $selection; do
        case $num in
            1)
                if [ "$frontend_running" = "true" ]; then
                    stop_service_on_port 7005 "Frontend (local)"
                else
                    echo -e "Frontend (local) is not running"
                fi
                ;;
            2)
                if [ "$backend_running" = "true" ]; then
                    stop_service_on_port 3002 "Backend (local)"
                else
                    echo -e "Backend (local) is not running"
                fi
                ;;
            3)
                if [ "$qlik_running" = "true" ]; then
                    stop_service_on_port 3001 "Qlik Service (local)"
                else
                    echo -e "Qlik Service (local) is not running"
                fi
                ;;
            4)
                if [ "$db_running" = "true" ]; then
                    cd "$ROOT_DIR"
                    docker-compose stop db 2>/dev/null && echo -e "${GREEN}Database stopped${NC}"
                else
                    echo -e "Database is not running"
                fi
                ;;
            5)
                if [ "$docker_backend_running" = "true" ]; then
                    docker stop sih-atellica-root-backend-1 2>/dev/null && echo -e "${GREEN}Backend (Docker) stopped${NC}"
                else
                    echo -e "Backend (Docker) is not running"
                fi
                ;;
            6)
                if [ "$docker_qlik_running" = "true" ]; then
                    docker stop sih-atellica-root-qlik-service-1 2>/dev/null && echo -e "${GREEN}Qlik Service (Docker) stopped${NC}"
                else
                    echo -e "Qlik Service (Docker) is not running"
                fi
                ;;
            7)
                if [ "$docker_frontend_running" = "true" ]; then
                    docker stop sih-atellica-root-frontend-1 2>/dev/null && echo -e "${GREEN}Frontend (Docker) stopped${NC}"
                else
                    echo -e "Frontend (Docker) is not running"
                fi
                ;;
            *)
                echo -e "${RED}Invalid option: $num${NC}"
                ;;
        esac
    done

    echo ""
    echo -e "${GREEN}Done!${NC}"
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
    echo -e "  ${GREEN}5)${NC} Interactive mode"
    echo -e "     Select individual services to stop"
    echo ""
    echo -e "  ${GREEN}6)${NC} Exit"
    echo ""
}

# Main script
main() {
    # Check for command line argument
    if [ "$1" == "local" ]; then
        stop_local
        exit 0
    elif [ "$1" == "docker" ]; then
        stop_docker
        exit 0
    elif [ "$1" == "full" ] || [ "$1" == "full-docker" ]; then
        stop_full_docker
        exit 0
    elif [ "$1" == "all" ]; then
        stop_all
        exit 0
    elif [ "$1" == "menu" ] || [ "$1" == "-m" ]; then
        # Show menu mode
        show_menu
        while true; do
            read -p "Enter your choice [1-6]: " choice
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
                    echo ""
                    stop_interactive
                    break
                    ;;
                6)
                    echo -e "${GREEN}Goodbye!${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}Invalid option. Please enter 1-6.${NC}"
                    ;;
            esac
        done
        exit 0
    fi

    # Default: interactive mode
    stop_interactive
}

main "$@"
