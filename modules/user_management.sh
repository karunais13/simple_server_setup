#!/bin/bash

# User Management and SSH Setup Module
# Handles user creation, SSH configuration, and access management

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
    echo "║                User Management & SSH Setup                   ║"
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

# Configure password policies
configure_password_policies() {
    echo -e "${YELLOW}Configuring password policies...${NC}"
    
    # Set minimum password length to 10 characters
    sed -i 's/^PASS_MIN_LEN.*/PASS_MIN_LEN\t10/' /etc/login.defs
    
    # Configure password complexity
    cat > /etc/security/pwquality.conf << EOF
# Password quality configuration
minlen = 10
minclass = 3
maxrepeat = 2
maxclassrepeat = 2
gecoscheck = 1
dictcheck = 1
usercheck = 1
enforcing = 1
retry = 3
EOF
    
    echo -e "${GREEN}Password policies configured successfully${NC}"
}

# Create new user
create_user() {
    echo -e "${YELLOW}Creating new user...${NC}"
    
    read -p "Enter username for new user: " username
    
    if id "$username" &>/dev/null; then
        echo -e "${RED}User $username already exists${NC}"
        return 1
    fi
    
    # Create user with home directory
    useradd -m -s /bin/bash "$username"
    
    # Set password
    passwd "$username"
    
    # Add user to sudo group
    usermod -aG sudo "$username"
    
    echo -e "${GREEN}User $username created successfully${NC}"
}

# Configure SSH
configure_ssh() {
    echo -e "${YELLOW}Configuring SSH...${NC}"
    
    # Backup original SSH config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Configure SSH settings
    cat > /etc/ssh/sshd_config << EOF
# SSH Configuration
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Authentication
LoginGraceTime 120
PermitRootLogin no
StrictModes yes
PubkeyAuthentication yes
AuthorizedKeysFile %h/.ssh/authorized_keys
PasswordAuthentication yes

# Security settings
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# X11 forwarding
X11Forwarding yes
X11DisplayOffset 10

# Other settings
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
AcceptEnv LANG LC_*

# Subsystem
Subsystem sftp /usr/lib/openssh/sftp-server

# PAM
UsePAM yes

# Connection limits
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
    
    # Restart SSH service
    systemctl restart ssh
    
    echo -e "${GREEN}SSH configured successfully${NC}"
}

# Setup SSH keys
setup_ssh_keys() {
    echo -e "${YELLOW}Setting up SSH keys...${NC}"
    
    read -p "Enter username for SSH key setup: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}User $username does not exist${NC}"
        return 1
    fi
    
    # Create .ssh directory
    mkdir -p /home/$username/.ssh
    chmod 700 /home/$username/.ssh
    
    # Generate SSH key pair
    ssh-keygen -t rsa -b 4096 -f /home/$username/.ssh/id_rsa -N ""
    
    # Set up authorized_keys
    cat /home/$username/.ssh/id_rsa.pub > /home/$username/.ssh/authorized_keys
    chmod 600 /home/$username/.ssh/authorized_keys
    
    # Set ownership
    chown -R $username:$username /home/$username/.ssh
    
    echo -e "${GREEN}SSH keys set up for user $username${NC}"
    echo -e "${YELLOW}Private key location: /home/$username/.ssh/id_rsa${NC}"
    echo -e "${YELLOW}Public key location: /home/$username/.ssh/id_rsa.pub${NC}"
}

# Configure sudo
configure_sudo() {
    echo -e "${YELLOW}Configuring sudo...${NC}"
    
    # Create sudoers file for wheel group
    cat > /etc/sudoers.d/wheel << EOF
# Allow members of group wheel to execute any command
%wheel ALL=(ALL) ALL
EOF
    
    # Set proper permissions
    chmod 440 /etc/sudoers.d/wheel
    
    echo -e "${GREEN}Sudo configured successfully${NC}"
}

# Create user groups
create_groups() {
    echo -e "${YELLOW}Creating user groups...${NC}"
    
    # Create common groups
    groupadd -f developers
    groupadd -f admins
    groupadd -f users
    
    echo -e "${GREEN}User groups created successfully${NC}"
}

# Show user information
show_user_info() {
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    User Information                        ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    
    echo -e "${WHITE}System Users:${NC}"
    awk -F: '$3 >= 1000 && $3 != 65534 {print "  " $1 " (UID: " $3 ")"}' /etc/passwd
    
    echo ""
    echo -e "${WHITE}Groups:${NC}"
    getent group | grep -E "(sudo|wheel|developers|admins)" | cut -d: -f1 | sort
    
    echo ""
    echo -e "${WHITE}SSH Service Status:${NC}"
    systemctl is-active ssh
    
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
}

# Main function
main() {
    print_banner
    
    # Check requirements
    check_root
    
    echo -e "${WHITE}User Management & SSH Setup${NC}"
    echo ""
    
    # Configure password policies
    configure_password_policies
    
    # Configure SSH
    configure_ssh
    
    # Configure sudo
    configure_sudo
    
    # Create groups
    create_groups
    
    # Ask for user creation
    read -p "Do you want to create a new user? (y/N): " create_user_choice
    if [[ $create_user_choice =~ ^[Yy]$ ]]; then
        create_user
    fi
    
    # Ask for SSH key setup
    read -p "Do you want to set up SSH keys? (y/N): " ssh_key_choice
    if [[ $ssh_key_choice =~ ^[Yy]$ ]]; then
        setup_ssh_keys
    fi
    
    # Show user information
    show_user_info
    
    echo ""
    echo -e "${GREEN}User management and SSH setup completed successfully!${NC}"
}

# Run main function
main "$@" 