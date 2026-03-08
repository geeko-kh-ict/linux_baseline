# System Architecture

## Overview

The Linux Baseline Configuration Tool is a modular, extensible system for applying standardized configurations to multiple Linux systems. It provides both interactive local and remote deployment capabilities.

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────┐
│  User Interface (Interactive Menu)                       │
│  - Command-line menu system                              │
│  - User input validation                                 │
│  - Configuration viewing & management                    │
└─────────────────────┬──────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
        ▼             ▼             ▼
   ┌─────────┐  ┌──────────┐  ┌──────────────┐
   │ Local   │  │ Remote   │  │ Configuration│
   │ Config  │  │ Deployment   Management   │
   └────┬────┘  └────┬─────┘  └──────┬───────┘
        │            │               │
        └────────────┼───────────────┘
                     │
        ┌────────────▼────────────┐
        │   YAML Configuration    │
        │   (systems.yaml)        │
        └────────────┬────────────┘
                     │
        ┌────────────▼────────────┐
        │  Library Functions      │
        │  (Modular Components)   │
        └────┬──────┬──────┬────┬─┘
        │      │      │      │
   ┌────▼──┐┌──▼──┐┌─▼──┐┌─┼──┐
   │Network││Users││Fire││Package   │
   │Config ││Config││wall││SSH      │
   └───────┘└─────┘└────┘└──────┘
        │
        ▼
    ┌─────────────────────┐
    │ Linux System Config │
    │ - Hostname          │
    │ - Network           │
    │ - Users             │
    │ - Firewall          │
    │ - SSH               │
    │ - Packages          │
    └─────────────────────┘
```

## Core Components

### 1. Main Script (`baseline-config.sh`)

**Purpose**: Interactive CLI interface and orchestration  
**Responsibilities**:
- Display menu and handle user input
- Coordinate library function calls
- Manage configuration workflow
- Log operations and provide feedback

**Key Functions**:
- `show_menu()` - Display main menu
- `configure_system_local()` - Apply config locally
- `configure_system_remote()` - Deploy via SSH
- `add_new_system()` - Add system to configuration
- `view_system_config()` - Display system details
- `main()` - Main event loop

### 2. Configuration File (`systems.yaml`)

**Format**: YAML (human-readable)  
**Purpose**: Central repository for system definitions  
**Structure**:
```
systems:
  1: System definition
  2: System definition
  3: System definition
```

**Contents Per System**:
- Basic info (name, hostname, IP, timezone)
- Network configuration
- User definitions
- Firewall rules
- Package list
- SSH settings

### 3. Library Modules (`lib/`)

#### `common.sh`
**Purpose**: Shared utilities and logging  
**Functions**:
- Logging: `log_info()`, `log_success()`, `log_warning()`, `log_error()`
- Root checks: `check_root()`
- YAML parsing: `parse_yaml()`, `get_system_info()`
- UI: `display_systems()`, `confirm()`
- System: `update_packages()`, `execute_cmd()`

#### `network.sh`
**Purpose**: Network configuration  
**Key Areas**:
- Hostname configuration (hostnamectl, /etc/hosts)
- Static IP configuration
  - Netplan for Debian/Ubuntu
  - ifcfg for CentOS/RHEL
- DNS configuration
- Timezone setup
- Multi-distro support

**Functions**:
- `configure_hostname()` - Set system hostname
- `configure_ip_netplan()` - Ubuntu/Debian networking
- `configure_ip_ifcfg()` - CentOS/RHEL networking
- `configure_timezone()` - Set timezone
- `configure_network()` - Dispatcher function

#### `users.sh`
**Purpose**: User and group management  
**Features**:
- User creation with custom UIDs
- Group management
- Group membership
- Home directory creation/skipping
- Sudo configuration

**Functions**:
- `create_user()` - Create user with groups
- `configure_sudo()` - Add sudo access
- `configure_users()` - Batch user processing

#### `firewall.sh`
**Purpose**: Firewall configuration  
**Support**:
- UFW (Ubuntu/Debian)
- firewalld (CentOS/RHEL/Fedora)
- Port-based rules (TCP/UDP)
- Accept/Deny actions

**Functions**:
- `enable_ufw()` - Initialize UFW
- `add_ufw_rule()` - Add UFW rule
- `enable_firewalld()` - Initialize firewalld
- `add_firewalld_rule()` - Add firewalld rule
- `configure_firewall()` - Dispatcher

#### `packages.sh`
**Purpose**: Package installation  
**Support**:
- apt (Debian/Ubuntu)
- yum (CentOS/RHEL)
- dnf (Fedora)
- Package list from YAML

**Functions**:
- `install_packages_apt()` - Debian/Ubuntu
- `install_packages_yum()` - CentOS/RHEL
- `install_packages_dnf()` - Fedora
- `install_packages()` - Dispatcher

#### `ssh.sh`
**Purpose**: SSH configuration and hardening  
**Features**:
- SSH config file management
- Auto-backup before changes
- Configuration validation
- Service management
- Security hardening

**Functions**:
- `backup_ssh_config()` - Create backup
- `update_ssh_config()` - Modify SSH config
- `configure_ssh()` - Apply SSH settings
- `harden_ssh()` - Apply security hardening

### 4. Remote Deployment Helper (`deploy-remote.sh`)

**Purpose**: Batch remote deployments  
**Features**:
- Single or multi-system deployment
- Connectivity testing
- Progress reporting
- Deployment reports

**Key Functions**:
- `deploy_to_system()` - Deploy to one system
- `deploy_all_systems()` - Deploy to all systems
- `test_connectivity()` - Verify SSH access
- `generate_report()` - Create deployment report

## Data Flow

### Local Configuration Flow

```
User → Menu
  │
  ├→ Show Systems (display_systems)
  │   └→ Parse YAML
  │       └→ Display available systems
  │
  ├→ Configure System
  │   ├→ Validate input
  │   ├→ Get system config
  │   ├→ Show preview
  │   ├→ Confirm action
  │   │
  │   └→ Apply Configuration
  │       ├→ Network setup
  │       │   └→ Timezone, Hostname, IP
  │       ├→ Package update
  │       ├→ User creation
  │       ├→ Firewall setup
  │       ├→ Package installation
  │       └→ SSH configuration
  │
  └→ Report completion
