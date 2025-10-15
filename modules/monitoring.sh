#!/bin/bash

# Monitoring Tools Installation Module
# Installs monitoring and logging tools for system observation

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
    echo "║                   Monitoring Tools Setup                     ║"
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

# Install basic monitoring tools
install_basic_tools() {
    echo -e "${YELLOW}Installing basic monitoring tools...${NC}"
    
    # Update package lists
    apt update
    
    # Install monitoring tools
    apt install -y htop iotop nethogs nload iftop nmon glances
    
    echo -e "${GREEN}Basic monitoring tools installed successfully${NC}"
}

# Configure log rotation
configure_log_rotation() {
    echo -e "${YELLOW}Configuring log rotation...${NC}"
    
    # Create logrotate configuration
    cat > /etc/logrotate.d/monitoring << EOF
/var/log/monitoring/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
}

/var/log/system-alerts/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF
    
    # Create log directories
    mkdir -p /var/log/monitoring
    mkdir -p /var/log/system-alerts
    
    echo -e "${GREEN}Log rotation configured successfully${NC}"
}

# Set up system alerts
setup_system_alerts() {
    echo -e "${YELLOW}Setting up system alerts...${NC}"
    
    # Create alert script
    cat > /usr/local/bin/system-alert.sh << 'EOF'
#!/bin/bash

# System alert script
ALERT_EMAIL="admin@$(hostname)"
DISK_THRESHOLD=80
MEMORY_THRESHOLD=90
LOAD_THRESHOLD=5
LOG_FILE="/var/log/system-alerts/alerts.log"

# Function to log alerts
log_alert() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Check disk usage
DISK_USAGE=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
    log_alert "High disk usage: ${DISK_USAGE}%"
    echo "High disk usage: ${DISK_USAGE}%" | mail -s "System Alert: High Disk Usage" "$ALERT_EMAIL" 2>/dev/null || true
fi

# Check memory usage
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ "$MEMORY_USAGE" -gt "$MEMORY_THRESHOLD" ]; then
    log_alert "High memory usage: ${MEMORY_USAGE}%"
    echo "High memory usage: ${MEMORY_USAGE}%" | mail -s "System Alert: High Memory Usage" "$ALERT_EMAIL" 2>/dev/null || true
fi

