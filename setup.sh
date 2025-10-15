#!/bin/bash

# Ubuntu Server Setup Script
# Interactive server setup and installation process

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Script version
VERSION="1.0.0"

# Log file
LOG_FILE="logs/setup_$(date +%Y%m%d_%H%M%S).log"

# Create logs directory if it doesn't exist
mkdir -p logs

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Print banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              Ubuntu Server Setup Script                      ║"
    echo "║                        Version $VERSION                        ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
        exit 1
    fi
}

# Check Ubuntu version
check_ubuntu() {
    if [[ ! -f /etc/os-release ]]; then
        echo -e "${RED}Error: This script is designed for Ubuntu systems${NC}"
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        echo -e "${RED}Error: This script is designed for Ubuntu systems${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Detected Ubuntu version: $VERSION_CODENAME $VERSION_ID${NC}"
}

# Create backup
create_backup() {
    echo -e "${YELLOW}Creating system backup...${NC}"
    mkdir -p backups
    tar -czf "backups/system_backup_$(date +%Y%m%d_%H%M%S).tar.gz" /etc /var/log 2>/dev/null || true
    echo -e "${GREEN}Backup created successfully${NC}"
}

# Execute module
execute_module() {
    local module_name=$1
    local module_file="modules/$module_name.sh"
    
    if [[ -f "$module_file" ]]; then
        echo -e "${YELLOW}Executing $module_name...${NC}"
        log_message "Starting module: $module_name"
        
        if bash "$module_file"; then
            echo -e "${GREEN}$module_name completed successfully${NC}"
            log_message "Module $module_name completed successfully"
        else
            echo -e "${RED}$module_name failed${NC}"
            log_message "Module $module_name failed"
        fi
    else
        echo -e "${RED}Module $module_name not found${NC}"
        log_message "Module $module_name not found"
    fi
}

# Show system info
show_system_info() {
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    System Information                      ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}Hostname:${NC} $(hostname)"
    echo -e "${WHITE}OS:${NC} $(lsb_release -d | cut -f2)"
    echo -e "${WHITE}Kernel:${NC} $(uname -r)"
    echo -e "${WHITE}Architecture:${NC} $(uname -m)"
    echo -e "${WHITE}Uptime:${NC} $(uptime -p)"
    echo -e "${WHITE}Memory:${NC} $(free -h | awk 'NR==2{printf "%s/%s", $3,$2 }')"
    echo -e "${WHITE}Disk Usage:${NC} $(df -h / | awk 'NR==2{printf "%s", $5}')"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Show main menu
show_menu() {
    echo -e "${WHITE}Main Menu - Choose an option:${NC}"
    echo ""
    echo -e "${CYAN}1.${NC} System Update & Essential Packages"
    echo -e "${CYAN}2.${NC} User Management & SSH Setup"
    echo -e "${CYAN}3.${NC} Web Server Setup (Nginx)"
    echo -e "${CYAN}4.${NC} Monitoring Tools Installation"
    echo -e "${CYAN}5.${NC} Docker & Container Management"
    echo -e "${CYAN}6.${NC} Elasticsearch & Kibana (Log Monitoring)"
    echo -e "${CYAN}7.${NC} Custom Software Installation"
    echo -e "${CYAN}8.${NC} Show System Information"
    echo -e "${CYAN}0.${NC} Exit"
    echo ""
}

# Main function
main() {
    print_banner
    
    # Check requirements
    check_root
    check_ubuntu
    
    # Create backup
    create_backup
    
    echo -e "${WHITE}Welcome to the Ubuntu Server Setup Script!${NC}"
    echo -e "${YELLOW}This script will help you configure your Ubuntu server.${NC}"
    echo ""
    
    while true; do
        show_menu
        read -p "Enter your choice (0-8): " choice
        
        case $choice in
            1)
                execute_module "system_update"
                ;;
            2)
                execute_module "user_management"
                ;;
            3)
                execute_module "webserver"
                ;;
            4)
                execute_module "monitoring"
                ;;
            5)
                execute_module "docker"
                ;;
            6)
                execute_module "elasticsearch"
                ;;
            7)
                execute_module "custom_software"
                ;;
            8)
                show_system_info
                ;;
            0)
                echo -e "${YELLOW}Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter 0-8.${NC}"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        echo ""
    done
}

# Run main function
main "$@" 