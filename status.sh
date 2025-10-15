#!/bin/bash

# Status Check Script for Ubuntu Server Setup
# This script checks the status of all installed services and configurations

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
    echo "║              Ubuntu Server Setup - Status Check              ║"
    echo "║                        Version 1.0.0                        ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check service status
check_service() {
    local service_name=$1
    local display_name=$2
    
    if systemctl is-active --quiet $service_name; then
        echo -e "  ${GREEN}✓${NC} $display_name: ${GREEN}Running${NC}"
    elif systemctl is-enabled --quiet $service_name; then
        echo -e "  ${YELLOW}⚠${NC} $display_name: ${YELLOW}Enabled but not running${NC}"
    else
        echo -e "  ${RED}✗${NC} $display_name: ${RED}Not installed/disabled${NC}"
    fi
}

# Check port status
check_port() {
    local port=$1
    local service_name=$2
    
    if netstat -tuln | grep -q ":$port "; then
        echo -e "  ${GREEN}✓${NC} $service_name (Port $port): ${GREEN}Listening${NC}"
    else
        echo -e "  ${RED}✗${NC} $service_name (Port $port): ${RED}Not listening${NC}"
    fi
}

# Check file existence
check_file() {
    local file_path=$1
    local description=$2
    
    if [[ -f "$file_path" ]]; then
        echo -e "  ${GREEN}✓${NC} $description: ${GREEN}Exists${NC}"
    else
        echo -e "  ${RED}✗${NC} $description: ${RED}Missing${NC}"
    fi
}

# Check directory existence
check_directory() {
    local dir_path=$1
    local description=$2
    
    if [[ -d "$dir_path" ]]; then
        echo -e "  ${GREEN}✓${NC} $description: ${GREEN}Exists${NC}"
    else
        echo -e "  ${RED}✗${NC} $description: ${RED}Missing${NC}"
    fi
}

# System information
show_system_info() {
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    System Information                      ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    
    echo -e "${WHITE}Hostname:${NC} $(hostname)"
    echo -e "${WHITE}OS:${NC} $(lsb_release -d | cut -f2)"
    echo -e "${WHITE}Kernel:${NC} $(uname -r)"
    echo -e "${WHITE}Architecture:${NC} $(uname -m)"
    echo -e "${WHITE}Uptime:${NC} $(uptime -p)"
    echo -e "${WHITE}Load Average:${NC} $(uptime | awk -F'load average:' '{print $2}')"
    echo -e "${WHITE}Memory Usage:${NC} $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
    echo -e "${WHITE}Disk Usage:${NC} $(df -h / | awk 'NR==2{printf "%.1f%%", $5}')"
    echo ""
}

# Service status
show_service_status() {
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    Service Status                          ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    
    # Web servers
    echo -e "${WHITE}Web Servers:${NC}"
    if systemctl is-active --quiet nginx; then
        echo -e "  ${GREEN}✓${NC} Nginx: Running (Port 80, 443)"
    else
        echo -e "  ${RED}✗${NC} Nginx: Not running"
    fi
    
    # Monitoring services
    echo -e "${WHITE}Monitoring Services:${NC}"
    check_service "netdata" "Netdata"
    check_service "prometheus" "Prometheus"
    check_service "node_exporter" "Node Exporter"
    echo ""
    
    # Docker
    echo -e "${WHITE}Container Services:${NC}"
    check_service "docker" "Docker"
    check_service "containerd" "Containerd"
    echo ""
}

# Port status
show_port_status() {
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    Port Status                             ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    
    check_port "22" "SSH"
    check_port "80" "HTTP"
    check_port "443" "HTTPS"
    check_port "9090" "Prometheus"
    check_port "9100" "Node Exporter"
    check_port "19999" "Netdata"
    check_port "3000" "Grafana"
    echo ""
}

