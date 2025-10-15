#!/bin/bash

# Web Server Installation Module
# Installs and configures Nginx web server

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
    echo "║                    Web Server Setup                          ║"
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

# Install Nginx
install_nginx() {
    echo -e "${YELLOW}Installing Nginx...${NC}"
    
    # Update package lists
    apt update
    
    # Install Nginx and PHP-FPM
    apt install -y nginx php-fpm php-cli
    
    # Start and enable services
    systemctl start nginx
    systemctl enable nginx
    
    # Start PHP-FPM (detect version automatically)
    PHP_VERSION=$(php -v | head -n 1 | cut -d' ' -f2 | cut -d'.' -f1,2)
    systemctl start php${PHP_VERSION}-fpm
    systemctl enable php${PHP_VERSION}-fpm
    
    echo -e "${GREEN}Nginx and PHP-FPM installed successfully${NC}"
}

# Configure Nginx
configure_nginx() {
    echo -e "${YELLOW}Configuring Nginx...${NC}"
    
    # Backup original configuration
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
    
    # Create optimized Nginx configuration
    cat > /etc/nginx/nginx.conf << EOF
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    # Basic Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    
    # MIME Types
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    # Gzip Settings
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # Rate Limiting
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone \$binary_remote_addr zone=login:10m rate=1r/s;
    
    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Include server configurations
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF
    
    # Create default site configuration
    cat > /etc/nginx/sites-available/default << EOF
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    
    # Security
    location ~ /\. {
        deny all;
    }
    
    # Rate limiting for login attempts
    location /login {
        limit_req zone=login burst=5 nodelay;
        try_files \$uri \$uri/ =404;
    }
    
    # API endpoints for system information
    location /api/uptime {
        limit_req zone=api burst=20 nodelay;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME /var/www/html/api/uptime.php;
        include fastcgi_params;
    }
    
    location /api/load {
        limit_req zone=api burst=20 nodelay;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME /var/www/html/api/load.php;
        include fastcgi_params;
    }
    
    location /api/memory {
        limit_req zone=api burst=20 nodelay;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME /var/www/html/api/memory.php;
        include fastcgi_params;
    }
    
    location /api/disk {
        limit_req zone=api burst=20 nodelay;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME /var/www/html/api/disk.php;
        include fastcgi_params;
    }
    
    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|txt)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Monitoring dashboard
    location /monitoring {
        alias /var/www/monitoring;
        index index.html;
        try_files \$uri \$uri/ =404;
    }
    
    # Main location
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF
    
    # Create individual API PHP scripts for each endpoint
    mkdir -p /var/www/html/api
    
    # Uptime API
    cat > /var/www/html/api/uptime.php << 'EOF'
<?php
header('Content-Type: text/plain');
header('Access-Control-Allow-Origin: *');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');

$result = shell_exec('uptime -p 2>/dev/null');
echo $result ? trim($result) : 'N/A';
?>
EOF

    # Load API
    cat > /var/www/html/api/load.php << 'EOF'
<?php
header('Content-Type: text/plain');
header('Access-Control-Allow-Origin: *');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');

$uptime = shell_exec('uptime 2>/dev/null');
if ($uptime && preg_match('/load average:\s*(.+)/', $uptime, $matches)) {
    echo trim($matches[1]);
} else {
    echo 'N/A';
}
?>
EOF

    # Memory API
    cat > /var/www/html/api/memory.php << 'EOF'
<?php
header('Content-Type: text/plain');
header('Access-Control-Allow-Origin: *');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');

$free = shell_exec('free -h 2>/dev/null');
if ($free) {
    $lines = explode("\n", $free);
    if (isset($lines[1])) {
        $parts = preg_split('/\s+/', trim($lines[1]));
        if (count($parts) >= 3) {
            $used = $parts[2];
            $total = $parts[1];
            // Calculate percentage properly
            $used_num = (float)str_replace(['G', 'M', 'K'], ['', '', ''], $used);
            $total_num = (float)str_replace(['G', 'M', 'K'], ['', '', ''], $total);
            if ($total_num > 0) {
                $percentage = round(($used_num / $total_num) * 100, 1);
                echo "$used/$total ($percentage%)";
            } else {
                echo "$used/$total";
            }
        } else {
            echo 'N/A';
        }
    } else {
        echo 'N/A';
    }
} else {
    echo 'N/A';
}
?>
EOF

    # Disk API
    cat > /var/www/html/api/disk.php << 'EOF'
<?php
header('Content-Type: text/plain');
header('Access-Control-Allow-Origin: *');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');

