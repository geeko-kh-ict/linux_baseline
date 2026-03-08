#!/bin/bash
# Package installation functions

# Install packages (Debian/Ubuntu)
install_packages_apt() {
    local packages=$1
    
    log_info "Installing packages via apt..."
    
    apt-get update
    
    if [ -z "$packages" ] || [ "$packages" = "null" ]; then
        log_warning "No packages specified"
        return 0
    fi
    
    # Parse package list from JSON array
    # Convert JSON array to space-separated list
    local pkg_list=$(echo "$packages" | sed 's/\[//g;s/\]//g;s/"//g;s/,/ /g')
    
    for package in $pkg_list; do
        package=$(echo "$package" | xargs)  # trim whitespace
        
        log_info "Installing: $package"
        apt-get install -y "$package"
        
        if [ $? -eq 0 ]; then
            log_success "Installed: $package"
        else
            log_warning "Failed to install: $package"
        fi
    done
}

# Install packages (CentOS/RHEL)
install_packages_yum() {
    local packages=$1
    
    log_info "Installing packages via yum..."
    
    if [ -z "$packages" ] || [ "$packages" = "null" ]; then
        log_warning "No packages specified"
        return 0
    fi
    
    # Parse package list from JSON array
    # Convert JSON array to space-separated list
    local pkg_list=$(echo "$packages" | sed 's/\[//g;s/\]//g;s/"//g;s/,/ /g')
    
    for package in $pkg_list; do
        package=$(echo "$package" | xargs)  # trim whitespace
        
        log_info "Installing: $package"
        yum install -y "$package"
        
        if [ $? -eq 0 ]; then
            log_success "Installed: $package"
        else
            log_warning "Failed to install: $package"
        fi
    done
}

# Install packages (Fedora)
install_packages_dnf() {
    local packages=$1
    
    log_info "Installing packages via dnf..."
    
    if [ -z "$packages" ] || [ "$packages" = "null" ]; then
        log_warning "No packages specified"
        return 0
    fi
    
    # Parse package list from JSON array
    # Convert JSON array to space-separated list
    local pkg_list=$(echo "$packages" | sed 's/\[//g;s/\]//g;s/"//g;s/,/ /g')
    
    for package in $pkg_list; do
        package=$(echo "$package" | xargs)  # trim whitespace
        
        log_info "Installing: $package"
        dnf install -y "$package"
        
        if [ $? -eq 0 ]; then
            log_success "Installed: $package"
        else
            log_warning "Failed to install: $package"
        fi
    done
}

# Configure packages based on distro
install_packages() {
    local packages=$1
    local distro=$2
    
    if [ -z "$packages" ] || [ "$packages" = "null" ]; then
        log_info "No packages specified"
        return 0
    fi
    
    log_info "Starting package installation..."
    
    case "$distro" in
        ubuntu|debian)
            install_packages_apt "$packages"
            ;;
        centos|rhel)
            install_packages_yum "$packages"
            ;;
        fedora)
            install_packages_dnf "$packages"
            ;;
        *)
            log_warning "Unknown distro: $distro. Attempting apt installation"
            install_packages_apt "$packages"
            ;;
    esac
    
    log_success "Package installation completed"
}

export -f install_packages_apt install_packages_yum install_packages_dnf install_packages
