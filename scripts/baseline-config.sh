#!/bin/bash
# Linux Baseline Configuration Tool
# Main script that orchestrates the system configuration

set -eo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure SCRIPT_DIR is the scripts directory (not lib)
if [[ "$SCRIPT_DIR" == */lib ]]; then
    SCRIPT_DIR="$(dirname "$SCRIPT_DIR")"
fi

# Verify required directories and files exist
if [ ! -d "${SCRIPT_DIR}/lib" ]; then
    echo "ERROR: Library directory not found at ${SCRIPT_DIR}/lib"
    echo "Make sure you're running this script from the linux_baseline root directory:"
    echo "  cd /path/to/linux_baseline"
    echo "  sudo bash scripts/baseline-config.sh"
    exit 1
fi

# Source all library files
source "${SCRIPT_DIR}/lib/common.sh" || {
    echo "ERROR: Failed to source common.sh from ${SCRIPT_DIR}/lib/"
    exit 1
}
source "${SCRIPT_DIR}/lib/network.sh" || { echo "ERROR: Failed to source network.sh"; exit 1; }
source "${SCRIPT_DIR}/lib/users.sh" || { echo "ERROR: Failed to source users.sh"; exit 1; }
source "${SCRIPT_DIR}/lib/firewall.sh" || { echo "ERROR: Failed to source firewall.sh"; exit 1; }
source "${SCRIPT_DIR}/lib/packages.sh" || { echo "ERROR: Failed to source packages.sh"; exit 1; }
source "${SCRIPT_DIR}/lib/ssh.sh" || { echo "ERROR: Failed to source ssh.sh"; exit 1; }

# Configuration file
CONFIG_FILE="${SCRIPT_DIR}/../configs/systems.yaml"

# Verify config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Main menu function
show_menu() {
    clear
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Linux Baseline Configuration Tool${NC}"
    echo -e "${BLUE}║     Version 1.0${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Select an option:"
    echo ""
    echo -e "${YELLOW}[1]${NC} Show available systems"
    echo -e "${YELLOW}[2]${NC} Configure a system (local)"
    echo -e "${YELLOW}[3]${NC} Configure a system (remote)"
    echo -e "${YELLOW}[4]${NC} Add new system to configuration"
    echo -e "${YELLOW}[5]${NC} View system configuration"
    echo -e "${YELLOW}[0]${NC} Exit"
    echo ""
    echo -ne "${BLUE}Enter your choice:${NC} "
}