$df = shell_exec('df -h / 2>/dev/null');
if ($df) {
    $lines = explode("\n", $df);
    if (isset($lines[1])) {
        $parts = preg_split('/\s+/', trim($lines[1]));
        if (count($parts) >= 5) {
            $used = $parts[2];
            $total = $parts[1];
            $percentage = $parts[4];
            echo "$used/$total ($percentage)";
        } else {
            echo 'N/A';
        }
    } else {
        echo 'N/A';
    }
} else {
    echo 'N/A';
}
?>
EOF
    
    # Get PHP version for socket path
    PHP_VERSION=$(php -v | head -n 1 | cut -d' ' -f2 | cut -d'.' -f1,2)
    
    # Create monitoring dashboard site
    cat > /etc/nginx/sites-available/monitoring << EOF
server {
    listen 80;
    server_name monitoring.local;
    
    root /var/www/monitoring;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # API endpoints for monitoring dashboard
    location /api/uptime {
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME /var/www/html/api/uptime.php;
        include fastcgi_params;
    }
    
    location /api/load {
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME /var/www/html/api/load.php;
        include fastcgi_params;
    }
    
    location /api/memory {
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME /var/www/html/api/memory.php;
        include fastcgi_params;
    }
    
    location /api/disk {
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME /var/www/html/api/disk.php;
        include fastcgi_params;
    }
}
EOF
    
    # Enable monitoring site
    ln -sf /etc/nginx/sites-available/monitoring /etc/nginx/sites-enabled/
    
    # Test configuration
    nginx -t
    
    # Reload Nginx
    systemctl reload nginx
    
    echo -e "${GREEN}Nginx configured successfully${NC}"
}

