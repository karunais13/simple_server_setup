#!/bin/bash

# Elasticsearch & Kibana Installation Module
# Installs Elasticsearch and Kibana for advanced log monitoring and querying

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
    echo "║                Elasticsearch & Kibana Setup                  ║"
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

# Check system requirements
check_requirements() {
    echo -e "${YELLOW}Checking system requirements...${NC}"
    
    # Check available memory (need at least 4GB)
    TOTAL_MEM=$(free -g | awk 'NR==2{print $2}')
    if [ "$TOTAL_MEM" -lt 4 ]; then
        echo -e "${RED}Warning: System has less than 4GB RAM. Elasticsearch may not perform well.${NC}"
        read -p "Continue anyway? (y/N): " continue_choice
        if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check available disk space (need at least 10GB)
    AVAILABLE_DISK=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    if [ "$AVAILABLE_DISK" -lt 10 ]; then
        echo -e "${RED}Warning: Less than 10GB available disk space.${NC}"
        read -p "Continue anyway? (y/N): " continue_choice
        if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo -e "${GREEN}System requirements check completed${NC}"
}

# Install Docker if not present
install_docker_if_needed() {
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${YELLOW}Docker not found. Installing Docker...${NC}"
        
        # Update package lists
        apt update
        
        # Install prerequisites
        apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
        
        # Add Docker GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Add Docker repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Install Docker
        apt update
        apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Start and enable Docker
        systemctl start docker
        systemctl enable docker
        
        echo -e "${GREEN}Docker installed successfully${NC}"
    else
        echo -e "${GREEN}Docker is already installed${NC}"
    fi
}

