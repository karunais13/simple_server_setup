#!/bin/bash

# Quick Start Script for Ubuntu Server Setup
# This script provides a streamlined setup process

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Print banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              Ubuntu Server Setup - Quick Start               ║"
    echo "║                        Version 1.0.0                        ║"
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

# Quick setup function
quick_setup() {
    echo -e "${YELLOW}Starting quick setup...${NC}"
    echo ""
    
    # Run system update
    echo -e "${BLUE}1. Updating system...${NC}"
    ./modules/system_update.sh
    
    # Run user management
    echo -e "${BLUE}2. Setting up user management...${NC}"
    ./modules/user_management.sh
    
    # Run web server setup
    echo -e "${BLUE}3. Installing web server...${NC}"
    ./modules/webserver.sh
    
    # Run monitoring setup
    echo -e "${BLUE}4. Setting up monitoring...${NC}"
    ./modules/monitoring.sh
    
    echo ""
    echo -e "${GREEN}Quick setup completed!${NC}"
}

# Development setup function
dev_setup() {
    echo -e "${YELLOW}Starting development setup...${NC}"
    echo ""
    
    # Run quick setup first
    quick_setup
    
    # Add development tools
    echo -e "${BLUE}5. Installing development tools...${NC}"
    ./modules/custom_software.sh
    
    # Add Docker
    echo -e "${BLUE}6. Installing Docker...${NC}"
    ./modules/docker.sh
    
    echo ""
    echo -e "${GREEN}Development setup completed!${NC}"
}

# Production setup function
prod_setup() {
    echo -e "${YELLOW}Starting production setup...${NC}"
    echo ""
    
    # Run quick setup first
    quick_setup
    
    # Add Docker
    echo -e "${BLUE}5. Installing Docker...${NC}"
    ./modules/docker.sh
    
    echo ""
    echo -e "${GREEN}Production setup completed!${NC}"
}

# Show menu
show_menu() {
    echo -e "${WHITE}Choose your setup type:${NC}"
    echo ""
    echo -e "${CYAN}1.${NC} Quick Setup (Basic server with user management, web server, and monitoring)"
    echo -e "${CYAN}2.${NC} Development Setup (Quick + dev tools + Docker)"
    echo -e "${CYAN}3.${NC} Production Setup (Quick + Docker)"
    echo -e "${CYAN}4.${NC} Custom Setup (Interactive menu)"
    echo -e "${CYAN}5.${NC} Exit"
    echo ""
}

# Main function
main() {
    print_banner
    
    # Check requirements
    check_root
    
    echo -e "${WHITE}Welcome to the Ubuntu Server Setup Quick Start!${NC}"
    echo -e "${YELLOW}This script will help you quickly set up your Ubuntu server.${NC}"
    echo ""
    
    while true; do
        show_menu
        read -p "Enter your choice (1-5): " choice
        
        case $choice in
            1)
                quick_setup
                break
                ;;
            2)
                dev_setup
                break
                ;;
            3)
                prod_setup
                break
                ;;
            4)
                echo -e "${YELLOW}Launching interactive setup...${NC}"
                ./setup.sh
                break
                ;;
            5)
                echo -e "${YELLOW}Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter 1-5.${NC}"
                ;;
        esac
    done
    
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    Setup Summary                            ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}Your Ubuntu server has been configured successfully!${NC}"
    echo ""
    echo -e "${WHITE}Next steps:${NC}"
    echo -e "  • Review the configuration files in the config/ directory"
    echo -e "  • Check the logs in the logs/ directory"
    echo -e "  • Access your web server at http://$(hostname -I | awk '{print $1}')"
    echo -e "  • Monitor your system using the installed monitoring tools"
    echo ""
    echo -e "${WHITE}For more information, see the README.md file.${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
}

# Run main function
main "$@" 