```

### Remote Configuration Flow

```
User → Menu
  │
  ├→ Configure Remote System
  │   ├→ Get system config
  │   ├→ Show preview
  │   ├→ Get SSH credentials
  │   ├→ Test connectivity
  │   │
  │   └→ Deploy
  │       ├→ Copy scripts via SCP
  │       ├→ Copy configuration
  │       └→ Execute local config script
  │           └→ Apply all configurations remotely
  │
  └→ Report completion
```

## Configuration Processing

```
YAML File
    │
    ├→ Read by yq
    │
    ├→ Extract system definition
    │
    └→ Process sections
        ├→ Basic info (name, hostname, IP)
        ├→ Network
        │   ├→ Interface
        │   └→ DHCP setting
        ├→ Users
        │   ├→ Name, UID
        │   └→ Groups
        ├→ Firewall
        │   └→ Rules list
        ├→ Packages
        │   └→ Package list
        └→ SSH
            ├→ Permissions
            └→ Settings
```

## Multi-Distro Support

```
System Detection
    │
    ├─→ Network Config
    │   ├─→ Ubuntu/Debian → Netplan
    │   └─→ CentOS/RHEL → ifcfg
    │
    ├─→ Firewall Config
    │   ├─→ Ubuntu/Debian → UFW
    │   └─→ CentOS/RHEL → firewalld
    │
    └─→ Package Manager
        ├─→ Ubuntu/Debian → apt
        ├─→ CentOS/RHEL → yum
        └─→ Fedora → dnf
```

## Extension Points

### Add New Configuration Module

1. **Create new library file** (`scripts/lib/newfeature.sh`)
   ```bash
   #!/bin/bash
   # New configuration functions
   
   configure_newfeature() {
       local param=$1
       # Implementation
   }
   
   export -f configure_newfeature
   ```

2. **Source in main script** (`baseline-config.sh`)
   ```bash
   source "${SCRIPT_DIR}/lib/newfeature.sh"
   ```

3. **Add menu option**
   ```bash
   6)
       configure_newfeature "param"
       ;;
   ```

4. **Add to YAML schema**
   ```yaml
   newfeature:
       param: value
   ```

### Support New Distribution

1. **Add detection** in dispatcher functions
   ```bash
   case "$distro" in
       newdistro)
           new_distro_function
           ;;
   esac
   ```

2. **Implement distribution-specific functions**
   ```bash
   configure_ip_newdistro() {
       # Implementation
   }
   ```

## Error Handling

- **Pre-flight checks**: Dependencies, root access, file existence
- **Validation**: User input, YAML structure, SSH connectivity
- **Safe operations**: Backup before modification, test configurations
- **Recovery**: Restore backups if operations fail
- **Logging**: All operations logged for audit trail

## Security Model

### Authentication
- **Local**: Root access required
- **Remote**: SSH key-based authentication

### Authorization
- **Root execution**: Required for system modifications
- **Sudo configuration**: Managed through user creation

### Configuration Protection
- **File permissions**: YAML should have restricted permissions
- **Backups**: Critical files backed up before modification
- **Validation**: YAML structure validated before application

### SSH Hardening
- **Root login**: Can be disabled
- **Password auth**: Can be disabled
- **Key-based auth**: Preferred method
- **Port**: Configurable
- **Authentication attempts**: Limit configurable

## Performance Considerations

- **Parallel Operations**: Non-dependent tasks could be parallelized
- **Package Installation**: Largest time consumer, batched by package manager
- **Network Operations**: Sequential to maintain control and visibility
- **YAML Parsing**: Single parse per system configuration

## Scalability

### Current Limitations
- Uses simple shell scripting
- YAML files are human-readable (not optimized for large scale)
- Sequential processing

### Potential Improvements
- Use Python for complex operations
- Use database backend for configurations
- Implement parallel remote deployments
- Add caching mechanisms
- Add incremental/diff-based updates

## Maintenance

### Backup Strategy
- SSH config backed up before modification: `/etc/ssh/sshd_config.backup.<timestamp>`
- Original files preserved for recovery

### Logging
- All operations logged to stdout
- Color-coded output for easy reading
- Timestamps available in logs

### Validation
- SSH config tested before restart
- Network connectivity verified
- User creation validated

## Future Enhancements

- [ ] Support for container image generation
- [ ] Configuration drift detection
- [ ] Rollback capabilities
- [ ] Audit logging to central syslog
- [ ] Integration with configuration management (Ansible, Puppet)
- [ ] Multi-system parallel deployment
- [ ] Web-based management interface
- [ ] System health checks and monitoring
- [ ] Compliance reporting

---

**Design Philosophy**: Simple, modular, and maintainable. Each component has a single responsibility and can be tested independently.
