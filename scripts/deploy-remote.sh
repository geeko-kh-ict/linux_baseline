#!/bin/bash
# Remote Deployment Helper Script
# This script facilitates deploying the baseline configuration to multiple remote systems

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure SCRIPT_DIR is the scripts directory (not lib)
if [[ "$SCRIPT_DIR" == */lib ]]; then
    SCRIPT_DIR="$(dirname "$SCRIPT_DIR")"
fi

# Config file is in parent directory (linux_baseline/configs/)
CONFIG_FILE="${SCRIPT_DIR}/../configs/systems.yaml"

# Verify config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found at $CONFIG_FILE"
    echo "Make sure you're running this script from the linux_baseline root directory:"
    echo "  cd /path/to/linux_baseline"
    echo "  bash scripts/deploy-remote.sh"
    exit 1
fi

# Check if yq is available
check_dependencies() {
    if ! command -v yq &> /dev/null; then
        log_error "yq is required but not installed"
        echo "Install with: sudo apt-get install yq"
        exit 1
    fi
    
    if ! command -v ssh &> /dev/null; then
        log_error "ssh is required but not installed"
        exit 1
    fi
}

# Deploy to single system
deploy_to_system() {
    local sys_num=$1
    local ssh_user=$2
    local ssh_key=$3
    
    log_info "Deploying to system $sys_num"
    
    # Get system info
    local hostname=$(yq eval ".systems.$sys_num.hostname" "$CONFIG_FILE")
    local ip=$(yq eval ".systems.$sys_num.ip_address" "$CONFIG_FILE")
    
    if [ "$hostname" = "null" ] || [ -z "$hostname" ]; then
        log_error "System $sys_num not found"
        return 1
    fi
    
    log_info "System: $hostname ($ip)"
    
    # Create SSH command
    local ssh_cmd="ssh"
    if [ -n "$ssh_key" ]; then
        ssh_cmd="$ssh_cmd -i $ssh_key"
    fi
    ssh_cmd="$ssh_cmd -o StrictHostKeyChecking=no"
    
    # Test connectivity
    log_info "Testing SSH connectivity..."
    if ! $ssh_cmd "${ssh_user}@${ip}" "echo 'Connected'" > /dev/null 2>&1; then
        log_error "Cannot connect to $ip via SSH"
        return 1
    fi
    
    log_success "SSH connection successful"
    
    # Copy scripts
    log_info "Copying baseline configuration scripts..."
    if scp -r "${SCRIPT_DIR}/scripts" "${ssh_user}@${ip}:~/baseline-config/" > /dev/null 2>&1; then
        log_success "Scripts copied"
    else
        log_error "Failed to copy scripts"
        return 1
    fi
    
    # Copy config
    log_info "Copying system configuration..."
    if scp "${SCRIPT_DIR}/configs/systems.yaml" "${ssh_user}@${ip}:~/baseline-config/configs/" > /dev/null 2>&1; then
        log_success "Configuration copied"
    else
        log_error "Failed to copy configuration"
        return 1
    fi
    
    # Run configuration
    log_info "Running baseline configuration..."
    if $ssh_cmd -t "${ssh_user}@${ip}" "cd ~/baseline-config && sudo bash scripts/baseline-config.sh < <(echo $sys_num)" > /dev/null 2>&1; then
        log_success "Configuration applied successfully"
    else
        log_warning "Configuration application completed with warnings"
    fi
    
    log_success "System $sys_num deployment completed"
    return 0
}

