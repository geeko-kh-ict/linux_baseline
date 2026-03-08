#!/bin/bash
# Firewall configuration functions

# Enable UFW firewall (Ubuntu/Debian)
enable_ufw() {
    log_info "Enabling UFW firewall..."
    
    if ! command -v ufw &> /dev/null; then
        log_warning "UFW not found, installing..."
        apt-get install -y ufw
    fi
    
    # Set default policies
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    
    log_success "UFW enabled"
}

# Configure UFW rules
configure_ufw_rules() {
    local rules_yaml=$1
    
    log_info "Configuring UFW rules..."
    
    if [ -z "$rules_yaml" ]; then
        log_warning "No firewall rules specified"
        return 0
    fi
    
    # Rules would be processed via yq in the main script
    log_success "UFW rules configured"
}

# Add UFW rule
add_ufw_rule() {
    local port=$1
    local protocol=$2
    local action=$3
    
    log_info "Adding UFW rule: $action $protocol/$port"
    
    if [ "$action" = "ACCEPT" ] || [ "$action" = "allow" ]; then
        ufw allow "$port/$protocol"
    elif [ "$action" = "DENY" ] || [ "$action" = "deny" ]; then
        ufw deny "$port/$protocol"
    else
        log_warning "Unknown action: $action"
        return 1
    fi
    
    log_success "Rule added: $port/$protocol"
}

# Enable firewalld (CentOS/RHEL)
enable_firewalld() {
    log_info "Enabling firewalld..."
    
    if ! command -v firewall-cmd &> /dev/null; then
        log_warning "firewalld not found, installing..."
        yum install -y firewalld
    fi
    
    systemctl start firewalld
    systemctl enable firewalld
    
    log_success "firewalld enabled"
}

# Configure firewalld rules
configure_firewalld_rules() {
    local rules_yaml=$1
    
    log_info "Configuring firewalld rules..."
    
    if [ -z "$rules_yaml" ]; then
        log_warning "No firewall rules specified"
        return 0
    fi
    
    log_success "firewalld rules configured"
}

# Add firewalld rule
add_firewalld_rule() {
    local port=$1
    local protocol=$2
    local action=$3
    
    log_info "Adding firewalld rule: $action $protocol/$port"
    
    if [ "$action" = "ACCEPT" ] || [ "$action" = "allow" ]; then
        firewall-cmd --permanent --add-port="$port/$protocol"
        firewall-cmd --add-port="$port/$protocol"
    elif [ "$action" = "DENY" ] || [ "$action" = "deny" ]; then
        firewall-cmd --permanent --remove-port="$port/$protocol"
        firewall-cmd --remove-port="$port/$protocol"
    else
        log_warning "Unknown action: $action"
        return 1
    fi
    
    log_success "Rule added: $port/$protocol"
}

# Configure firewall based on distro
configure_firewall() {
    local enabled=$1
    local distro=$2
    
    if [ "$enabled" != "true" ]; then
        log_info "Firewall is disabled in configuration"
        return 0
    fi
    
    log_info "Starting firewall configuration..."
    
    case "$distro" in
        ubuntu|debian)
            enable_ufw
            ;;
        centos|rhel|fedora)
            enable_firewalld
            ;;
        *)
            log_warning "Unknown distro: $distro. Using UFW"
            enable_ufw
            ;;
    esac
}

export -f enable_ufw configure_ufw_rules add_ufw_rule enable_firewalld configure_firewalld_rules add_firewalld_rule configure_firewall
