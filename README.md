# Ubuntu Server Setup Script

A comprehensive, interactive server setup and installation process for Ubuntu servers. This script provides a modular approach to configuring and securing Ubuntu servers with modern best practices.

## 🚀 Features

### Core Setup
- **System Updates**: Automatic package updates and essential software installation
- **User Management**: User creation, SSH configuration, and security policies
- **Web Server Setup**: Nginx installation with virtual hosts
- **Monitoring**: Basic monitoring tools and Netdata integration
- **Container Support**: Docker and Docker Compose v2 installation
- **Elasticsearch & Kibana**: Advanced log monitoring and querying with Logstash

### Security Features
- SSH key-based authentication
- Password complexity requirements (10 characters minimum)
- Secure user permissions and sudo configuration
- Docker security hardening

### Monitoring & Logging
- Real-time system monitoring with Netdata
- Log collection and analysis with Elasticsearch
- Web-based dashboards for system metrics
- Automated log rotation and management

### Additional Features
- **Custom Software**: Installation of development and admin tools
- **Modular Design**: Independent modules for selective installation
- **Interactive Menus**: User-friendly terminal interface
- **Comprehensive Logging**: Detailed logging of all operations
- **Configuration Templates**: Ready-to-use configuration files

## 📋 Prerequisites

- Ubuntu 20.04 LTS or later
- Root access or sudo privileges
- Internet connection for package downloads
- Minimum 1GB RAM and 10GB disk space

## 🛠 Quick Start

### 1. Download and Setup
```bash
# Clone or download the script
git clone <repository-url>
cd ServerSetupScript

# Make scripts executable
chmod +x *.sh
chmod +x modules/*.sh
```

### 2. Run Quick Setup
```bash
# Quick setup with all essential components
sudo ./quick_start.sh

# Or run individual modules
sudo ./modules/system_update.sh
sudo ./modules/user_management.sh
sudo ./modules/webserver.sh
sudo ./modules/monitoring.sh
sudo ./modules/docker.sh
```

### 3. Interactive Setup
```bash
# Full interactive setup
sudo ./setup.sh
```

## 📁 File Structure

```
ServerSetupScript/
├── setup.sh                 # Main interactive setup script
├── status.sh                # System status checker
├── install.sh               # Automated installation script
├── quick_start.sh           # Quick start guide
├── README.md                # This documentation
├── modules/                 # Modular installation scripts
│   ├── system_update.sh     # System updates and package management
│   ├── user_management.sh   # User creation and SSH configuration
│   ├── webserver.sh         # Nginx installation
│   ├── monitoring.sh        # Monitoring tools and Netdata
│   ├── docker.sh           # Docker and container management
│   ├── elasticsearch.sh    # Elasticsearch, Kibana, and Logstash
│   └── custom_software.sh  # Additional software installation
├── config/                  # Configuration templates
│   ├── nginx/              # Nginx configuration files
│   ├── ssh/                # SSH configuration templates
│   ├── systemd/            # Systemd service templates
│   ├── monitoring/         # Monitoring configuration
│   └── docker/             # Docker configuration examples
├── logs/                   # Installation and operation logs
└── backups/                # System backup storage
```

## 🎯 Setup Options

### Quick Setup
Basic server with essential components:
- System updates
- User management and SSH
- Web server (Nginx)
- Monitoring tools

### Development Setup
Quick setup plus development tools:
- All quick setup components
- Development tools and utilities
- Docker and containerization

### Production Setup
Quick setup optimized for production:
- All quick setup components
- Docker for containerization
- Performance optimizations

### Custom Setup
Interactive menu for selective installation:
- Choose specific modules to install
- Customize configurations
- Selective service setup

## ⚙️ Configuration

### Password Policies
- Minimum length: 10 characters
- Complexity requirements: 3 character classes
- Maximum repeat: 2 characters
- Dictionary check enabled

### Web Server Configuration
- Security headers enabled
- Gzip compression
- Static file caching
- Rate limiting
- SSL/TLS support

### SSH Configuration
- Root login disabled
- Key-based authentication
- Connection limits
- Timeout settings

## 🔧 Customization

### Adding Custom Modules
1. Create a new script in the `modules/` directory
2. Follow the naming convention: `module_name.sh`
3. Include proper error handling and logging
4. Add the module to the main menu in `setup.sh`

### Configuration Templates
- All configuration files are in the `config/` directory
- Templates can be customized before installation
- Backup of original configurations is automatic

### Environment Variables
Create a `.env` file in the project root:
```bash
SERVER_HOSTNAME=your-server
ADMIN_EMAIL=admin@your-domain.com
DOMAIN_NAME=your-domain.com
TIMEZONE=UTC
```

## 🐛 Troubleshooting

### Common Issues

**Permission Denied**
```bash
# Ensure scripts are executable
chmod +x *.sh
chmod +x modules/*.sh
```

**Service Not Starting**
```bash
# Check service status
sudo systemctl status service-name

# View logs
sudo journalctl -u service-name
```

**Configuration Errors**
```bash
# Test Nginx configuration
sudo nginx -t
```

### Log Files
- Setup logs: `logs/setup_*.log`
- Service logs: `/var/log/nginx/`
- System logs: `/var/log/syslog`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Development Guidelines
- Follow bash scripting best practices
- Include proper error handling
- Add comprehensive logging
- Test on multiple Ubuntu versions
- Update documentation

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

### Getting Help
- Check the troubleshooting section
- Review log files for errors
- Search existing issues
- Create a new issue with details