# Check load average
LOAD_AVERAGE=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
if (( $(echo "$LOAD_AVERAGE > $LOAD_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
    log_alert "High load average: $LOAD_AVERAGE"
    echo "High load average: $LOAD_AVERAGE" | mail -s "System Alert: High Load Average" "$ALERT_EMAIL" 2>/dev/null || true
fi

# Check if Docker is running (if installed)
if command -v docker >/dev/null 2>&1; then
    if ! systemctl is-active --quiet docker; then
        log_alert "Docker service is not running"
        echo "Docker service is not running" | mail -s "System Alert: Docker Service Down" "$ALERT_EMAIL" 2>/dev/null || true
    fi
fi

# Check if Netdata is running (if Docker is available)
if command -v docker >/dev/null 2>&1; then
    if ! docker ps --format "{{.Names}}" | grep -q netdata; then
        log_alert "Netdata container is not running"
        echo "Netdata container is not running" | mail -s "System Alert: Netdata Container Down" "$ALERT_EMAIL" 2>/dev/null || true
    fi
fi
EOF
    
    chmod +x /usr/local/bin/system-alert.sh
    
    # Add to crontab (run every 5 minutes)
    (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/system-alert.sh") | crontab -
    
    echo -e "${GREEN}System alerts configured successfully${NC}"
}

# Set up centralized logging
setup_centralized_logging() {
    echo -e "${YELLOW}Setting up centralized logging...${NC}"
    
    # Install rsyslog if not present
    apt install -y rsyslog
    
    # Configure rsyslog
    cat > /etc/rsyslog.d/monitoring.conf << EOF
# Centralized logging configuration
\$ModLoad imfile
\$InputFileName /var/log/syslog
\$InputFileTag syslog
\$InputFileStateFile stat-syslog
\$InputFileSeverity info
\$InputFileFacility local0
\$InputRunFileMonitor

# Log monitoring events
local0.* /var/log/monitoring/monitoring.log

# Send to remote server (uncomment and configure as needed)
# *.* @@remote-log-server:514
EOF
    
    # Restart rsyslog
    systemctl restart rsyslog
    
    echo -e "${GREEN}Centralized logging configured successfully${NC}"
}

# Create monitoring dashboard
create_monitoring_dashboard() {
    echo -e "${YELLOW}Creating monitoring dashboard...${NC}"
    
    # Create dashboard directory
    mkdir -p /var/www/monitoring
    
    # Create simple dashboard
    cat > /var/www/monitoring/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Monitoring Dashboard</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .dashboard {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        .card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .card h3 {
            margin-top: 0;
            color: #333;
        }
        .link {
            display: inline-block;
            padding: 10px 20px;
            background-color: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin: 5px;
        }
        .link:hover {
            background-color: #0056b3;
        }
        .status {
            padding: 10px;
            border-radius: 5px;
            margin: 10px 0;
        }
        .status.online {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .status.offline {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .metric {
            background-color: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            margin: 5px 0;
        }
    </style>
</head>
<body>
    <h1>🚀 System Monitoring Dashboard</h1>
    <p>Welcome to your Ubuntu server monitoring dashboard.</p>
    
    <div class="dashboard">
        <div class="card">
            <h3>📊 System Status</h3>
            <div class="status online">✅ System Status: Online</div>
            <div class="metric">
                <strong>Hostname:</strong> $(hostname)
            </div>
            <div class="metric">
                <strong>Uptime:</strong> <span id="uptime">$(uptime -p)</span>
            </div>
            <div class="metric">
                <strong>Load Average:</strong> <span id="load">$(uptime | awk -F'load average:' '{print $2}')</span>
            </div>
            <div class="metric">
                <strong>Memory Usage:</strong> <span id="memory">$(free -h | awk 'NR==2{printf "%s/%s", $3,$2 }')</span>
            </div>
            <div class="metric">
                <strong>Disk Usage:</strong> <span id="disk">$(df -h / | awk 'NR==2{print $5}')</span>
            </div>
        </div>
        
        <div class="card">
            <h3>📈 Netdata Monitoring</h3>
            <div class="status online">✅ Netdata: Running via Docker</div>
            <p>Real-time system monitoring with Netdata:</p>
            <a href="http://$(hostname -I | awk '{print $1}'):19999" class="link" target="_blank">Netdata Dashboard</a>
            <p><small>Access comprehensive system metrics, performance data, and real-time monitoring.</small></p>
        </div>
        
        <div class="card">
            <h3>🐳 Container Management</h3>
            <div class="status online">✅ Docker: Running</div>
            <a href="https://$(hostname -I | awk '{print $1}'):9443" class="link" target="_blank">Portainer</a>
            <p><small>Manage Docker containers and images through the web interface.</small></p>
        </div>
        
        <div class="card">
            <h3>🔧 System Tools</h3>
            <p>Installed monitoring tools:</p>
            <ul>
                <li><strong>htop</strong> - Process monitoring</li>
                <li><strong>iotop</strong> - I/O monitoring</li>
                <li><strong>nethogs</strong> - Network monitoring</li>
                <li><strong>nload</strong> - Network load</li>
                <li><strong>iftop</strong> - Network connections</li>
                <li><strong>nmon</strong> - System monitoring</li>
                <li><strong>glances</strong> - System overview</li>
            </ul>
        </div>
    </div>
    
    <div class="card" style="margin-top: 20px;">
        <h3>📋 Quick Commands</h3>
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 10px;">
            <div class="metric">
                <strong>System Status:</strong><br>
                <code>systemctl status</code>
            </div>
            <div class="metric">
                <strong>Process Monitor:</strong><br>
                <code>htop</code>
            </div>
            <div class="metric">
                <strong>Disk Usage:</strong><br>
                <code>df -h</code>
            </div>
            <div class="metric">
                <strong>Memory Usage:</strong><br>
                <code>free -h</code>
            </div>
            <div class="metric">
                <strong>Network Status:</strong><br>
                <code>nload</code>
            </div>
            <div class="metric">
                <strong>Docker Status:</strong><br>
                <code>docker ps</code>
            </div>
        </div>
    </div>
    
    <div class="card" style="margin-top: 20px;">
        <h3>📊 Real-time Metrics</h3>
        <p>For comprehensive system monitoring, use Netdata which provides:</p>
        <ul>
            <li>Real-time CPU, memory, and disk usage</li>
            <li>Network traffic and bandwidth monitoring</li>
            <li>Process and service monitoring</li>
            <li>Docker container metrics</li>
            <li>Custom alerts and notifications</li>
            <li>Historical data and trends</li>
        </ul>
        <a href="http://$(hostname -I | awk '{print $1}'):19999" class="link" target="_blank">Open Netdata Dashboard</a>
    </div>
    
    <script>
        // Auto-refresh system metrics
        function updateMetrics() {
            // Update uptime
            fetch('/api/uptime')
                .then(response => response.text())
                .then(data => {
                    document.getElementById('uptime').textContent = data;
                })
                .catch(error => console.log('Error updating uptime:', error));
            
            // Update load average
            fetch('/api/load')
                .then(response => response.text())
                .then(data => {
                    document.getElementById('load').textContent = data;
                })
                .catch(error => console.log('Error updating load:', error));
            
            // Update memory usage
            fetch('/api/memory')
                .then(response => response.text())
                .then(data => {
                    document.getElementById('memory').textContent = data;
                })
                .catch(error => console.log('Error updating memory:', error));
            
            // Update disk usage
            fetch('/api/disk')
                .then(response => response.text())
                .then(data => {
                    document.getElementById('disk').textContent = data;
                })
                .catch(error => console.log('Error updating disk:', error));
        }
        
        // Update every 30 seconds
        setInterval(updateMetrics, 30000);
        
        // Initial update
        updateMetrics();
    </script>
</body>
</html>
EOF
    
    # Set permissions
    chown -R www-data:www-data /var/www/monitoring
    chmod -R 755 /var/www/monitoring
    
    echo -e "${GREEN}Monitoring dashboard created successfully${NC}"
    echo -e "${WHITE}Access dashboard at:${NC} http://$(hostname -I | awk '{print $1}')/monitoring"
}

# Show monitoring status
show_monitoring_status() {
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    Monitoring Status                        ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    
    # Basic tools
    echo -e "${WHITE}Basic Monitoring Tools:${NC}"
    if command -v htop >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} htop: Installed"
    else
        echo -e "  ${RED}✗${NC} htop: Not installed"
    fi
    
    if command -v iotop >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} iotop: Installed"
    else
        echo -e "  ${RED}✗${NC} iotop: Not installed"
    fi
    
    if command -v nload >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} nload: Installed"
    else
        echo -e "  ${RED}✗${NC} nload: Not installed"
    fi
    
    if command -v glances >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} glances: Installed"
    else
        echo -e "  ${RED}✗${NC} glances: Not installed"
    fi
    
    echo ""
    
    # Docker and Netdata status
    echo -e "${WHITE}Docker & Netdata:${NC}"
    if command -v docker >/dev/null 2>&1; then
        if systemctl is-active --quiet docker; then
            echo -e "  ${GREEN}✓${NC} Docker: Running"
            
            # Check if Netdata container is running
            if docker ps --format "{{.Names}}" | grep -q netdata; then
                echo -e "  ${GREEN}✓${NC} Netdata Container: Running (Port 19999)"
                echo -e "    ${WHITE}Log monitoring:${NC} Enabled (5GB limit)"
                echo -e "    ${WHITE}Host logs:${NC} /var/log/syslog, /var/log/auth.log, /var/log/monitoring/"
                echo -e "    ${WHITE}Docker logs:${NC} /var/log/docker/"
            else
                echo -e "  ${YELLOW}⚠${NC} Netdata Container: Not running"
                echo -e "    Run 'cd /opt/netdata && docker compose up -d' to start"
            fi
        else
            echo -e "  ${RED}✗${NC} Docker: Not running"
        fi
    else
        echo -e "  ${RED}✗${NC} Docker: Not installed"
        echo -e "    Install Docker first to use Netdata monitoring"
    fi
    
    echo ""
    
    # Logging services
    echo -e "${WHITE}Logging Services:${NC}"
    if systemctl is-active --quiet rsyslog; then
        echo -e "  ${GREEN}✓${NC} rsyslog: Running"
    else
        echo -e "  ${RED}✗${NC} rsyslog: Not running"
    fi
    
    # Check if alert script exists
    if [[ -f /usr/local/bin/system-alert.sh ]]; then
        echo -e "  ${GREEN}✓${NC} System Alerts: Configured"
    else
        echo -e "  ${RED}✗${NC} System Alerts: Not configured"
    fi
    
    echo ""
    
    # Access URLs
    echo -e "${WHITE}Access URLs:${NC}"
    echo -e "  • Monitoring Dashboard: http://$(hostname -I | awk '{print $1}')/monitoring"
    if command -v docker >/dev/null 2>&1 && docker ps --format "{{.Names}}" | grep -q netdata; then
        echo -e "  • Netdata Dashboard: http://$(hostname -I | awk '{print $1}'):19999"
    else
        echo -e "  • Netdata Dashboard: Not available (install Docker and Netdata first)"
    fi
    echo -e "  • Portainer (if installed): https://$(hostname -I | awk '{print $1}'):9443"
    
    echo ""
    
    # System metrics
    echo -e "${WHITE}Current System Metrics:${NC}"
    echo -e "  • CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
    echo -e "  • Memory Usage: $(free | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
    echo -e "  • Disk Usage: $(df -h / | awk 'NR==2{print $5}')"
    echo -e "  • Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo -e "  • Uptime: $(uptime -p)"
    
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
}

# Main function
main() {
    print_banner
    
    # Check requirements
    check_root
    
    echo -e "${WHITE}Monitoring Tools Setup${NC}"
    echo ""
    
    # Install basic monitoring tools
    install_basic_tools
    
    # Configure log rotation
    configure_log_rotation
    
    # Set up system alerts
    read -p "Do you want to set up system alerts? (y/N): " alerts_choice
    if [[ $alerts_choice =~ ^[Yy]$ ]]; then
        setup_system_alerts
    fi
    
    # Set up centralized logging
    read -p "Do you want to set up centralized logging? (y/N): " logging_choice
    if [[ $logging_choice =~ ^[Yy]$ ]]; then
        setup_centralized_logging
    fi
    
    # Create monitoring dashboard
    read -p "Do you want to create a monitoring dashboard? (y/N): " dashboard_choice
    if [[ $dashboard_choice =~ ^[Yy]$ ]]; then
        create_monitoring_dashboard
    fi
    
    # Show status
    show_monitoring_status
    
    echo ""
    echo -e "${GREEN}Monitoring tools setup completed successfully!${NC}"
    echo ""
    echo -e "${WHITE}Next steps:${NC}"
    echo -e "  • Install Docker and Netdata for comprehensive monitoring"
    echo -e "  • Run 'htop' for process monitoring"
    echo -e "  • Run 'nload' for network monitoring"
    echo -e "  • Run 'glances' for system overview"
    echo -e "  • Check logs in /var/log/monitoring/"
    echo ""
    echo -e "${YELLOW}Note:${NC} For comprehensive monitoring, install Docker and Netdata using the Docker module."
}

# Run main function
main "$@" 