#!/bin/bash

# Docker & Containerization Module
# Installs Docker, Docker Compose, and container management tools

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
    echo "║                Docker & Containerization                     ║"
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

# Install Docker
install_docker() {
    echo -e "${YELLOW}Installing Docker...${NC}"
    
    # Update package lists
    apt update
    
    # Install required packages
    apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package lists
    apt update
    
    # Install Docker Engine
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Add current user to docker group
    usermod -aG docker $SUDO_USER
    
    echo -e "${GREEN}Docker installed successfully${NC}"
}

# Install Docker Compose
install_docker_compose() {
    echo -e "${YELLOW}Installing Docker Compose...${NC}"
    
    # Install Docker Compose v2 (included with Docker)
    if command -v docker compose >/dev/null 2>&1; then
        echo -e "${GREEN}Docker Compose v2 is already installed${NC}"
    else
        # Install Docker Compose v1 as fallback
        curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        echo -e "${GREEN}Docker Compose installed successfully${NC}"
    fi
}

# Configure Docker
configure_docker() {
    echo -e "${YELLOW}Configuring Docker...${NC}"
    
    # Create Docker daemon configuration
    mkdir -p /etc/docker
    
    cat > /etc/docker/daemon.json << EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "live-restore": true,
    "userland-proxy": false,
    "experimental": false
}
EOF
    
    # Restart Docker to apply configuration
    systemctl restart docker
    
    echo -e "${GREEN}Docker configured successfully${NC}"
}

# Install Portainer
install_portainer() {
    echo -e "${YELLOW}Installing Portainer...${NC}"
    
    echo -e "${WHITE}Choose Portainer installation type:${NC}"
    echo -e "${CYAN}1.${NC} Portainer CE (Standalone)"
    echo -e "${CYAN}2.${NC} Portainer Agent (For remote management)"
    echo ""
    
    read -p "Enter your choice (1-2): " portainer_choice
    
    case $portainer_choice in
        1)
            # Install Portainer CE
            docker volume create portainer_data
            docker run -d -p 8000:8000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
            echo -e "${GREEN}Portainer CE installed successfully${NC}"
            echo -e "${WHITE}Access Portainer at:${NC} https://$(hostname -I | awk '{print $1}'):9443"
            ;;
        2)
            # Install Portainer Agent
            docker volume create portainer_agent_data
            docker run -d -p 9001:9001 --name=portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes -v portainer_agent_data:/data portainer/agent:latest
            echo -e "${GREEN}Portainer Agent installed successfully${NC}"
            echo -e "${WHITE}Agent running on port:${NC} 9001"
            echo -e "${WHITE}Add this endpoint to your Portainer server:${NC} $(hostname -I | awk '{print $1}'):9001"
            ;;
        *)
            echo -e "${RED}Invalid choice. Installing Portainer CE.${NC}"
            docker volume create portainer_data
            docker run -d -p 8000:8000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
            echo -e "${GREEN}Portainer CE installed successfully${NC}"
            ;;
    esac
}

