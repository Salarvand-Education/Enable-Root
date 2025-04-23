#!/bin/bash
# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'  # Bold text
NC='\033[0m'    # No Color

# Function to print messages in color
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print fancy headers
print_header() {
    local message=$1
    echo -e "${BOLD}${PURPLE}=== ${message} ===${NC}"
}

# Function to generate a random password
generate_random_password() {
    local length=${1:-16}  # Default length is 16 characters
    tr -dc 'A-Za-z0-9!@#$%^&*()' < /dev/urandom | head -c "$length"
}

# Function to get server IPv4 address
get_server_ipv4() {
    # Try to get external IPv4 first (if there's internet connection)
    local EXTERNAL_IP
    EXTERNAL_IP=$(curl -s --connect-timeout 3 -4 ifconfig.me 2>/dev/null)
    
    # If external IP detection fails, get the primary local IPv4
    if [[ -z "$EXTERNAL_IP" ]]; then
        local LOCAL_IP
        # These commands try to extract only IPv4 addresses
        LOCAL_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | head -n 1)
        
        # Fallback if the above doesn't work
        if [[ -z "$LOCAL_IP" ]]; then
            LOCAL_IP=$(hostname -I | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | head -n 1)
        fi
        
        if [[ -n "$LOCAL_IP" ]]; then
            echo "$LOCAL_IP"
        else
            echo "unknown-ip"
        fi
    else
        echo "$EXTERNAL_IP"
    fi
}

# Check root access
if [[ $EUID -ne 0 ]]; then
    print_message "$YELLOW" "⚠️  This script must be run as root."
    print_message "$YELLOW" "🔑 Please run with sudo."
    exit 1
fi

print_header "SSH Configuration Utility"
print_message "$GREEN" "🚀 Starting SSH configuration..."

# Backup original config
if cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup 2>/dev/null; then
    print_message "$GREEN" "✅ SSH config file backed up successfully."
else
    print_message "$RED" "❌ Failed to backup SSH config file. Exiting..."
    exit 1
fi

# Check if Port is already defined in sshd_config
if grep -q "^Port" /etc/ssh/sshd_config; then
    PORT=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
    print_message "$YELLOW" "🔍 Existing SSH port detected: ${GREEN}${PORT}${NC}"
else
    PORT=22
    print_message "$YELLOW" "ℹ️ No existing SSH port found. Setting default port: ${GREEN}${PORT}${NC}"
fi

# Set root password
print_header "Root Password Setup"
print_message "$YELLOW" "🔑 Do you want to generate a random root password? (y/n)"
read -r RANDOM_PASSWORD_CHOICE

if [[ "$RANDOM_PASSWORD_CHOICE" == "y" || "$RANDOM_PASSWORD_CHOICE" == "Y" ]]; then
    NEW_ROOT_PASSWORD=$(generate_random_password)
    echo "root:$NEW_ROOT_PASSWORD" | chpasswd
    if [[ $? -ne 0 ]]; then
        print_message "$RED" "❌ Failed to set random root password. Exiting..."
        exit 1
    fi
    print_message "$GREEN" "✅ Random root password generated and set successfully."
    print_message "$YELLOW" "🔐 Your new root password is: ${BOLD}${RED}${NEW_ROOT_PASSWORD}${NC}"
    print_message "$YELLOW" "📝 Please save this password in a secure place!"
else
    print_message "$GREEN" "🔑 Please enter a new root password:"
    read -rs NEW_ROOT_PASSWORD
    echo "root:$NEW_ROOT_PASSWORD" | chpasswd
    if [[ $? -ne 0 ]]; then
        print_message "$RED" "❌ Failed to set root password. Exiting..."
        exit 1
    fi
    print_message "$GREEN" "✅ Custom root password set successfully."
    print_message "$YELLOW" "🔐 Your custom root password has been set."
    print_message "$YELLOW" "📝 Please remember to store it in a secure place!"
fi

# Configure SSH
print_header "SSH Configuration"
cat > /etc/ssh/sshd_config << EOL
# Port configuration (preserving existing or defaulting to 22)
Port ${PORT}
Include /etc/ssh/sshd_config.d/*.conf
PasswordAuthentication yes
PermitRootLogin yes
PubkeyAuthentication yes
KbdInteractiveAuthentication yes
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem       sftp    /usr/lib/openssh/sftp-server
EOL

# Set proper permissions
chmod 644 /etc/ssh/sshd_config
if [[ $? -ne 0 ]]; then
    print_message "$RED" "❌ Failed to set permissions on SSH config file. Exiting..."
    exit 1
fi

# Restart SSH service
print_message "$BLUE" "🔄 Restarting SSH service..."
systemctl restart sshd
if [[ $? -ne 0 ]]; then
    print_message "$RED" "❌ Failed to restart SSH service. Exiting..."
    exit 1
fi

print_message "$GREEN" "✅ SSH configuration completed successfully!"

# Display new settings
print_header "Configuration Summary"
print_message "$YELLOW" "📋 New SSH settings applied:"
echo -e "- Root login: ${GREEN}enabled${NC} ✅"
echo -e "- Password authentication: ${GREEN}enabled${NC} ✅"
echo -e "- SSH key authentication: ${GREEN}enabled${NC} ✅"
echo -e "- Interactive authentication: ${GREEN}enabled${NC} ✅"
echo -e "- SSH port: ${GREEN}${PORT}${NC} 🔌"

# Get the server IPv4 address
SERVER_IP=$(get_server_ipv4)

# Display connection info
print_message "$BLUE" "🔗 To connect to the server, use the following command:"
echo -e "${CYAN}ssh root@${SERVER_IP} -p ${PORT}${NC}"

# Check SSH service status
if systemctl is-active --quiet sshd; then
    print_message "$GREEN" "✅ SSH service is active and running."
else
    print_message "$RED" "❌ Error: SSH service is not running."
fi

print_message "$GREEN" "🎉 Script execution completed successfully!"
