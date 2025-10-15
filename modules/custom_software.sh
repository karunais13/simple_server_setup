#!/bin/bash

# Custom Software Module
# Handles installation of additional software packages and tools

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
    echo "║                Custom Software Installation                   ║"
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

# Install development tools
install_development_tools() {
    log "Installing development tools..."
    
    # Install common development packages
    apt install -y build-essential cmake pkg-config
    
    # Install version control tools
    apt install -y git subversion mercurial
    
    # Install programming languages
    apt install -y python3 python3-pip python3-venv
    apt install -y nodejs npm
    apt install -y golang-go
    
    # Install text editors
    apt install -y vim nano emacs
    
    # Install debugging tools
    apt install -y gdb valgrind strace ltrace
    
    log "Development tools installed"
}

# Install network tools
install_network_tools() {
    log "Installing network tools..."
    
    # Install network monitoring tools
    apt install -y nmap netcat-openbsd tcpdump wireshark
    
    # Install network utilities
    apt install -y traceroute mtr whois dig nslookup
    
    # Install network configuration tools
    apt install -y bridge-utils vlan iptables-persistent
    
    # Install VPN tools
    apt install -y openvpn strongswan
    
    log "Network tools installed"
}

# Install system administration tools
install_admin_tools() {
    log "Installing system administration tools..."
    
    # Install system monitoring
    apt install -y glances ncdu iotop htop
    
    # Install process management
    apt install -y supervisor systemd-cron
    
    # Install file management
    apt install -y mc ranger rsync
    
    # Install system information
    apt install -y inxi neofetch hwinfo
    
    # Install backup tools
    apt install -y rsnapshot duplicity
    
    log "System administration tools installed"
}

# Install multimedia tools
install_multimedia_tools() {
    log "Installing multimedia tools..."
    
    # Install media players
    apt install -y vlc mpv
    
    # Install image processing
    apt install -y imagemagick ffmpeg
    
    # Install audio tools
    apt install -y sox audacity
    
    # Install video tools
    apt install -y handbrake-cli mencoder
    
    log "Multimedia tools installed"
}

# Install office tools
install_office_tools() {
    log "Installing office tools..."
    
    # Install LibreOffice
    apt install -y libreoffice-writer libreoffice-calc libreoffice-impress
    
    # Install PDF tools
    apt install -y poppler-utils qpdf
    
    # Install document conversion
    apt install -y pandoc texlive
    
    log "Office tools installed"
}

# Install security tools
install_security_tools() {
    log "Installing security tools..."
    
    # Install security scanners
    apt install -y lynis chkrootkit
    
    # Install encryption tools
    apt install -y gpg openssl
    
    # Install password managers
    apt install -y pass keepassxc
    
    # Install network security
    apt install -y fail2ban ufw
    
    log "Security tools installed"
}

# Install cloud tools
install_cloud_tools() {
    log "Installing cloud tools..."
    
    # Install AWS CLI
    if ! command -v aws >/dev/null 2>&1; then
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        ./aws/install
        rm -rf aws awscliv2.zip
    fi
    
    # Install Azure CLI
    if ! command -v az >/dev/null 2>&1; then
        curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    fi
    
    # Install Google Cloud SDK
    if ! command -v gcloud >/dev/null 2>&1; then
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
        apt update && apt install -y google-cloud-sdk
    fi
    
    # Install Terraform
    if ! command -v terraform >/dev/null 2>&1; then
        wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
        apt update && apt install -y terraform
    fi
    
    log "Cloud tools installed"
}

# Install container tools
install_container_tools() {
    log "Installing container tools..."
    
    # Install Kubernetes tools
    if ! command -v kubectl >/dev/null 2>&1; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        mv kubectl /usr/local/bin/
    fi
    
    # Install Helm
    if ! command -v helm >/dev/null 2>&1; then
        curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz
        mv linux-amd64/helm /usr/local/bin/
        rm -rf linux-amd64
    fi
    
    # Install Docker Compose (if not already installed)
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    log "Container tools installed"
}

# Install monitoring tools
install_monitoring_tools() {
    log "Installing monitoring tools..."
    
    # Install Prometheus tools
    if ! command -v promtool >/dev/null 2>&1; then
        wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
        tar xvf prometheus-2.45.0.linux-amd64.tar.gz
        cp prometheus-2.45.0.linux-amd64/promtool /usr/local/bin/
        rm -rf prometheus-2.45.0.linux-amd64*
    fi
    
    # Install Grafana
    if ! command -v grafana-server >/dev/null 2>&1; then
        wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
        echo "deb https://packages.grafana.com/oss/deb stable main" | tee /etc/apt/sources.list.d/grafana.list
        apt update && apt install -y grafana
    fi
    
    # Install Alertmanager
    if ! command -v alertmanager >/dev/null 2>&1; then
        wget https://github.com/prometheus/alertmanager/releases/download/v0.26.0/alertmanager-0.26.0.linux-amd64.tar.gz
        tar xvf alertmanager-0.26.0.linux-amd64.tar.gz
        cp alertmanager-0.26.0.linux-amd64/alertmanager /usr/local/bin/
        rm -rf alertmanager-0.26.0.linux-amd64*
    fi
    
    log "Monitoring tools installed"
}

