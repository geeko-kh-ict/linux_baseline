#!/bin/bash
# Common functions for baseline configuration

# Source directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../configs/systems.yaml"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Parse YAML file (simplified parser for basic key-value)
parse_yaml() {
    local file=$1
    local section=$2
    
    if command -v yq &> /dev/null; then
        cat "$file"
    else
        log_error "yq is not installed. Please install yq: sudo apt-get install yq"
        exit 1
    fi
}

# Get system count from YAML
get_system_count() {
    if command -v yq &> /dev/null; then
        yq eval '.systems | keys | length' "$CONFIG_FILE"
    else
        return 0
    fi
}

# Get system info by number
get_system_info() {
    local sys_num=$1
    if command -v yq &> /dev/null; then
        yq eval ".systems.$sys_num" "$CONFIG_FILE"
    fi
}

# Display available systems
display_systems() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   Available Linux Systems${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if ! command -v yq &> /dev/null; then
        log_error "yq is required but not installed"
        echo "Install yq with: sudo apt-get install yq"
        return 1
    fi
    
    local count=$(yq eval '.systems | keys | length' "$CONFIG_FILE")
    
    for i in $(seq 1 "$count"); do
        local name=$(yq eval ".systems.$i.name" "$CONFIG_FILE")
        local hostname=$(yq eval ".systems.$i.hostname" "$CONFIG_FILE")
        local ip=$(yq eval ".systems.$i.ip_address" "$CONFIG_FILE")
        
        echo -e "${YELLOW}[$i]${NC} $name"
        echo "    Hostname: $hostname"
        echo "    IP: $ip"
        echo ""
    done
    
    echo -e "${BLUE}========================================${NC}"
}

# Confirm action
confirm() {
    local prompt="$1"
    local response
    
    echo -ne "${YELLOW}$prompt (yes/no): ${NC}"
    read -r response
    
    [[ "$response" =~ ^[Yy][Ee][Ss]$ ]]
}

# Execute with error handling
execute_cmd() {
    local cmd="$1"
    local description="$2"
    
    log_info "Executing: $description"
    if eval "$cmd"; then
        log_success "$description completed successfully"
        return 0
    else
        log_error "$description failed"
        return 1
    fi
}

# Update system packages
update_packages() {
    log_info "Updating system packages..."
    
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get upgrade -y
    elif command -v yum &> /dev/null; then
        yum update -y
    elif command -v dnf &> /dev/null; then
        dnf upgrade -y
    else
        log_warning "Unable to determine package manager"
        return 1
    fi
}

export -f log_info log_success log_warning log_error check_root display_systems confirm execute_cmd update_packages