# Create sample web content
create_web_content() {
    echo -e "${YELLOW}Creating sample web content...${NC}"
    
    # Create web directory
    mkdir -p /var/www/html
    
    # Create sample index page
    cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to Ubuntu Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .status {
            background-color: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
            border: 1px solid #c3e6cb;
        }
        .info {
            background-color: #e2e3e5;
            padding: 15px;
            border-radius: 5px;
            margin: 10px 0;
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
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Ubuntu Server Setup Complete!</h1>
        
        <div class="status">
            ✅ Nginx web server is running successfully
        </div>
        
        <div class="info">
            <h3>Server Information:</h3>
            <p><strong>Hostname:</strong> <span id="hostname">Loading...</span></p>
            <p><strong>IP Address:</strong> <span id="ip-address">Loading...</span></p>
            <p><strong>Uptime:</strong> <span id="uptime">Loading...</span></p>
            <p><strong>Load Average:</strong> <span id="load-average">Loading...</span></p>
            <p><strong>Memory Usage:</strong> <span id="memory-usage">Loading...</span></p>
            <p><strong>Disk Usage:</strong> <span id="disk-usage">Loading...</span></p>
        </div>
        
        <div class="info">
            <h3>Available Services:</h3>
            <p>• <strong>Nginx Web Server:</strong> Running on port 80</p>
            <p>• <strong>SSH Access:</strong> Available on port 22</p>
            <p>• <strong>System Monitoring:</strong> Check status with 'status.sh'</p>
        </div>
        
        <div class="info">
            <h3>Quick Links:</h3>
            <a href="/monitoring" class="link">System Monitoring Dashboard</a>
            <a href="http://$(hostname -I | awk '{print $1}'):19999" class="link" target="_blank">Netdata (if installed)</a>
            <a href="http://$(hostname -I | awk '{print $1}'):5601" class="link" target="_blank">Kibana (if installed)</a>
            <a href="https://$(hostname -I | awk '{print $1}'):9443" class="link" target="_blank">Portainer (if installed)</a>
        </div>
        
        <div class="info">
            <h3>Next Steps:</h3>
            <ul>
                <li>Configure SSL certificates with Let's Encrypt</li>
                <li>Set up virtual hosts for your domains</li>
                <li>Install additional services as needed</li>
                <li>Configure firewall rules</li>
                <li>Set up automated backups</li>
            </ul>
        </div>
        
        <div class="info">
            <h3>Documentation:</h3>
            <p>For more information, check the README.md file or run:</p>
            <code>./status.sh</code> - Check system status<br>
            <code>./setup.sh</code> - Run setup menu again
        </div>
    </div>
    
    <script>
        // Function to update server information
        async function updateServerInfo() {
            try {
                // Fetch server information from API endpoints
                const [uptimeResponse, loadResponse, memoryResponse, diskResponse] = await Promise.all([
                    fetch('/api/uptime'),
                    fetch('/api/load'),
                    fetch('/api/memory'),
                    fetch('/api/disk')
                ]);
                
                // Update hostname (static)
                document.getElementById('hostname').textContent = window.location.hostname;
                
                // Update IP address (static)
                document.getElementById('ip-address').textContent = window.location.hostname;
                
                // Update dynamic information
                if (uptimeResponse.ok) {
                    document.getElementById('uptime').textContent = await uptimeResponse.text();
                } else {
                    document.getElementById('uptime').textContent = 'System uptime: Available via monitoring dashboard';
                }
                
                if (loadResponse.ok) {
                    document.getElementById('load-average').textContent = await loadResponse.text();
                } else {
                    document.getElementById('load-average').textContent = 'System load: Available via monitoring dashboard';
                }
                
                if (memoryResponse.ok) {
                    document.getElementById('memory-usage').textContent = await memoryResponse.text();
                } else {
                    document.getElementById('memory-usage').textContent = 'Memory usage: Available via monitoring dashboard';
                }
                
                if (diskResponse.ok) {
                    document.getElementById('disk-usage').textContent = await diskResponse.text();
                } else {
                    document.getElementById('disk-usage').textContent = 'Disk usage: Available via monitoring dashboard';
                }
                
            } catch (error) {
                console.error('Error fetching server information:', error);
                // Fallback to static information
                document.getElementById('hostname').textContent = window.location.hostname;
                document.getElementById('ip-address').textContent = window.location.hostname;
                document.getElementById('uptime').textContent = 'System uptime: Available via monitoring dashboard';
                document.getElementById('load-average').textContent = 'System load: Available via monitoring dashboard';
                document.getElementById('memory-usage').textContent = 'Memory usage: Available via monitoring dashboard';
                document.getElementById('disk-usage').textContent = 'Disk usage: Available via monitoring dashboard';
            }
        }
        
        // Update server information on page load
        document.addEventListener('DOMContentLoaded', updateServerInfo);
        
        // Update server information every 30 seconds
        setInterval(updateServerInfo, 30000);
    </script>
</body>
</html>
EOF
    
    # Create basic monitoring dashboard if it doesn't exist
    if [[ ! -d /var/www/monitoring ]]; then
        echo -e "${YELLOW}Creating basic monitoring dashboard...${NC}"
        mkdir -p /var/www/monitoring
        
        cat > /var/www/monitoring/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Monitoring Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .card { background: #f8f9fa; padding: 15px; margin: 10px 0; border-radius: 5px; border-left: 4px solid #007bff; }
        .metric { margin: 10px 0; }
        .status { padding: 10px; border-radius: 5px; margin: 10px 0; }
        .online { background-color: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 System Monitoring Dashboard</h1>
        <p>Welcome to your Ubuntu server monitoring dashboard.</p>
        
        <div class="card">
            <h3>📊 System Status</h3>
            <div class="status online">✅ System Status: Online</div>
            <div class="metric"><strong>Hostname:</strong> <span id="hostname">Loading...</span></div>
            <div class="metric"><strong>Uptime:</strong> <span id="uptime">Loading...</span></div>
            <div class="metric"><strong>Load Average:</strong> <span id="load-average">Loading...</span></div>
            <div class="metric"><strong>Memory Usage:</strong> <span id="memory-usage">Loading...</span></div>
            <div class="metric"><strong>Disk Usage:</strong> <span id="disk-usage">Loading...</span></div>
        </div>
        
        <div class="card">
            <h3>🔗 Quick Links</h3>
            <p><a href="/">← Back to Main Page</a></p>
            <p><a href="http://$(hostname -I | awk '{print $1}'):19999" target="_blank">Netdata Dashboard (if installed)</a></p>
        </div>
    </div>
    
    <script>
        // Function to update server information
        async function updateServerInfo() {
            try {
                // Update hostname
                document.getElementById('hostname').textContent = window.location.hostname;
                
                // Function to fetch API data with better error handling
                async function fetchApiData(endpoint, elementId) {
                    try {
                        const response = await fetch('/api/' + endpoint);
                        if (response.ok) {
                            const data = await response.text();
                            document.getElementById(elementId).textContent = data;
                        } else {
                            console.error('API error for ' + endpoint + ':', response.status);
                            document.getElementById(elementId).textContent = 'Error';
                        }
                    } catch (error) {
                        console.error('Fetch error for ' + endpoint + ':', error);
                        document.getElementById(elementId).textContent = 'N/A';
                    }
                }
                
                // Fetch all API data
                await Promise.all([
                    fetchApiData('uptime', 'uptime'),
                    fetchApiData('load', 'load-average'),
                    fetchApiData('memory', 'memory-usage'),
                    fetchApiData('disk', 'disk-usage')
                ]);
                
            } catch (error) {
                console.error('Error updating server information:', error);
            }
        }
        
        // Update on page load and every 30 seconds
        document.addEventListener('DOMContentLoaded', updateServerInfo);
        setInterval(updateServerInfo, 30000);
    </script>
</body>
</html>
EOF
    fi
    
    # Set permissions
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    chown -R www-data:www-data /var/www/monitoring
    chmod -R 755 /var/www/monitoring
    
    echo -e "${GREEN}Sample web content created successfully${NC}"
}

# Install SSL certificates (Let's Encrypt)
install_ssl() {
    echo -e "${YELLOW}Installing SSL certificates...${NC}"
    
    # Install Certbot
    apt install -y certbot python3-certbot-nginx
    
    # Get domain name
    read -p "Enter your domain name (or press Enter to skip): " domain_name
    
    if [[ -n "$domain_name" ]]; then
        # Create SSL certificate
        certbot --nginx -d "$domain_name" --non-interactive --agree-tos --email admin@"$domain_name"
        
        # Set up auto-renewal
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
        
        echo -e "${GREEN}SSL certificate installed for $domain_name${NC}"
    else
        echo -e "${YELLOW}SSL installation skipped${NC}"
    fi
}

# Show web server status
show_webserver_status() {
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    Web Server Status                        ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    
    # Nginx status
    if systemctl is-active --quiet nginx; then
        echo -e "${GREEN}✓ Nginx: Running${NC}"
        echo -e "  ${WHITE}Version:${NC} $(nginx -v 2>&1 | cut -d'/' -f2)"
        echo -e "  ${WHITE}HTTP Port:${NC} 80"
        echo -e "  ${WHITE}HTTPS Port:${NC} 443"
    else
        echo -e "${RED}✗ Nginx: Not running${NC}"
    fi
    
    echo ""
    
    # Check SSL certificates
    echo -e "${WHITE}SSL Certificates:${NC}"
    if [[ -d /etc/letsencrypt/live ]]; then
        for domain in /etc/letsencrypt/live/*; do
            if [[ -d "$domain" && "$(basename "$domain")" != "README" ]]; then
                echo -e "  ${GREEN}✓${NC} $(basename "$domain")"
                echo -e "    ${WHITE}Expires:${NC} $(openssl x509 -in "$domain/cert.pem" -noout -enddate | cut -d= -f2)"
            fi
        done
    else
        echo -e "  ${YELLOW}⚠ No SSL certificates found${NC}"
    fi
    
    echo ""
    
    # Virtual hosts
    echo -e "${WHITE}Virtual Hosts:${NC}"
    if [[ -d /etc/nginx/sites-enabled ]]; then
        for site in /etc/nginx/sites-enabled/*; do
            if [[ -f "$site" ]]; then
                echo -e "  • $(basename "$site")"
            fi
        done
    fi
    
    echo ""
    
    # Access URLs
    echo -e "${WHITE}Access URLs:${NC}"
    echo -e "  • Main Website: http://$(hostname -I | awk '{print $1}')"
    echo -e "  • Monitoring Dashboard: http://$(hostname -I | awk '{print $1}')/monitoring"
    
    # Check for SSL
    if [[ -d /etc/letsencrypt/live ]]; then
        for domain in /etc/letsencrypt/live/*; do
            if [[ -d "$domain" && "$(basename "$domain")" != "README" ]]; then
                echo -e "  • HTTPS: https://$(basename "$domain")"
            fi
        done
    fi
    
    echo ""
    
    # Performance metrics
    echo -e "${WHITE}Performance Metrics:${NC}"
    echo -e "  • Active Connections: $(ss -tuln | grep :80 | wc -l)"
    echo -e "  • Nginx Process Count: $(ps aux | grep nginx | grep -v grep | wc -l)"
    echo -e "  • Memory Usage: $(ps aux | grep nginx | grep -v grep | awk '{sum+=$6} END {print sum/1024 " MB"}')"
    
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
}

# Main function
main() {
    print_banner
    
    # Check requirements
    check_root
    
    echo -e "${WHITE}Web Server Setup${NC}"
    echo ""
    
    # Install Nginx
    install_nginx
    
    # Configure Nginx
    configure_nginx
    
    # Create web content
    create_web_content
    
    # Install SSL certificates
    read -p "Do you want to install SSL certificates? (y/N): " ssl_choice
    if [[ $ssl_choice =~ ^[Yy]$ ]]; then
        install_ssl
    fi
    
    # Show status
    show_webserver_status
    
    echo ""
    echo -e "${GREEN}Web server setup completed successfully!${NC}"
    echo ""
    echo -e "${WHITE}Next steps:${NC}"
    echo -e "  • Access your website: http://$(hostname -I | awk '{print $1}')"
    echo -e "  • Configure virtual hosts for your domains"
    echo -e "  • Set up SSL certificates with Let's Encrypt"
    echo -e "  • Configure firewall rules"
}

# Run main function
main "$@" 