# Install custom package
install_custom_package() {
    local package_name="$1"
    
    log "Installing custom package: $package_name"
    
    case "$package_name" in
        "development")
            install_development_tools
            ;;
        "network")
            install_network_tools
            ;;
        "admin")
            install_admin_tools
            ;;
        "multimedia")
            install_multimedia_tools
            ;;
        "office")
            install_office_tools
            ;;
        "security")
            install_security_tools
            ;;
        "cloud")
            install_cloud_tools
            ;;
        "container")
            install_container_tools
            ;;
        "monitoring")
            install_monitoring_tools
            ;;
        *)
            # Try to install as a regular package
            if apt install -y "$package_name"; then
                log "Package $package_name installed successfully"
            else
                error_log "Failed to install package $package_name"
            fi
            ;;
    esac
}

# Show installed software
show_installed_software() {
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                Installed Software Status                     ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    
    # Development tools
    echo -e "${WHITE}Development Tools:${NC}"
    echo -e "  Git: $(git --version 2>/dev/null || echo 'Not installed')"
    echo -e "  Python: $(python3 --version 2>/dev/null || echo 'Not installed')"
    echo -e "  Node.js: $(node --version 2>/dev/null || echo 'Not installed')"
    echo -e "  Go: $(go version 2>/dev/null || echo 'Not installed')"
    
    # Network tools
    echo -e "\n${WHITE}Network Tools:${NC}"
    echo -e "  Nmap: $(nmap --version 2>/dev/null | head -1 || echo 'Not installed')"
    echo -e "  Wireshark: $(tshark --version 2>/dev/null | head -1 || echo 'Not installed')"
    echo -e "  OpenVPN: $(openvpn --version 2>/dev/null | head -1 || echo 'Not installed')"
    
    # Cloud tools
    echo -e "\n${WHITE}Cloud Tools:${NC}"
    echo -e "  AWS CLI: $(aws --version 2>/dev/null || echo 'Not installed')"
    echo -e "  Azure CLI: $(az version 2>/dev/null | head -1 || echo 'Not installed')"
    echo -e "  Google Cloud: $(gcloud version 2>/dev/null | head -1 || echo 'Not installed')"
    echo -e "  Terraform: $(terraform version 2>/dev/null | head -1 || echo 'Not installed')"
    
    # Container tools
    echo -e "\n${WHITE}Container Tools:${NC}"
    echo -e "  Docker: $(docker --version 2>/dev/null || echo 'Not installed')"
    echo -e "  Docker Compose: $(docker-compose --version 2>/dev/null || docker compose version 2>/dev/null | head -1 || echo 'Not installed')"
    echo -e "  kubectl: $(kubectl version --client 2>/dev/null | head -1 || echo 'Not installed')"
    echo -e "  Helm: $(helm version 2>/dev/null | head -1 || echo 'Not installed')"
    
    # Monitoring tools
    echo -e "\n${WHITE}Monitoring Tools:${NC}"
    echo -e "  Prometheus: $(prometheus --version 2>/dev/null | head -1 || echo 'Not installed')"
    echo -e "  Grafana: $(grafana-server --version 2>/dev/null | head -1 || echo 'Not installed')"
    echo -e "  Alertmanager: $(alertmanager --version 2>/dev/null | head -1 || echo 'Not installed')"
    
    # System tools
    echo -e "\n${WHITE}System Tools:${NC}"
    echo -e "  htop: $(which htop 2>/dev/null || echo 'Not installed')"
    echo -e "  glances: $(which glances 2>/dev/null || echo 'Not installed')"
    echo -e "  ncdu: $(which ncdu 2>/dev/null || echo 'Not installed')"
    
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
}

# Main function
main() {
    echo -e "${CYAN}Starting Custom Software Installation${NC}"
    echo ""
    
    # Show available categories
    echo -e "${WHITE}Available software categories:${NC}"
    echo -e "${CYAN}1.${NC} Development Tools (git, python, nodejs, go, etc.)"
    echo -e "${CYAN}2.${NC} Network Tools (nmap, wireshark, openvpn, etc.)"
    echo -e "${CYAN}3.${NC} System Administration Tools (htop, glances, etc.)"
    echo -e "${CYAN}4.${NC} Multimedia Tools (vlc, ffmpeg, imagemagick, etc.)"
    echo -e "${CYAN}5.${NC} Office Tools (libreoffice, pandoc, etc.)"
    echo -e "${CYAN}6.${NC} Security Tools (lynis, gpg, etc.)"
    echo -e "${CYAN}7.${NC} Cloud Tools (aws, azure, gcloud, terraform)"
    echo -e "${CYAN}8.${NC} Container Tools (kubectl, helm, docker-compose)"
    echo -e "${CYAN}9.${NC} Monitoring Tools (prometheus, grafana, alertmanager)"
    echo -e "${CYAN}10.${NC} Custom Package"
    echo ""
    
    # Install software by category
    while confirm_action "Do you want to install software from a category?"; do
        echo -e "${YELLOW}Enter category number (1-10) or package name:${NC}"
        read -r choice
        
        case "$choice" in
            1) install_development_tools ;;
            2) install_network_tools ;;
            3) install_admin_tools ;;
            4) install_multimedia_tools ;;
            5) install_office_tools ;;
            6) install_security_tools ;;
            7) install_cloud_tools ;;
            8) install_container_tools ;;
            9) install_monitoring_tools ;;
            10)
                local package_name=$(get_user_input "Enter package name")
                if [[ -n "$package_name" ]]; then
                    install_custom_package "$package_name"
                fi
                ;;
            *)
                # Try to install as a custom package
                install_custom_package "$choice"
                ;;
        esac
    done
    
    # Show status
    show_installed_software
    
    echo ""
    log "Custom Software Installation completed successfully"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    print_banner
    main "$@"
fi 