# Configure system locally
configure_system_local() {
    if ! command -v yq &> /dev/null; then
        log_error "yq is required but not installed"
        echo ""
        echo "Install yq with one of these commands:"
        echo "  Ubuntu/Debian: sudo apt-get install yq"
        echo "  CentOS/RHEL: sudo yum install yq"
        echo "  Or using pip: pip install yq"
        echo ""
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Check if root
    if [ "$EUID" -ne 0 ]; then
        log_error "Local configuration must be run as root"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    display_systems
    
    echo -ne "${YELLOW}Enter system number to configure:${NC} "
    read -r sys_num
    
    # Validate input
    if ! [[ "$sys_num" =~ ^[0-9]+$ ]]; then
        log_error "Invalid input"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Get system configuration
    local sys_config=$(yq eval ".systems.$sys_num" "$CONFIG_FILE")
    
    if [ "$sys_config" = "null" ] || [ -z "$sys_config" ]; then
        log_error "System $sys_num not found"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Display system details
    clear
    echo ""
    echo -e "${BLUE}System Configuration Details${NC}"
    echo "================================"
    echo ""
    yq eval ".systems.$sys_num" "$CONFIG_FILE"
    echo ""
    echo ""
    
    if ! confirm "Do you want to proceed with this configuration?"; then
        log_warning "Configuration cancelled"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Apply configuration
    log_info "Starting baseline configuration..."
    echo ""
    
    # Extract values from YAML
    local hostname=$(yq eval ".systems.$sys_num.hostname" "$CONFIG_FILE")
    local ip=$(yq eval ".systems.$sys_num.ip_address" "$CONFIG_FILE")
    local netmask=$(yq eval ".systems.$sys_num.netmask" "$CONFIG_FILE")
    local gateway=$(yq eval ".systems.$sys_num.gateway" "$CONFIG_FILE")
    local dns_primary=$(yq eval ".systems.$sys_num.dns_primary" "$CONFIG_FILE")
    local dns_secondary=$(yq eval ".systems.$sys_num.dns_secondary" "$CONFIG_FILE")
    local timezone=$(yq eval ".systems.$sys_num.timezone" "$CONFIG_FILE")
    local distro=$(yq eval ".systems.$sys_num.distro" "$CONFIG_FILE")
    local interface=$(yq eval ".systems.$sys_num.network.interface" "$CONFIG_FILE")
    local firewall_enabled=$(yq eval ".systems.$sys_num.firewall.enabled" "$CONFIG_FILE")
    
    # 1. Hostname
    configure_hostname "$hostname"
    echo ""
    
    # 2. Timezone
    configure_timezone "$timezone"
    echo ""
    
    # 3. Update packages
    update_packages
    echo ""
    
    # 4. Network configuration
    configure_network "$interface" "$ip" "$netmask" "$gateway" "$dns_primary" "$dns_secondary" "$distro"
    echo ""
    
    # 5. Users
    log_info "Starting user creation..."
    local user_count=$(yq eval ".systems.$sys_num.users | length" "$CONFIG_FILE")
    
    for ((i=0; i<user_count; i++)); do
        local user_name=$(yq eval ".systems.$sys_num.users[$i].name" "$CONFIG_FILE")
        local user_uid=$(yq eval ".systems.$sys_num.users[$i].uid" "$CONFIG_FILE")
        local user_groups=$(yq eval ".systems.$sys_num.users[$i].groups | @json" "$CONFIG_FILE")
        local user_home=$(yq eval ".systems.$sys_num.users[$i].create_home" "$CONFIG_FILE")
        
        create_user "$user_name" "$user_uid" "$user_groups" "$user_home"
    done
    echo ""
    
    # 6. Firewall
    configure_firewall "$firewall_enabled" "$distro"
    
    if [ "$firewall_enabled" = "true" ]; then
        local rule_count=$(yq eval ".systems.$sys_num.firewall.rules | length" "$CONFIG_FILE")
        
        for ((i=0; i<rule_count; i++)); do
            local rule_port=$(yq eval ".systems.$sys_num.firewall.rules[$i].port" "$CONFIG_FILE")
            local rule_protocol=$(yq eval ".systems.$sys_num.firewall.rules[$i].protocol" "$CONFIG_FILE")
            local rule_action=$(yq eval ".systems.$sys_num.firewall.rules[$i].action" "$CONFIG_FILE")
            
            if [ "$distro" = "ubuntu" ] || [ "$distro" = "debian" ]; then
                add_ufw_rule "$rule_port" "$rule_protocol" "$rule_action"
            else
                add_firewalld_rule "$rule_port" "$rule_protocol" "$rule_action"
            fi
        done
    fi
    echo ""
    
    # 7. Packages
    local packages=$(yq eval ".systems.$sys_num.packages | @json" "$CONFIG_FILE")
    install_packages "$packages" "$distro"
    echo ""
    
    # 8. SSH Configuration
    local ssh_permit_root=$(yq eval ".systems.$sys_num.ssh.permit_root_login" "$CONFIG_FILE")
    local ssh_password=$(yq eval ".systems.$sys_num.ssh.password_authentication" "$CONFIG_FILE")
    local ssh_pubkey=$(yq eval ".systems.$sys_num.ssh.pubkey_authentication" "$CONFIG_FILE")
    local ssh_port=$(yq eval ".systems.$sys_num.ssh.port" "$CONFIG_FILE")
    local ssh_max_auth=$(yq eval ".systems.$sys_num.ssh.max_auth_tries" "$CONFIG_FILE")
    local ssh_client_alive=$(yq eval ".systems.$sys_num.ssh.client_alive_interval" "$CONFIG_FILE")
    
    configure_ssh "$ssh_permit_root" "$ssh_password" "$ssh_pubkey" "$ssh_port" "$ssh_max_auth" "$ssh_client_alive"
    echo ""
    
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}Configuration completed!${NC}"
    echo -e "${GREEN}================================${NC}"
    
    read -p "Press Enter to continue..."
}