# File and directory status
show_file_status() {
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    File Status                             ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    
    echo -e "${WHITE}Configuration Files:${NC}"
    check_file "/etc/nginx/nginx.conf" "Nginx Configuration"
    check_file "/etc/ssh/sshd_config" "SSH Configuration"
    echo ""
    
    echo -e "${WHITE}Directories:${NC}"
    check_directory "/var/log/server-setup" "Setup Logs"
    check_directory "/var/www/html" "Web Root"
    echo ""
}

# Docker status
show_docker_status() {
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    Docker Status                           ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    
    if command -v docker >/dev/null 2>&1; then
        echo -e "${WHITE}Docker Version:${NC} $(docker --version)"
        echo -e "${WHITE}Docker Compose Version:${NC} $(docker compose version)"
        echo -e "${WHITE}Running Containers:${NC} $(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | wc -l)"
        echo -e "${WHITE}Total Images:${NC} $(docker images | wc -l)"
        echo ""
        
        if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q .; then
            echo -e "${WHITE}Running Containers:${NC}"
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        else
            echo -e "${YELLOW}No containers are currently running${NC}"
        fi
    else
        echo -e "${RED}Docker is not installed${NC}"
    fi
    echo ""
}

# SSH status
show_ssh_status() {
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    SSH Status                              ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    
    # Check SSH service status
    if systemctl is-active --quiet ssh; then
        echo -e "${GREEN}✓ SSH Service: Running${NC}"
    else
        echo -e "${RED}✗ SSH Service: Not running${NC}"
    fi
    
    # Check SSH configuration
    echo -e "${WHITE}SSH Configuration:${NC}"
    if grep -q "PermitRootLogin no" /etc/ssh/sshd_config; then
        echo -e "  ${GREEN}✓${NC} Root login disabled"
    else
        echo -e "  ${RED}✗${NC} Root login enabled"
    fi
    
    if grep -q "PasswordAuthentication yes" /etc/ssh/sshd_config; then
        echo -e "  ${YELLOW}⚠${NC} Password authentication enabled"
    else
        echo -e "  ${GREEN}✓${NC} Password authentication disabled"
    fi
    
    # Check password policy
    if grep -q "PASS_MIN_LEN.*10" /etc/login.defs; then
        echo -e "  ${GREEN}✓${NC} Minimum password length: 10 characters"
    else
        echo -e "  ${RED}✗${NC} Password length policy not configured"
    fi
    echo ""
}

# Check Elasticsearch & Kibana
show_elasticsearch_status() {
    echo -e "${WHITE}Elasticsearch & Kibana:${NC}"
    if command -v docker >/dev/null 2>&1; then
        if docker ps --format "{{.Names}}" | grep -q elasticsearch; then
            echo -e "  ${GREEN}✓${NC} Elasticsearch: Running (Port 9200)"
        else
            echo -e "  ${RED}✗${NC} Elasticsearch: Not running"
        fi
        
        if docker ps --format "{{.Names}}" | grep -q kibana; then
            echo -e "  ${GREEN}✓${NC} Kibana: Running (Port 5601)"
        else
            echo -e "  ${RED}✗${NC} Kibana: Not running"
        fi
        
        if docker ps --format "{{.Names}}" | grep -q logstash; then
            echo -e "  ${GREEN}✓${NC} Logstash: Running"
        else
            echo -e "  ${RED}✗${NC} Logstash: Not running"
        fi
    else
        echo -e "  ${RED}✗${NC} Docker: Not installed"
    fi
}

# Main function
main() {
    print_banner
    
    show_system_info
    show_service_status
    show_port_status
    show_file_status
    show_docker_status
    show_ssh_status
    show_elasticsearch_status
    
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    Status Check Complete                    ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}For detailed logs, check:${NC}"
    echo -e "  • /var/log/server-setup/"
    echo -e "  • /var/log/nginx/"
    echo -e "  • /var/log/apache2/"
    echo ""
    echo -e "${WHITE}For configuration files, check:${NC}"
    echo -e "  • /etc/nginx/"
    echo -e "  • /etc/ssh/"
}

# Run main function
main "$@" 