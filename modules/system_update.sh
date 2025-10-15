#!/bin/bash

# System Update Module
# Handles Ubuntu system updates and basic package management

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
    echo "║                  System Update & Management                  ║"
    echo "║                        Version 1.0.0                        ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Logging functions
log() { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"; }
error_log() { echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"; }
warning_log() { echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"; }

# User input functions
get_user_input() {
    local prompt="$1"
    local default="$2"
    if [[ -n "$default" ]]; then
        echo -e "${YELLOW}$prompt${NC} [${CYAN}$default${NC}]: "
        read -r user_input
        echo "${user_input:-$default}"
    else
        echo -e "${YELLOW}$prompt${NC}: "
        read -r user_input
        echo "$user_input"
    fi
}

confirm_action() {
    local message="$1"
    echo -e "${YELLOW}$message${NC} (${CYAN}y/N${NC}): "
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

# Update package lists
update_package_lists() {
    log "Updating package lists..."
    if apt update; then
        log "Package lists updated successfully"
        return 0
    else
        error_log "Failed to update package lists"
        return 1
    fi
}

# Upgrade installed packages
upgrade_packages() {
    log "Upgrading installed packages..."
    if apt upgrade -y; then
        log "Packages upgraded successfully"
        return 0
    else
        error_log "Failed to upgrade packages"
        return 1
    fi
}

# Install essential packages
install_essential_packages() {
    local essential_packages=(
        "curl"
        "wget"
        "git"
        "vim"
        "nano"
        "htop"
        "rsync"
        "lsb_release"
        "net-tools"
    )
    
    log "Installing essential packages..."
    for package in "${essential_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            log "Installing $package..."
            if apt install -y "$package"; then
                log "$package installed successfully"
            else
                warning_log "Failed to install $package"
            fi
        else
            log "$package is already installed"
        fi
    done
}

# Configure automatic updates
configure_auto_updates() {
    log "Configuring automatic updates..."
    
    # Install unattended-upgrades if not present
    if ! dpkg -l | grep -q "^ii  unattended-upgrades "; then
        apt install -y unattended-upgrades
    fi
    
    # Enable unattended-upgrades
    dpkg-reconfigure -plow unattended-upgrades
    
    # Configure automatic reboot if needed
    if confirm_action "Do you want to enable automatic reboots for security updates?"; then
        echo 'Unattended-Upgrade::Automatic-Reboot "true";' >> /etc/apt/apt.conf.d/50unattended-upgrades
        echo 'Unattended-Upgrade::Automatic-Reboot-Time "02:00";' >> /etc/apt/apt.conf.d/50unattended-upgrades
        log "Automatic reboots enabled at 2:00 AM"
    fi
}

# Set up timezone
configure_timezone() {
    log "Configuring timezone..."
    
    # Get current timezone
    current_tz=$(timedatectl show --property=Timezone --value)
    echo -e "${WHITE}Current timezone:${NC} $current_tz"
    
    if confirm_action "Do you want to change the timezone?"; then
        # Show available timezones
        echo -e "${YELLOW}Available timezones (showing first 20):${NC}"
        timedatectl list-timezones | head -20
        
        new_tz=$(get_user_input "Enter timezone (e.g., America/New_York, Europe/London)")
        if [[ -n "$new_tz" ]]; then
            if timedatectl set-timezone "$new_tz"; then
                log "Timezone set to $new_tz"
            else
                error_log "Failed to set timezone to $new_tz"
            fi
        fi
    fi
}

# Configure hostname
configure_hostname() {
    log "Configuring hostname..."
    
    current_hostname=$(hostname)
    echo -e "${WHITE}Current hostname:${NC} $current_hostname"
    
    if confirm_action "Do you want to change the hostname?"; then
        new_hostname=$(get_user_input "Enter new hostname")
        if [[ -n "$new_hostname" ]]; then
            if hostnamectl set-hostname "$new_hostname"; then
                # Update /etc/hosts
                sed -i "s/127.0.1.1.*/127.0.1.1\t$new_hostname/" /etc/hosts
                log "Hostname set to $new_hostname"
                warning_log "Please reboot the system for hostname changes to take effect"
            else
                error_log "Failed to set hostname to $new_hostname"
            fi
        fi
    fi
}

# Clean up package cache
cleanup_packages() {
    log "Cleaning up package cache..."
    if apt autoremove -y && apt autoclean; then
        log "Package cache cleaned successfully"
        return 0
    else
        warning_log "Some cleanup operations failed"
        return 1
    fi
}

# Show system status
show_system_status() {
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    System Status Report                      ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    
    # System information
    echo -e "${WHITE}System Information:${NC}"
    echo -e "  OS: $(lsb_release -d | cut -f2)"
    echo -e "  Kernel: $(uname -r)"
    echo -e "  Hostname: $(hostname)"
    echo -e "  Timezone: $(timedatectl show --property=Timezone --value)"
    
    # Package information
    echo -e "\n${WHITE}Package Information:${NC}"
    echo -e "  Total packages: $(dpkg -l | wc -l)"
    echo -e "  Upgradable packages: $(apt list --upgradable 2>/dev/null | wc -l)"
    
    # System resources
    echo -e "\n${WHITE}System Resources:${NC}"
    echo -e "  Memory: $(free -h | awk 'NR==2{printf "%.1f/%.1f GB", $3/1024, $2/1024}')"
    echo -e "  Disk Usage: $(df -h / | awk 'NR==2{printf "%s/%s (%s)", $3, $2, $5}')"
    echo -e "  Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    
    # Services status
    echo -e "\n${WHITE}Service Status:${NC}"
    echo -e "  SSH: $(systemctl is-active ssh)"
    echo -e "  UFW: $(systemctl is-active ufw)"
    echo -e "  Fail2ban: $(systemctl is-active fail2ban)"
    
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
}

# Main function
main() {
    print_banner
    
    echo -e "${CYAN}Starting System Updates & Basic Setup${NC}"
    echo ""
    
    # Update package lists
    if ! update_package_lists; then
        error_log "Failed to update package lists. Exiting."
        return 1
    fi
    
    # Upgrade packages
    if confirm_action "Do you want to upgrade all installed packages?"; then
        if ! upgrade_packages; then
            warning_log "Package upgrade failed, but continuing..."
        fi
    fi
    
    # Install essential packages
    if confirm_action "Do you want to install essential packages?"; then
        install_essential_packages
    fi
    
    # # Configure automatic updates
    # if confirm_action "Do you want to configure automatic security updates?"; then
    #     configure_auto_updates
    # fi
    
    # Configure timezone
    configure_timezone
    
    # Configure hostname
    configure_hostname
    
    # Clean up
    if confirm_action "Do you want to clean up package cache?"; then
        cleanup_packages
    fi
    
    # Show system status
    show_system_status
    
    echo ""
    log "System Updates & Basic Setup completed successfully"
    
    if confirm_action "Do you want to reboot the system now?"; then
        log "Rebooting system in 10 seconds..."
        sleep 10
        reboot
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 