# Configure system remotely via SSH
configure_system_remote() {
    display_systems
    
    echo -ne "${YELLOW}Enter system number to configure:${NC} "
    read -r sys_num
    
    # Validate input
    if ! [[ "$sys_num" =~ ^[0-9]+$ ]]; then
        log_error "Invalid input"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Get system configuration
    if ! command -v yq &> /dev/null; then
        log_error "yq is required but not installed"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    local sys_config=$(yq eval ".systems.$sys_num" "$CONFIG_FILE")
    
    if [ "$sys_config" = "null" ] || [ -z "$sys_config" ]; then
        log_error "System $sys_num not found"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Display system details
    clear
    echo ""
    echo -e "${BLUE}System Configuration Details${NC}"
    echo "================================"
    echo ""
    yq eval ".systems.$sys_num" "$CONFIG_FILE"
    echo ""
    echo ""
    
    local ip=$(yq eval ".systems.$sys_num.ip_address" "$CONFIG_FILE")
    local hostname=$(yq eval ".systems.$sys_num.hostname" "$CONFIG_FILE")
    
    echo -ne "${YELLOW}Enter SSH username (default: root):${NC} "
    read -r ssh_user
    ssh_user=${ssh_user:-root}
    
    if ! confirm "Deploy configuration to $hostname ($ip) as $ssh_user?"; then
        log_warning "Deployment cancelled"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    log_info "Copying baseline script to remote host..."
    
    # Copy script to remote
    scp -r "${SCRIPT_DIR}" "${ssh_user}@${ip}:~/baseline-config/"
    
    log_info "Running baseline configuration on remote host..."
    
    # Run script remotely
    ssh -t "${ssh_user}@${ip}" "cd ~/baseline-config && sudo bash scripts/baseline-config.sh"
    
    log_success "Remote configuration completed"
    
    read -p "Press Enter to continue..."
}

# Add new system to configuration
add_new_system() {
    clear
    echo ""
    echo -e "${BLUE}Add New System to Configuration${NC}"
    echo "==============================="
    echo ""
    
    echo -ne "${YELLOW}System name (e.g., Web Server - Production):${NC} "
    read -r sys_name
    
    echo -ne "${YELLOW}Hostname:${NC} "
    read -r sys_hostname
    
    echo -ne "${YELLOW}IP Address:${NC} "
    read -r sys_ip
    
    echo -ne "${YELLOW}Netmask (e.g., 255.255.255.0):${NC} "
    read -r sys_netmask
    
    echo -ne "${YELLOW}Gateway:${NC} "
    read -r sys_gateway
    
    echo -ne "${YELLOW}Primary DNS (e.g., 8.8.8.8):${NC} "
    read -r sys_dns1
    
    echo -ne "${YELLOW}Secondary DNS (e.g., 8.8.4.4):${NC} "
    read -r sys_dns2
    
    echo -ne "${YELLOW}Timezone (e.g., UTC):${NC} "
    read -r sys_tz
    
    echo -ne "${YELLOW}Distribution (ubuntu/centos/debian/fedora):${NC} "
    read -r sys_distro
    
    # Get next system number
    if ! command -v yq &> /dev/null; then
        log_error "yq is required to add systems"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    local next_num=$(yq eval '.systems | keys | max' "$CONFIG_FILE")
    next_num=$((next_num + 1))
    
    log_info "Adding system $next_num: $sys_name"
    
    # Use yq to add the new system
    yq eval ".systems.$next_num = {
        name: \"$sys_name\",
        hostname: \"$sys_hostname\",
        ip_address: \"$sys_ip\",
        netmask: \"$sys_netmask\",
        gateway: \"$sys_gateway\",
        dns_primary: \"$sys_dns1\",
        dns_secondary: \"$sys_dns2\",
        timezone: \"$sys_tz\",
        distro: \"$sys_distro\",
        network: {interface: \"eth0\", dhcp: false},
        users: [],
        firewall: {enabled: true, rules: []},
        packages: [],
        ssh: {
            permit_root_login: \"no\",
            password_authentication: \"no\",
            pubkey_authentication: \"yes\",
            port: 22,
            max_auth_tries: 3,
            client_alive_interval: 300
        }
    }" -i "$CONFIG_FILE"
    
    log_success "System $next_num added to configuration"
    log_info "Edit $CONFIG_FILE to customize the configuration"
    
    read -p "Press Enter to continue..."
}

# View system configuration
view_system_config() {
    if ! command -v yq &> /dev/null; then
        log_error "yq is required but not installed"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    display_systems
    
    echo -ne "${YELLOW}Enter system number to view:${NC} "
    read -r sys_num
    
    # Validate input
    if ! [[ "$sys_num" =~ ^[0-9]+$ ]]; then
        log_error "Invalid input"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    clear
    echo ""
    echo -e "${BLUE}System Configuration for System $sys_num${NC}"
    echo "========================================"
    echo ""
    
    if yq eval ".systems.$sys_num" "$CONFIG_FILE" | grep -q "null"; then
        log_error "System $sys_num not found"
    else
        yq eval ".systems.$sys_num" "$CONFIG_FILE"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Main loop
main() {
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                display_systems
                read -p "Press Enter to continue..."
                ;;
            2)
                configure_system_local
                ;;
            3)
                configure_system_remote
                ;;
            4)
                add_new_system
                ;;
            5)
                view_system_config
                ;;
            0)
                log_info "Exiting..."
                exit 0
                ;;
            *)
                log_error "Invalid option"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run main function
main