# Deploy to multiple systems
deploy_all_systems() {
    local ssh_user=$1
    local ssh_key=$2
    
    if ! command -v yq &> /dev/null; then
        log_error "yq is required"
        return 1
    fi
    
    local count=$(yq eval '.systems | keys | length' "$CONFIG_FILE")
    
    log_info "Deploying to $count systems"
    echo ""
    
    local success=0
    local failed=0
    
    for i in $(seq 1 "$count"); do
        if deploy_to_system "$i" "$ssh_user" "$ssh_key"; then
            ((success++))
        else
            ((failed++))
        fi
        echo ""
    done
    
    echo "================================"
    echo -e "${GREEN}Deployment Summary${NC}"
    echo "================================"
    echo -e "Successful: ${GREEN}$success${NC}"
    echo -e "Failed: ${RED}$failed${NC}"
    echo "================================"
    
    if [ $failed -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Generate deployment report
generate_report() {
    local output_file=$1
    
    log_info "Generating deployment report..."
    
    cat > "$output_file" << 'EOF'
# Deployment Report

## Environment
Date: $(date)
Hostname: $(hostname)
User: $(whoami)

## Systems Deployed
EOF
    
    if command -v yq &> /dev/null; then
        yq eval '.systems | to_entries | .[] | "- System \(.key): \(.value.name)"' "$CONFIG_FILE" >> "$output_file"
    fi
    
    log_success "Report generated: $output_file"
}

# Main menu
show_menu() {
    clear
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Remote Deployment Tool${NC}"
    echo -e "${BLUE}║   Version 1.0${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Options:"
    echo ""
    echo -e "${YELLOW}[1]${NC} Deploy to a single system"
    echo -e "${YELLOW}[2]${NC} Deploy to all systems"
    echo -e "${YELLOW}[3]${NC} Test connectivity to all systems"
    echo -e "${YELLOW}[4]${NC} Generate deployment report"
    echo -e "${YELLOW}[0]${NC} Exit"
    echo ""
    echo -ne "${BLUE}Enter your choice:${NC} "
}

# Test connectivity
test_connectivity() {
    local ssh_user=${1:-ubuntu}
    
    if ! command -v yq &> /dev/null; then
        log_error "yq is required"
        return 1
    fi
    
    local count=$(yq eval '.systems | keys | length' "$CONFIG_FILE")
    
    log_info "Testing connectivity to $count systems"
    echo ""
    
    local reachable=0
    local unreachable=0
    
    for i in $(seq 1 "$count"); do
        local ip=$(yq eval ".systems.$i.ip_address" "$CONFIG_FILE")
        local hostname=$(yq eval ".systems.$i.hostname" "$CONFIG_FILE")
        
        echo -n "Testing $hostname ($ip)... "
        
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${ssh_user}@${ip}" "echo 'OK'" > /dev/null 2>&1; then
            echo -e "${GREEN}OK${NC}"
            ((reachable++))
        else
            echo -e "${RED}UNREACHABLE${NC}"
            ((unreachable++))
        fi
    done
    
    echo ""
    echo "================================"
    echo -e "Reachable: ${GREEN}$reachable${NC}"
    echo -e "Unreachable: ${RED}$unreachable${NC}"
    echo "================================"
}

# Main function
main() {
    check_dependencies
    
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                echo ""
                echo -ne "${YELLOW}Enter system number:${NC} "
                read -r sys_num
                echo -ne "${YELLOW}SSH username:${NC} "
                read -r ssh_user
                echo -ne "${YELLOW}SSH key (press Enter for default):${NC} "
                read -r ssh_key
                
                deploy_to_system "$sys_num" "$ssh_user" "$ssh_key"
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                echo -ne "${YELLOW}SSH username:${NC} "
                read -r ssh_user
                echo -ne "${YELLOW}SSH key (press Enter for default):${NC} "
                read -r ssh_key
                
                deploy_all_systems "$ssh_user" "$ssh_key"
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                echo -ne "${YELLOW}SSH username (default: ubuntu):${NC} "
                read -r ssh_user
                ssh_user=${ssh_user:-ubuntu}
                
                test_connectivity "$ssh_user"
                read -p "Press Enter to continue..."
                ;;
            4)
                echo ""
                echo -ne "${YELLOW}Output filename (default: deployment_report.md):${NC} "
                read -r output_file
                output_file=${output_file:-deployment_report.md}
                
                generate_report "$output_file"
                read -p "Press Enter to continue..."
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

# Check if script is being sourced or executed
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main
fi
