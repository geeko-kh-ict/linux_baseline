# Linux Baseline Configuration Tool

A comprehensive Linux system configuration tool that allows you to define baseline configurations for multiple Linux systems and apply them either locally or remotely.

## Features

- 🎯 **Multiple System Management** - Define and manage configurations for multiple Linux systems
- 🖥️ **Interactive Menu Interface** - User-friendly CLI for selecting and applying configurations
- 🔧 **Comprehensive Configuration** - Hostname, network, users, firewall, packages, and SSH settings
- 💻 **Multi-Distro Support** - Works with Ubuntu, Debian, CentOS, RHEL, and Fedora
- 🌐 **Local & Remote Deployment** - Configure systems locally or remotely via SSH
- 📝 **YAML-based Configuration** - Easy-to-read and edit YAML configuration files
- 🔒 **Security-Focused** - Includes SSH hardening and firewall configuration options

## Prerequisites

### System Requirements
- Linux system (Ubuntu 18.04+, CentOS 7+, Debian 10+, Fedora 30+)
- Bash 4.0 or higher
- Root or sudo access for local configuration
- SSH access for remote configuration

### Required Tools
- `yq` - YAML parser and query tool
- `ipcalc` - IP calculator (for network configuration on some systems)
- Standard utilities: `curl`, `wget`, `git` (installed by the tool)

### Installation of Prerequisites

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y yq ipcalc
```

**CentOS/RHEL:**
```bash
sudo yum install -y yq ipcalc
```

**Fedora:**
```bash
sudo dnf install -y yq ipcalc
```

## Project Structure

```
linux_baseline/
├── configs/
│   └── systems.yaml              # System definitions and configurations
├── scripts/
│   ├── baseline-config.sh        # Main interactive configuration script
│   ├── deploy-remote.sh          # Helper script for remote deployment
│   └── lib/
│       ├── common.sh             # Common functions (logging, utilities)
│       ├── network.sh            # Network configuration functions
│       ├── users.sh              # User and group management
│       ├── firewall.sh           # Firewall configuration
│       ├── packages.sh           # Package installation
│       └── ssh.sh                # SSH configuration
├── README.md                     # This file
└── .gitignore                    # Git ignore patterns
```

## Configuration File Structure

The `configs/systems.yaml` file contains system definitions with the following structure:

```yaml
systems:
  1:
    name: "System Name"               # Descriptive name
    hostname: "hostname"              # System hostname
    ip_address: "192.168.1.10"       # IP address
    netmask: "255.255.255.0"         # Netmask
    gateway: "192.168.1.1"           # Default gateway
    dns_primary: "8.8.8.8"           # Primary DNS
    dns_secondary: "8.8.4.4"         # Secondary DNS
    timezone: "UTC"                   # Timezone (e.g., UTC, America/New_York)
    distro: "ubuntu"                 # Distribution (ubuntu, debian, centos, rhel, fedora)
    
    network:
      interface: "eth0"               # Network interface name
      dhcp: false                     # DHCP enabled (true/false)
    
    users:                            # List of users to create
      - name: "username"
        uid: 1001
        groups: ["sudo", "wheel"]    # Groups to add user to
        create_home: true
    
    firewall:
      enabled: true                   # Enable/disable firewall
      rules:                          # Firewall rules
        - port: 22
          protocol: "tcp"
          action: "ACCEPT"
          comment: "SSH"
    
    packages:                         # Packages to install
      - "package1"
      - "package2"
    
    ssh:
      permit_root_login: "no"        # Allow root login
      password_authentication: "no"   # Allow password auth
      pubkey_authentication: "yes"    # Allow key-based auth
      port: 22                        # SSH port
      max_auth_tries: 3              # Max authentication attempts
      client_alive_interval: 300     # Keep-alive interval (seconds)
```

## Usage

### Step 1: Prepare Configuration File

Edit `configs/systems.yaml` to define your systems:

```bash
nano configs/systems.yaml
```

Add your systems with their configurations. The file comes with 3 example systems.

### Step 2: Run the Main Script

**⚠️ Important:** Always run this script from the `linux_baseline` root directory, not from the `scripts/` directory.

```bash
# Navigate to the linux_baseline root directory
cd /path/to/linux_baseline

# Make the script executable
chmod +x scripts/baseline-config.sh