# Install Netdata
install_netdata() {
    echo -e "${YELLOW}Installing Netdata...${NC}"
    
    # Create Netdata directories
    mkdir -p /opt/netdata/{config,data,logs}
    
    # Create Netdata configuration
    cat > /opt/netdata/config/netdata.conf << EOF
[global]
    hostname = $(hostname)
    memory mode = dbengine
    page cache size = 256
    dbengine multihost disk space = 256
    # Log management - limit to 5GB
    log files max size = 5GB
    log files max number = 10
    log files max rotation = 10

[web]
    bind to = *

[plugins]
    python = yes
    node.d = yes
    go.d = yes

[python.d]
    # Enable Python plugins
    nginx = yes
    mysql = yes
    postgres = yes
    redis = yes
    docker = yes

[node.d]
    # Enable Node.js plugins
    nginx = yes
    mysql = yes
    postgres = yes
    redis = yes

[go.d]
    # Enable Go plugins
    nginx = yes
    mysql = yes
    postgres = yes
    redis = yes
    docker = yes

# Log monitoring configuration
[logs]
    # Enable log monitoring
    enabled = yes
    
    # System logs to monitor
    system_logs = yes
    auth_logs = yes
    kernel_logs = yes
    
    # Custom log paths
    log_files = 
        /var/log/syslog
        /var/log/auth.log
        /var/log/kern.log
        /var/log/dpkg.log
        /var/log/apt/history.log
        /var/log/monitoring/*.log
        /var/log/system-alerts/*.log
        /var/log/docker/*.log
        /var/log/nginx/*.log
        /var/log/apache2/*.log

# Database engine configuration for log storage
[db]
    # Limit database size to 5GB
    dbengine multihost disk space = 5GB
    page cache size = 512
    dbengine allocation = 512
    dbengine multihost disk space = 5GB
    dbengine multihost preload data cache max = 512
EOF
    
    # Create log monitoring configuration
    cat > /opt/netdata/config/go.d/logs.conf << EOF
# Log monitoring configuration
jobs:
  - name: system_logs
    type: logs
    update_every: 10
    log_files:
      - /var/log/syslog
      - /var/log/auth.log
      - /var/log/kern.log
    log_format: syslog
    exclude_patterns:
      - ".*netdata.*"
      - ".*CRON.*"
    
  - name: application_logs
    type: logs
    update_every: 10
    log_files:
      - /var/log/monitoring/*.log
      - /var/log/system-alerts/*.log
      - /var/log/docker/*.log
    log_format: json
    exclude_patterns:
      - ".*DEBUG.*"
      
  - name: web_server_logs
    type: logs
    update_every: 10
    log_files:
      - /var/log/nginx/*.log
      - /var/log/apache2/*.log
    log_format: nginx
    exclude_patterns:
      - ".*health.*"
      - ".*favicon.*"
EOF
    
    # Create Docker Compose file for Netdata
    cat > /opt/netdata/docker-compose.yml << EOF
version: '3.8'

services:
  netdata:
    image: netdata/netdata:latest
    container_name: netdata
    hostname: $(hostname)
    ports:
      - "19999:19999"
    volumes:
      - /opt/netdata/config:/etc/netdata:ro
      - /opt/netdata/data:/var/lib/netdata
      - /opt/netdata/logs:/var/log/netdata
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /etc/passwd:/host/etc/passwd:ro
      - /etc/group:/host/etc/group:ro
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      # Host logs for monitoring
      - /var/log:/host/var/log:ro
      - /var/log/syslog:/host/var/log/syslog:ro
      - /var/log/auth.log:/host/var/log/auth.log:ro
      - /var/log/kern.log:/host/var/log/kern.log:ro
      - /var/log/monitoring:/host/var/log/monitoring:ro
      - /var/log/system-alerts:/host/var/log/system-alerts:ro
      - /var/log/docker:/host/var/log/docker:ro
      - /var/log/nginx:/host/var/log/nginx:ro
      - /var/log/apache2:/host/var/log/apache2:ro
    environment:
      - NETDATA_HOST_IS_CONTAINER=0
      - NETDATA_HOST_PROC=/host/proc
      - NETDATA_HOST_SYS=/host/sys
      - NETDATA_HOST_ETC_PASSWD=/host/etc/passwd
      - NETDATA_HOST_ETC_GROUP=/host/etc/group
      - NETDATA_HOST_VAR_LOG=/host/var/log
      # Log management environment variables
      - NETDATA_LOG_FILES_MAX_SIZE=5GB
      - NETDATA_LOG_FILES_MAX_NUMBER=10
      - NETDATA_DBENGINE_MULTIHOST_DISK_SPACE=5GB
    restart: unless-stopped
    cap_add:
      - SYS_PTRACE
    security_opt:
      - apparmor:unconfined
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.netdata.rule=Host(\`netdata.local\`)"
EOF
    
    # Set proper permissions
    chown -R 201:201 /opt/netdata/data
    chown -R 201:201 /opt/netdata/logs
    
    # Create log directories if they don't exist
    mkdir -p /var/log/monitoring
    mkdir -p /var/log/system-alerts
    mkdir -p /var/log/docker
    
    # Set permissions for log access
    chmod 755 /var/log/monitoring
    chmod 755 /var/log/system-alerts
    chmod 755 /var/log/docker
    
    # Start Netdata
    cd /opt/netdata
    docker compose up -d
    
    echo -e "${GREEN}Netdata installed successfully${NC}"
    echo -e "${WHITE}Access Netdata at:${NC} http://$(hostname -I | awk '{print $1}'):19999"
    echo -e "${WHITE}Configuration directory:${NC} /opt/netdata/config"
    echo -e "${WHITE}Log monitoring enabled with 5GB limit${NC}"
    echo -e "${WHITE}Host logs will be displayed in Netdata dashboard${NC}"
}

# Create Docker Compose examples
create_docker_compose_examples() {
    echo -e "${YELLOW}Creating Docker Compose examples...${NC}"
    
    # Create examples directory
    mkdir -p /opt/docker-examples
    
    # Example 1: Simple web application
    cat > /opt/docker-examples/web-app.yml << EOF
version: '3.8'

services:
  webapp:
    image: nginx:alpine
    container_name: webapp
    ports:
      - "8080:80"
    volumes:
      - ./web:/usr/share/nginx/html
    restart: unless-stopped
    networks:
      - app-network

  redis:
    image: redis:alpine
    container_name: redis
    restart: unless-stopped
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
EOF
    
    # Example 2: Development environment
    cat > /opt/docker-examples/dev-env.yml << EOF
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: postgres-dev
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: developer
      POSTGRES_PASSWORD: devpassword
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:alpine
    container_name: redis-dev
    ports:
      - "6379:6379"
    restart: unless-stopped

volumes:
  postgres_data:
EOF
    
    # Example 3: Monitoring stack
    cat > /opt/docker-examples/monitoring.yml << EOF
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
EOF
    
    echo -e "${GREEN}Docker Compose examples created in /opt/docker-examples${NC}"
}

# Configure Docker security
configure_docker_security() {
    echo -e "${YELLOW}Configuring Docker security...${NC}"
    
    # Create Docker security configuration
    cat > /etc/docker/daemon.json << EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "5"
    },
    "storage-driver": "overlay2",
    "live-restore": true,
    "userland-proxy": false,
    "experimental": false,
    "no-new-privileges": true,
    "default-ulimits": {
        "nofile": {
            "Hard": 64000,
            "Name": "nofile",
            "Soft": 64000
        }
    },
    "log-level": "info",
    "max-concurrent-downloads": 10,
    "max-concurrent-uploads": 5,
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ]
}
EOF
    
    # Create logrotate configuration for Docker logs
    cat > /etc/logrotate.d/docker << EOF
/var/lib/docker/containers/*/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    copytruncate
    maxsize 100M
}
EOF
    
    # Restart Docker to apply security settings
    systemctl restart docker
    
    echo -e "${GREEN}Docker security configured successfully${NC}"
    echo -e "${WHITE}Docker logs limited to 100MB per container, 7 rotations${NC}"
}

