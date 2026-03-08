#!/bin/bash
# Network configuration functions

# Configure hostname
configure_hostname() {
    local hostname=$1
    
    log_info "Configuring hostname: $hostname"
    
    hostnamectl set-hostname "$hostname"
    
    if [ -f /etc/hosts ]; then
        sed -i "s/127\.0\.1\.1.*/127.0.1.1 $hostname/" /etc/hosts
    fi
    
    log_success "Hostname configured: $hostname"
}

# Configure static IP address (Netplan for Ubuntu/Debian)
configure_ip_netplan() {
    local interface=$1
    local ip=$2
    local netmask=$3
    local gateway=$4
    local dns_primary=$5
    local dns_secondary=$6
    
    log_info "Configuring static IP on $interface: $ip/$netmask"
    
    # Convert netmask to CIDR
    local cidr=$(ipcalc -p "$netmask" | cut -d'=' -f2)
    
    cat > /etc/netplan/01-netcfg.yaml << EOF
network:
  version: 2
  ethernets:
    $interface:
      dhcp4: no
      addresses:
        - ${ip}/${cidr}
      gateway4: $gateway
      nameservers:
        addresses:
          - $dns_primary
          - $dns_secondary
EOF
    
    netplan apply
    log_success "Static IP configured"
}

# Configure static IP address (ifcfg for CentOS/RHEL)
configure_ip_ifcfg() {
    local interface=$1
    local ip=$2
    local netmask=$3
    local gateway=$4
    local dns_primary=$5
    local dns_secondary=$6
    
    log_info "Configuring static IP on $interface: $ip/$netmask"
    
    cat > /etc/sysconfig/network-scripts/ifcfg-"$interface" << EOF
TYPE=Ethernet
BOOTPROTO=none
NAME=$interface
DEVICE=$interface
ONBOOT=yes
IPADDR=$ip
NETMASK=$netmask
GATEWAY=$gateway
DNS1=$dns_primary
DNS2=$dns_secondary
EOF
    
    systemctl restart network
    log_success "Static IP configured"
}

# Configure timezone
configure_timezone() {
    local timezone=$1
    
    log_info "Configuring timezone: $timezone"
    
    timedatectl set-timezone "$timezone"
    
    log_success "Timezone configured: $timezone"
}

# Configure network based on distro
configure_network() {
    local interface=$1
    local ip=$2
    local netmask=$3
    local gateway=$4
    local dns_primary=$5
    local dns_secondary=$6
    local distro=$7
    
    log_info "Starting network configuration..."
    
    case "$distro" in
        ubuntu|debian)
            configure_ip_netplan "$interface" "$ip" "$netmask" "$gateway" "$dns_primary" "$dns_secondary"
            ;;
        centos|rhel|fedora)
            configure_ip_ifcfg "$interface" "$ip" "$netmask" "$gateway" "$dns_primary" "$dns_secondary"
            ;;
        *)
            log_warning "Unknown distro: $distro. Using netplan configuration"
            configure_ip_netplan "$interface" "$ip" "$netmask" "$gateway" "$dns_primary" "$dns_secondary"
            ;;
    esac
}

export -f configure_hostname configure_ip_netplan configure_ip_ifcfg configure_timezone configure_network
