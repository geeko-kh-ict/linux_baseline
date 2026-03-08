#!/bin/bash
# SSH configuration functions

# Backup original SSH config
backup_ssh_config() {
    local backup_file="/etc/ssh/sshd_config.backup.$(date +%s)"
    
    log_info "Backing up SSH config to $backup_file"
    cp /etc/ssh/sshd_config "$backup_file"
    
    log_success "SSH config backed up"
}

# Update SSH configuration
update_ssh_config() {
    local key=$1
    local value=$2
    
    # Comment out existing entry if present
    sed -i "/^$key /s/^/#/" /etc/ssh/sshd_config
    
    # Add new entry
    echo "$key $value" >> /etc/ssh/sshd_config
}

# Configure SSH
configure_ssh() {
    local permit_root=$1
    local password_auth=$2
    local pubkey_auth=$3
    local port=$4
    local max_auth=$5
    local client_alive=$6
    
    log_info "Starting SSH configuration..."
    
    # Backup original config
    backup_ssh_config
    
    # Update SSH configuration
    log_info "Setting PermitRootLogin: $permit_root"
    update_ssh_config "PermitRootLogin" "$permit_root"
    
    log_info "Setting PasswordAuthentication: $password_auth"
    update_ssh_config "PasswordAuthentication" "$password_auth"
    
    log_info "Setting PubkeyAuthentication: $pubkey_auth"
    update_ssh_config "PubkeyAuthentication" "$pubkey_auth"
    
    log_info "Setting Port: $port"
    update_ssh_config "Port" "$port"
    
    log_info "Setting MaxAuthTries: $max_auth"
    update_ssh_config "MaxAuthTries" "$max_auth"
    
    log_info "Setting ClientAliveInterval: $client_alive"
    update_ssh_config "ClientAliveInterval" "$client_alive"
    
    # Test SSH config
    if sshd -t; then
        log_success "SSH configuration is valid"
    else
        log_error "SSH configuration test failed"
        log_warning "Restoring original configuration"
        cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
        return 1
    fi
    
    # Restart SSH service
    log_info "Restarting SSH service..."
    systemctl restart sshd
    
    if systemctl is-active --quiet sshd; then
        log_success "SSH service restarted successfully"
    else
        log_error "Failed to restart SSH service"
        return 1
    fi
    
    log_success "SSH configuration completed"
}

# Harden SSH (additional security measures)
harden_ssh() {
    log_info "Applying SSH hardening..."
    
    # Disable root login
    update_ssh_config "PermitRootLogin" "no"
    
    # Disable password authentication
    update_ssh_config "PasswordAuthentication" "no"
    
    # Enable public key authentication
    update_ssh_config "PubkeyAuthentication" "yes"
    
    # Disable X11 forwarding
    update_ssh_config "X11Forwarding" "no"
    
    # Disable empty passwords
    update_ssh_config "PermitEmptyPasswords" "no"
    
    # Disable password prompt
    update_ssh_config "ChallengeResponseAuthentication" "no"
    
    # Set host key algorithms
    echo "HostKeyAlgorithms ssh-ed25519" >> /etc/ssh/sshd_config
    
    systemctl restart sshd
    log_success "SSH hardening applied"
}

export -f backup_ssh_config update_ssh_config configure_ssh harden_ssh