# Show Docker status
show_docker_status() {
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    Docker Status                            ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    
    # Docker service status
    if systemctl is-active --quiet docker; then
        echo -e "${GREEN}✓ Docker Service: Running${NC}"
    else
        echo -e "${RED}✗ Docker Service: Not running${NC}"
    fi
    
    # Docker version
    if command -v docker >/dev/null 2>&1; then
        echo -e "${WHITE}Docker Version:${NC} $(docker --version)"
    fi
    
    # Docker Compose version
    if command -v docker-compose >/dev/null 2>&1; then
        echo -e "${WHITE}Docker Compose Version:${NC} $(docker-compose --version)"
    elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        echo -e "${WHITE}Docker Compose Version:${NC} $(docker compose version --short)"
    fi
    
    echo ""
    
    # Running containers
    echo -e "${WHITE}Running Containers:${NC}"
    if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q .; then
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo -e "${YELLOW}No containers are currently running${NC}"
    fi
    
    echo ""
    
    # Docker volumes
    echo -e "${WHITE}Docker Volumes:${NC}"
    if docker volume ls | grep -q .; then
        docker volume ls
    else
        echo -e "${YELLOW}No volumes found${NC}"
    fi
    
    echo ""
    
    # Docker networks
    echo -e "${WHITE}Docker Networks:${NC}"
    docker network ls
    
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
}

# Main function
main() {
    print_banner
    
    # Check requirements
    check_root
    
    echo -e "${WHITE}Docker & Containerization Setup${NC}"
    echo ""
    
    # Install Docker
    install_docker
    
    # Install Docker Compose
    install_docker_compose
    
    # Configure Docker
    configure_docker
    
    # Configure Docker security
    configure_docker_security
    
    # Install Portainer
    read -p "Do you want to install Portainer? (y/N): " portainer_choice
    if [[ $portainer_choice =~ ^[Yy]$ ]]; then
        install_portainer
    fi
    
    # Install Netdata
    read -p "Do you want to install Netdata using Docker Compose? (y/N): " netdata_choice
    if [[ $netdata_choice =~ ^[Yy]$ ]]; then
        install_netdata
    fi
    
    # Create Docker Compose examples
    read -p "Do you want to create Docker Compose examples? (y/N): " examples_choice
    if [[ $examples_choice =~ ^[Yy]$ ]]; then
        create_docker_compose_examples
    fi
    
    # Show status
    show_docker_status
    
    echo ""
    echo -e "${GREEN}Docker and containerization setup completed successfully!${NC}"
    echo ""
    echo -e "${WHITE}Next steps:${NC}"
    echo -e "  • Access Portainer (if installed): https://$(hostname -I | awk '{print $1}'):9443"
    echo -e "  • Access Netdata (if installed): http://$(hostname -I | awk '{print $1}'):19999"
    echo -e "  • Check Docker Compose examples in /opt/docker-examples"
    echo -e "  • Run 'docker --help' for more commands"
}

# Run main function
main "$@" 