### Reporting Issues
When reporting issues, please include:
- Ubuntu version
- Script version
- Error messages
- Log files
- Steps to reproduce

## Access Points & Ports

### Web Interfaces & Dashboards

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **Kibana Dashboard** | `http://server-ip:5601` | 5601 | Elasticsearch data visualization and log analysis |
| **Netdata Dashboard** | `http://server-ip:19999` | 19999 | Real-time system monitoring and metrics |
| **Portainer** | `https://server-ip:9443` | 9443 | Docker container management interface |
| **Monitoring Dashboard** | `http://server-ip/monitoring` | 80/443 | Custom system monitoring overview |
| **Elasticsearch API** | `http://server-ip:9200` | 9200 | Elasticsearch REST API |
| **Elasticsearch Cluster** | `http://server-ip:9300` | 9300 | Elasticsearch cluster communication |
| **Logstash API** | `http://server-ip:9600` | 9600 | Logstash monitoring API |

### Web Servers

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **Nginx** | `http://server-ip` | 80 | Web server (HTTP) |
| **Nginx SSL** | `https://server-ip` | 443 | Web server (HTTPS) |

### System Services

| Service | Port | Description |
|---------|------|-------------|
| **SSH** | 22 | Secure shell access |

## Complete Port Summary

### Standard Ports (Always Available)
- **22** - SSH
- **80** - HTTP (Nginx)
- **443** - HTTPS (Nginx with SSL)

### Service Ports (Based on Installation)
- **19999** - Netdata
- **5601** - Kibana
- **9200** - Elasticsearch
- **9300** - Elasticsearch Cluster
- **9600** - Logstash
- **9443** - Portainer

## Quick Access Guide

### Primary Dashboards
1. **System Overview**: `http://server-ip/monitoring`
2. **Real-time Monitoring**: `http://server-ip:19999`
3. **Log Analysis**: `http://server-ip:5601`
4. **Container Management**: `https://server-ip:9443`

### API Endpoints
- **Elasticsearch**: `http://server-ip:9200`
- **Logstash**: `http://server-ip:9600`

### Web Services
- **Main Website**: `http://server-ip` or `https://server-ip`

## Security Notes

### Authentication & Access Control
- **SSH**: Root login disabled, key-based authentication required
- **Password Policy**: Minimum 10 characters with complexity requirements
- **User Permissions**: Restricted sudo access with proper group assignments
- **Service Isolation**: Each service runs with appropriate user permissions

### Network Security
- **HTTPS Only**: Web services use SSL/TLS encryption (ports 443, 9443)
- **Port Restrictions**: Non-essential ports are not exposed by default
- **Rate Limiting**: Nginx configured with rate limiting for API endpoints
- **Security Headers**: XSS protection, content type options, frame options

### Container Security
- **Docker Hardening**: Non-root containers, security options enabled
- **Resource Limits**: Memory and CPU limits configured
- **Network Isolation**: Docker networks isolated from host network
- **Image Security**: Only official images from trusted sources

### Monitoring & Logging
- **Log Management**: Centralized logging with 5GB size limits
- **Audit Trail**: All system changes logged and monitored
- **Real-time Alerts**: System monitoring with automated alerts
- **Access Logging**: All web and service access logged

## Firewall Configuration

For production deployments, consider restricting access to:
- **SSH (22)**: Limit to specific IP ranges or VPN access
- **Web Ports (80, 443)**: Public access for web services
- **Monitoring Ports (19999, 5601)**: Internal network or VPN access only
- **Container Ports (9443)**: Internal network access only
- **Elasticsearch Ports (9200, 9300)**: Local access only

## 📈 Version History

### Version 1.0.0 (Current)
**Initial Release - Complete Server Setup Solution**

#### Core Features
- **System Management**: Automated system updates, package management, and essential software installation
- **User Management**: Secure user creation, SSH key configuration, password policies (10+ characters)
- **Web Server**: Nginx installation with security headers, SSL support, and performance optimization
- **Monitoring**: Netdata real-time monitoring, system metrics, and performance dashboards
- **Container Platform**: Docker and Docker Compose with Portainer management interface
- **Log Analytics**: Elasticsearch, Kibana, and Logstash for advanced log monitoring and analysis

#### Security Features
- SSH key-based authentication with root login disabled
- Password complexity requirements and user permission controls
- Docker security hardening with non-root containers
- Nginx security headers and rate limiting
- Automated SSL certificate management with Let's Encrypt

#### Monitoring & Logging
- Real-time system monitoring with Netdata (port 19999)
- Advanced log analysis with Elasticsearch (port 9200) and Kibana (port 5601)
- Logstash pipeline for centralized log processing (port 9600)
- Custom monitoring dashboard with system metrics
- Automated log rotation and 5GB storage limits

#### Container Management
- Docker container runtime with security configurations
- Portainer web interface for container management (port 9443)
- Docker Compose for multi-container applications
- Container health monitoring and automated restarts

#### Web Services
- Nginx web server with optimized configuration
- SSL/TLS support with automatic certificate renewal
- Virtual host support for multiple domains
- Performance optimization with gzip compression and caching

#### Development Tools
- Custom software installation module
- Development environment setup
- System administration tools
- Network and monitoring utilities

#### System Integration
- Modular design for selective installation
- Interactive setup menus with user-friendly interface
- Comprehensive logging and error handling
- Configuration templates and backup systems
- Status checking and system health monitoring

---

**Note**: This script is designed for Ubuntu servers. Use with caution and always backup your system before running automated setup scripts. 