# Install Elasticsearch and Kibana
install_elasticsearch_kibana() {
    echo -e "${YELLOW}Installing Elasticsearch and Kibana...${NC}"
    
    # Create directories
    mkdir -p /opt/elasticsearch/{config,data,logs}
    mkdir -p /opt/kibana/{config,data}
    mkdir -p /opt/logstash/{config,pipeline,logs}
    
    # Set proper permissions
    chown -R 1000:1000 /opt/elasticsearch
    chown -R 1000:1000 /opt/kibana
    chown -R 1000:1000 /opt/logstash
    
    # Create Elasticsearch configuration
    cat > /opt/elasticsearch/config/elasticsearch.yml << EOF
cluster.name: docker-cluster
network.host: 0.0.0.0
discovery.type: single-node
xpack.security.enabled: false
xpack.monitoring.enabled: true
xpack.watcher.enabled: true
xpack.ml.enabled: true
path.data: /usr/share/elasticsearch/data
path.logs: /usr/share/elasticsearch/logs
bootstrap.memory_lock: true
cluster.routing.allocation.disk.threshold_enabled: true
cluster.routing.allocation.disk.watermark.low: 93%
cluster.routing.allocation.disk.watermark.high: 95%
cluster.routing.allocation.disk.watermark.flood_stage: 97%
EOF
    
    # Create Kibana configuration
    cat > /opt/kibana/config/kibana.yml << EOF
server.name: kibana
server.host: 0.0.0.0
server.port: 5601
elasticsearch.hosts: ["http://elasticsearch:9200"]
monitoring.ui.container.elasticsearch.enabled: true
monitoring.ui.container.logstash.enabled: true
xpack.security.enabled: false
xpack.encryptedSavedObjects.encryptionKey: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
EOF
    
    # Create Logstash configuration
    cat > /opt/logstash/config/logstash.yml << EOF
http.host: "0.0.0.0"
xpack.monitoring.elasticsearch.hosts: ["http://elasticsearch:9200"]
xpack.monitoring.enabled: true
EOF
    
    # Create Logstash pipeline
    cat > /opt/logstash/pipeline/logstash.conf << EOF
input {
  file {
    path => "/host/var/log/syslog"
    type => "syslog"
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
  file {
    path => "/host/var/log/auth.log"
    type => "auth"
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
  file {
    path => "/host/var/log/kern.log"
    type => "kernel"
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
  file {
    path => "/host/var/log/monitoring/*.log"
    type => "monitoring"
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
  file {
    path => "/host/var/log/system-alerts/*.log"
    type => "alerts"
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
  file {
    path => "/host/var/log/docker/*.log"
    type => "docker"
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
  file {
    path => "/host/var/log/nginx/*.log"
    type => "nginx"
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
  file {
    path => "/host/var/log/apache2/*.log"
    type => "apache"
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
}

filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:timestamp} %{SYSLOGHOST:hostname} %{DATA:program}(?:\[%{POSINT:pid}\])?: %{GREEDYDATA:message}" }
    }
    date {
      match => [ "timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
  
  if [type] == "auth" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:timestamp} %{SYSLOGHOST:hostname} %{DATA:program}(?:\[%{POSINT:pid}\])?: %{GREEDYDATA:message}" }
    }
    date {
      match => [ "timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
  
  if [type] == "kernel" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:timestamp} %{SYSLOGHOST:hostname} kernel: %{GREEDYDATA:message}" }
    }
    date {
      match => [ "timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
  
  if [type] == "nginx" {
    grok {
      match => { "message" => "%{COMBINEDAPACHELOG}" }
    }
    date {
      match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z" ]
    }
  }
  
  if [type] == "apache" {
    grok {
      match => { "message" => "%{COMBINEDAPACHELOG}" }
    }
    date {
      match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z" ]
    }
  }
  
  if [type] == "docker" {
    json {
      source => "message"
    }
  }
  
  if [type] == "monitoring" or [type] == "alerts" {
    json {
      source => "message"
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "logs-%{type}-%{+YYYY.MM.dd}"
  }
  stdout { codec => rubydebug }
}
EOF
    
    # Create Docker Compose file
    cat > /opt/elasticsearch/docker-compose.yml << EOF
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - cluster.routing.allocation.disk.threshold_enabled=true
      - cluster.routing.allocation.disk.watermark.low=93%
      - cluster.routing.allocation.disk.watermark.high=95%
      - cluster.routing.allocation.disk.watermark.flood_stage=97%
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    volumes:
      - /opt/elasticsearch/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml:ro
      - /opt/elasticsearch/data:/usr/share/elasticsearch/data
      - /opt/elasticsearch/logs:/usr/share/elasticsearch/logs
    ports:
      - "9200:9200"
      - "9300:9300"
    networks:
      - elastic
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9200/_cluster/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    container_name: kibana
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
      - XPACK_SECURITY_ENABLED=false
    volumes:
      - /opt/kibana/config/kibana.yml:/usr/share/kibana/config/kibana.yml:ro
      - /opt/kibana/data:/usr/share/kibana/data
    ports:
      - "5601:5601"
    networks:
      - elastic
    depends_on:
      elasticsearch:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:5601/api/status || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5

  logstash:
    image: docker.elastic.co/logstash/logstash:8.11.0
    container_name: logstash
    environment:
      - XPACK_MONITORING_ENABLED=true
      - XPACK_MONITORING_ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    volumes:
      - /opt/logstash/config/logstash.yml:/usr/share/logstash/config/logstash.yml:ro
      - /opt/logstash/pipeline/logstash.conf:/usr/share/logstash/pipeline/logstash.conf:ro
      - /opt/logstash/logs:/usr/share/logstash/logs
      # Host logs
      - /var/log:/host/var/log:ro
    networks:
      - elastic
    depends_on:
      elasticsearch:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9600 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5

networks:
  elastic:
    driver: bridge
EOF
    
    # Create log directories if they don't exist
    mkdir -p /var/log/monitoring
    mkdir -p /var/log/system-alerts
    mkdir -p /var/log/docker
    
    # Set permissions for log access
    chmod 755 /var/log/monitoring
    chmod 755 /var/log/system-alerts
    chmod 755 /var/log/docker
    
    # Start services
    cd /opt/elasticsearch
    docker compose up -d
    
    echo -e "${GREEN}Elasticsearch and Kibana installed successfully${NC}"
    echo -e "${WHITE}Elasticsearch:${NC} http://$(hostname -I | awk '{print $1}'):9200"
    echo -e "${WHITE}Kibana:${NC} http://$(hostname -I | awk '{print $1}'):5601"
    echo -e "${WHITE}Logstash:${NC} Running (collecting logs from host)"
}

# Show Elasticsearch status
show_elasticsearch_status() {
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                Elasticsearch & Kibana Status                ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    
    # Check if Docker is running
    if ! systemctl is-active --quiet docker; then
        echo -e "${RED}✗ Docker: Not running${NC}"
        return
    fi
    
    # Check Elasticsearch container
    if docker ps --format "{{.Names}}" | grep -q elasticsearch; then
        echo -e "${GREEN}✓ Elasticsearch: Running (Port 9200)${NC}"
        
        # Check Elasticsearch health
        if curl -s http://localhost:9200/_cluster/health > /dev/null 2>&1; then
            HEALTH=$(curl -s http://localhost:9200/_cluster/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
            echo -e "  ${WHITE}Cluster Health:${NC} $HEALTH"
        else
            echo -e "  ${YELLOW}⚠ Health check failed${NC}"
        fi
    else
        echo -e "${RED}✗ Elasticsearch: Not running${NC}"
    fi
    
    # Check Kibana container
    if docker ps --format "{{.Names}}" | grep -q kibana; then
        echo -e "${GREEN}✓ Kibana: Running (Port 5601)${NC}"
        
        # Check Kibana status
        if curl -s http://localhost:5601/api/status > /dev/null 2>&1; then
            echo -e "  ${WHITE}Status:${NC} Online"
        else
            echo -e "  ${YELLOW}⚠ Status check failed${NC}"
        fi
    else
        echo -e "${RED}✗ Kibana: Not running${NC}"
    fi
    
    # Check Logstash container
    if docker ps --format "{{.Names}}" | grep -q logstash; then
        echo -e "${GREEN}✓ Logstash: Running${NC}"
        
        # Check Logstash status
        if curl -s http://localhost:9600 > /dev/null 2>&1; then
            echo -e "  ${WHITE}Status:${NC} Online"
        else
            echo -e "  ${YELLOW}⚠ Status check failed${NC}"
        fi
    else
        echo -e "${RED}✗ Logstash: Not running${NC}"
    fi
    
    echo ""
    
    # Show log indices
    echo -e "${WHITE}Log Indices:${NC}"
    if curl -s http://localhost:9200/_cat/indices/logs-* > /dev/null 2>&1; then
        curl -s http://localhost:9200/_cat/indices/logs-* | while read line; do
            if [[ -n "$line" ]]; then
                echo -e "  • $line"
            fi
        done
    else
        echo -e "  ${YELLOW}No log indices found yet${NC}"
    fi
    
    echo ""
    
    # Access URLs
    echo -e "${WHITE}Access URLs:${NC}"
    echo -e "  • Elasticsearch API: http://$(hostname -I | awk '{print $1}'):9200"
    echo -e "  • Kibana Dashboard: http://$(hostname -I | awk '{print $1}'):5601"
    
    echo ""
    
    # System resources
    echo -e "${WHITE}System Resources:${NC}"
    echo -e "  • Memory Usage: $(free -h | awk 'NR==2{printf "%s/%s", $3,$2 }')"
    echo -e "  • Disk Usage: $(df -h / | awk 'NR==2{print $5}')"
    echo -e "  • Elasticsearch Data: $(du -sh /opt/elasticsearch/data 2>/dev/null || echo 'N/A')"
    
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
}

# Main function
main() {
    print_banner
    
    # Check requirements
    check_root
    check_requirements
    
    echo -e "${WHITE}Elasticsearch & Kibana Setup${NC}"
    echo ""
    
    # Install Docker if needed
    install_docker_if_needed
    
    # Install Elasticsearch and Kibana
    install_elasticsearch_kibana
    
    # Wait a bit for services to start
    echo -e "${YELLOW}Waiting for services to start...${NC}"
    sleep 30
    
    # Show status
    show_elasticsearch_status
    
    echo ""
    echo -e "${GREEN}Elasticsearch and Kibana setup completed successfully!${NC}"
    echo ""
    echo -e "${WHITE}Next steps:${NC}"
    echo -e "  • Access Kibana: http://$(hostname -I | awk '{print $1}'):5601"
    echo -e "  • Check Elasticsearch API: http://$(hostname -I | awk '{print $1}'):9200"
    echo -e "  • Logs are automatically collected from /var/log/"
    echo -e "  • Create custom dashboards in Kibana"
    echo ""
    echo -e "${YELLOW}Note:${NC} Services may take a few minutes to fully start up."
}

# Run main function
main "$@" 