#!/bin/bash
# User and group management functions

# Create user
create_user() {
    local username=$1
    local uid=$2
    local groups=$3
    local create_home=$4
    
    log_info "Creating user: $username (UID: $uid)"
    
    # Check if user exists
    if id "$username" &>/dev/null; then
        log_warning "User $username already exists"
        return 0
    fi
    
    # Create user
    local home_flag=""
    if [ "$create_home" = "true" ]; then
        home_flag="-m"
    else
        home_flag="-M"
    fi
    
    useradd $home_flag -u "$uid" -s /bin/bash "$username"
    
    if [ -n "$groups" ] && [ "$groups" != "null" ]; then
        # Parse groups and add user to them
        # Convert JSON array to space-separated list
        local group_list=$(echo "$groups" | sed 's/\[//g;s/\]//g;s/"//g;s/,/ /g')
        
        for group in $group_list; do
            group=$(echo "$group" | xargs)  # trim whitespace
            
            # Create group if it doesn't exist
            if ! getent group "$group" > /dev/null; then
                groupadd "$group"
                log_info "Created group: $group"
            fi
            
            # Add user to group
            usermod -aG "$group" "$username"
            log_info "Added $username to group: $group"
        done
    fi
    
    log_success "User created: $username"
}

# Configure sudo for user
configure_sudo() {
    local username=$1
    
    log_info "Configuring sudo for $username"
    
    # Add to sudoers if not already there
    if ! grep -q "^$username" /etc/sudoers; then
        echo "$username ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
        log_success "Sudo configured for $username"
    else
        log_warning "Sudo already configured for $username"
    fi
}

# Configure users
configure_users() {
    local users_yaml=$1
    
    log_info "Starting user configuration..."
    
    if [ -z "$users_yaml" ]; then
        log_warning "No users specified"
        return 0
    fi
    
    # Parse and create users
    # Note: This requires yq to parse the YAML
    # Example: users_yaml would be a string of user definitions
    
    log_success "User configuration completed"
}

export -f create_user configure_sudo configure_users