# Run the script
sudo bash scripts/baseline-config.sh
```

### Step 3: Select an Option from the Menu

```
1. Show available systems       - List all configured systems
2. Configure a system (local)   - Apply configuration directly to current system
3. Configure a system (remote)  - Configure a remote system via SSH
4. Add new system              - Interactively add a new system
5. View system configuration   - Display a system's configuration
0. Exit                        - Exit the tool
```

## Examples

### Example 1: Configure Web Server - Production

1. Run the script: `sudo bash scripts/baseline-config.sh`
2. Select option `2` (Configure a system - local)
3. Select system `1` (Web Server - Production)
4. Review the configuration and confirm
5. The tool will apply all configurations:
   - Set hostname to `web-prod-01`
   - Configure IP: `192.168.1.10/24`
   - Configure timezone
   - Update packages
   - Create users (`admin`, `appuser`)
   - Enable and configure firewall (UFW on Ubuntu)
   - Install packages
   - Configure SSH

### Example 2: Configure Remote Database Server

1. Run the script: `sudo bash scripts/baseline-config.sh`
2. Select option `3` (Configure a system - remote)
3. Select system `2` (Database Server - Production)
4. Enter the SSH username (e.g., `ubuntu`)
5. Confirm the deployment
6. The tool will:
   - Copy scripts to the remote system
   - Execute the baseline configuration remotely
   - Apply all settings via SSH

### Example 3: Add a New System

1. Run the script: `sudo bash scripts/baseline-config.sh`
2. Select option `4` (Add new system)
3. Fill in the prompted details:
   - System name
   - Hostname
   - IP address
   - Netmask
   - Gateway
   - DNS servers
   - Timezone
   - Linux distribution
4. The system will be added to `configs/systems.yaml`
5. Edit the YAML file to add more details (users, packages, firewall rules, etc.)

## Configuration Details

### Network Configuration

- **Ubuntu/Debian**: Uses Netplan (`/etc/netplan/01-netcfg.yaml`)
- **CentOS/RHEL**: Uses ifcfg (`/etc/sysconfig/network-scripts/`)
- Supports both static IP and DHCP configurations
- Automatically configures DNS settings

### User Management

- Creates users with specified UIDs
- Adds users to specified groups
- Optionally creates home directories
- Sudo access can be configured

### Firewall Configuration

- **Ubuntu/Debian**: Uses UFW (Uncomplicated Firewall)
- **CentOS/RHEL**: Uses firewalld
- Supports TCP/UDP rules
- Default deny incoming, allow outgoing policy

### Package Management

- **Ubuntu/Debian**: Uses `apt-get`
- **CentOS/RHEL**: Uses `yum`
- **Fedora**: Uses `dnf`
- Automatically updates package cache before installation

### SSH Hardening

- Disables root login
- Disables password authentication
- Enables public key authentication
- Configurable SSH port
- Sets maximum authentication attempts
- Configures keep-alive settings
- Backs up original SSH configuration

## Security Considerations

1. **Private Storage**: Keep `configs/systems.yaml` in a private repository or secure location
2. **Credentials**: Ensure SSH keys are properly configured for remote access
3. **Backups**: The tool creates backups of `/etc/ssh/sshd_config` before modification
4. **Testing**: Test configurations in non-production environments first
5. **Logging**: All operations are logged for audit purposes

## Troubleshooting

### "No such file or directory" with "lib/lib" in the path

This error occurs when the script is executed from the wrong directory.

```bash
# ❌ WRONG - Don't run from the scripts directory:
cd linux_baseline/scripts/
bash baseline-config.sh
# Error: No such file or directory (with lib/lib path)

# ✅ CORRECT - Run from the linux_baseline root directory:
cd linux_baseline
sudo bash scripts/baseline-config.sh
# Works correctly!
```

**Solution**: Always run the script from the `linux_baseline` root directory.

### yq Not Found

```bash
# Install yq
sudo apt-get install yq

# Or with pip
pip install yq
```

### SSH Connection Failed

```bash
# Ensure SSH key is available
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519

# Add public key to remote system
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@remote_host
```

### Permission Denied

- Local configuration requires root access: use `sudo`
- Remote configuration requires SSH key authentication
- Ensure the user has sudo privileges on the remote system

### Firewall Locked Out

If you configure firewall rules and lock yourself out:

1. Access the system via console or another method
2. Restore from backup: `cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config`
3. Restart SSH: `systemctl restart sshd`

## Customization

### Modify System Configuration

Edit `configs/systems.yaml` directly:

```bash
nano configs/systems.yaml
```

### Add Custom Functions

Create new library files in `scripts/lib/`:

```bash
cat > scripts/lib/docker.sh << 'EOF'
#!/bin/bash
# Custom Docker configuration functions

install_docker() {
    log_info "Installing Docker..."
    # Your custom implementation
}

export -f install_docker
EOF
```

### Extend Main Script

Add new menu options in `scripts/baseline-config.sh`:

```bash
source "${SCRIPT_DIR}/lib/docker.sh"

# In the menu case statement:
6)
    install_docker
    ;;
```

## Log Output Example

```
[INFO] Starting network configuration...
[INFO] Configuring static IP on eth0: 192.168.1.10/24
[SUCCESS] Static IP configured
[INFO] Creating user: admin (UID: 1001)
[INFO] Added admin to group: sudo
[SUCCESS] User created: admin
[INFO] Enabling UFW firewall...
[SUCCESS] UFW enabled
[INFO] Adding UFW rule: allow tcp/22
[SUCCESS] Rule added: 22/tcp
```

## Backup and Recovery

The tool automatically creates backups of critical files:

- **SSH Config**: `/etc/ssh/sshd_config.backup.<timestamp>`
- **Netplan Config** (Ubuntu/Debian): `/etc/netplan/01-netcfg.yaml.backup` (optional)

To restore:

```bash
sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## Contributing

To contribute improvements:

1. Test changes in a non-production environment
2. Update configuration examples if applicable
3. Document new features in the README
4. Follow existing code style and conventions

## License

This project is open source. Modify and distribute as needed for your environment.

## Support

For issues or questions:

1. Check the Troubleshooting section
2. Review the script output for error messages
3. Verify all prerequisites are installed
4. Test with a single system first

## Version History

### v1.0 (Current)
- Initial release
- Support for Ubuntu, Debian, CentOS, RHEL, Fedora
- Comprehensive baseline configuration
- Local and remote deployment
- Interactive menu interface

---

**Last Updated**: March 8, 2026  
**Maintainer**: Linux Baseline Configuration Team
