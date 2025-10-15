#!/bin/bash

# Installation script for Ubuntu Server Setup Script
# This script prepares the environment for the main setup script

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
    echo "║           Ubuntu Server Setup Script Installer               ║"
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
    
    echo -e "${GREEN}Detected Ubuntu version: $VERSION${NC}"
}

# Install dependencies
install_dependencies() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    
    # Update package lists
    apt update
    
    # Install required packages
    apt install -y curl wget git unzip zip
    
    echo -e "${GREEN}Dependencies installed successfully${NC}"
}

# Set up directory structure
setup_directories() {
    echo -e "${YELLOW}Setting up directory structure...${NC}"
    
    # Create necessary directories
    mkdir -p /var/log/server-setup
    mkdir -p /var/backups
    mkdir -p /opt/server-setup
    
    # Set proper permissions
    chmod 755 /var/log/server-setup
    chmod 750 /var/backups
    
    echo -e "${GREEN}Directory structure created${NC}"
}

# Create configuration files
create_configs() {
    echo -e "${YELLOW}Creating configuration files...${NC}"
    
    # Create environment file
    cat > /opt/server-setup/.env << EOF
# Server Setup Configuration
SERVER_HOSTNAME=$(hostname)
ADMIN_EMAIL=admin@$(hostname)
DOMAIN_NAME=example.com
TIMEZONE=$(timedatectl show --property=Timezone --value)
EOF
    
    # Create log rotation configuration
    cat > /etc/logrotate.d/server-setup << EOF
/var/log/server-setup/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF
    
    echo -e "${GREEN}Configuration files created${NC}"
}

# Create systemd service (optional)
create_service() {
    echo -e "${YELLOW}Creating systemd service...${NC}"
    
    cat > /etc/systemd/system/server-setup.service << EOF
[Unit]
Description=Ubuntu Server Setup Script
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable server-setup.service
    
    echo -e "${GREEN}Systemd service created${NC}"
}

# Create desktop shortcut (if GUI is available)
create_desktop_shortcut() {
    if [[ -n "$DISPLAY" ]] && command -v xdg-desktop-menu >/dev/null 2>&1; then
        echo -e "${YELLOW}Creating desktop shortcut...${NC}"
        
        cat > /usr/share/applications/server-setup.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Server Setup
Comment=Ubuntu Server Setup Script
Exec=sudo /opt/server-setup/setup.sh
Icon=system-run
Terminal=true
Categories=System;Settings;
EOF
        
        echo -e "${GREEN}Desktop shortcut created${NC}"
    fi
}

# Show installation summary
show_summary() {
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    Installation Summary                      ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}Script Location:${NC} $(pwd)/setup.sh"
    echo -e "${WHITE}Log Directory:${NC} /var/log/server-setup"
    echo -e "${WHITE}Configuration:${NC} /opt/server-setup/.env"
    echo -e "${WHITE}Systemd Service:${NC} server-setup.service"
    echo ""
    echo -e "${WHITE}To run the setup script:${NC}"
    echo -e "  sudo ./setup.sh"
    echo ""
    echo -e "${WHITE}To run individual modules:${NC}"
    echo -e "  sudo ./modules/system_update.sh"
    echo -e "  sudo ./modules/user_management.sh"
    echo -e "  sudo ./modules/webserver.sh"
    echo -e "  sudo ./modules/monitoring.sh"
    echo -e "  sudo ./modules/docker.sh"
    echo -e "  sudo ./modules/custom_software.sh"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
}

# Main installation function
main() {
    print_banner
    
    echo -e "${WHITE}Welcome to the Ubuntu Server Setup Script Installer${NC}"
    echo ""
    
    # Check requirements
    check_root
    check_ubuntu
    
    echo ""
    echo -e "${YELLOW}This installer will:${NC}"
    echo -e "  • Install required dependencies"
    echo -e "  • Set up directory structure"
    echo -e "  • Create configuration files"
    echo -e "  • Create systemd service"
    echo -e "  • Create desktop shortcut (if GUI available)"
    echo ""
    
    read -p "Press Enter to continue or Ctrl+C to cancel..."
    
    # Run installation steps
    install_dependencies
    setup_directories
    create_configs
    create_service
    create_desktop_shortcut
    
    echo ""
    show_summary
    
    echo ""
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo -e "${YELLOW}You can now run the setup script with: sudo ./setup.sh${NC}"
}

# Run main function
main "$@" 