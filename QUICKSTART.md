# Quick Start Guide

## Installation & Setup (5 minutes)

### 1. Clone or Download the Configuration Tool
The tool is ready in the `linux_baseline` directory.

### 2. Install Prerequisites
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y yq ipcalc

# CentOS/RHEL
sudo yum install -y yq ipcalc

# Fedora
sudo dnf install -y yq ipcalc
```

### 3. Setup and Navigate

**⚠️ IMPORTANT: Always run from the linux_baseline root directory**

```bash
# Navigate to linux_baseline root
cd /path/to/linux_baseline

# Make scripts executable
chmod +x scripts/baseline-config.sh
chmod +x scripts/deploy-remote.sh
chmod +x scripts/lib/*.sh

# Verify you're in the right directory
ls -la
# You should see: configs/ scripts/ *.md files
```

## Your First Configuration (15 minutes)

### Step 1: Review Default Systems
The tool comes with 3 example systems. View them:

```bash
cat configs/systems.yaml
```

You'll see:
- **System 1**: Web Server - Production (192.168.1.10)
- **System 2**: Database Server - Production (192.168.1.20)
- **System 3**: Development Server - Staging (192.168.1.30)

### Step 2: Customize for Your Environment

Edit the configuration file:
```bash
nano configs/systems.yaml
```

Change:
- Hostnames
- IP addresses & network settings
- Users and groups
- Packages to install
- Firewall rules
- SSH settings

Example modification:
```yaml
hostname: "myserver-01"  # Change to your hostname
ip_address: "10.0.0.10"  # Change to your IP
timezone: "America/New_York"  # Change to your timezone
distro: "ubuntu"  # Specify your Linux distro
```

### Step 3: Configure a Local System

If you want to configure the current machine:

```bash
# Make sure you're in the linux_baseline root directory!
cd /path/to/linux_baseline

# Run the configuration tool
sudo bash scripts/baseline-config.sh
```

Menu appears:
```
[1] Show available systems
[2] Configure a system (local)      ← Select this
[3] Configure a system (remote)
[4] Add new system to configuration
[5] View system configuration
[0] Exit
```

- Select option **2** (Configure locally)
- Choose system number (e.g., **1** for Web Server)
- Review the configuration
- Type **yes** to apply
- The tool will:
  - ✅ Set hostname
  - ✅ Configure network/IP
  - ✅ Set timezone
  - ✅ Update all packages
  - ✅ Create users
  - ✅ Set up firewall
  - ✅ Configure SSH

### Step 4: Configure Remote Systems

To configure a Linux system over the network:

```bash
sudo bash scripts/baseline-config.sh
```

- Select option **3** (Configure remotely)
- Choose system number
- Enter SSH username
- Confirm deployment
- Tool will copy scripts and apply configuration via SSH

## Working with Multiple Systems

### Adding a New System

```bash
sudo bash scripts/baseline-config.sh
```

- Select option **4** (Add new system)
- Fill in the details interactively
- Edit `configs/systems.yaml` for advanced options

### Deploying to Many Systems at Once

```bash
bash scripts/deploy-remote.sh
```

This alternative tool allows:
- Deploy to all systems with one command
- Test connectivity before deployment
- Generate deployment reports

## Common Tasks

### Change a System's Configuration

Edit `configs/systems.yaml`:
```bash
nano configs/systems.yaml
```

Modify the system's section and save.

### Add Users to a System

In `configs/systems.yaml`, find your system and modify the `users` section:

```yaml
users:
  - name: "admin"
    uid: 1001
    groups: ["sudo"]
    create_home: true
  - name: "newuser"      # Add this
    uid: 1002            # Add this
    groups: ["usergroup"] # Add this
    create_home: true    # Add this
```

### Install Additional Packages

In `configs/systems.yaml`, modify the `packages` section:

```yaml
packages:
  - "curl"
  - "wget"
  - "vim"
  - "neovim"             # Add this
  - "python3"            # Add this
  - "python3-pip"        # Add this
```

### Configure Firewall Rules

In `configs/systems.yaml`, modify the `firewall.rules` section:

```yaml
firewall:
  enabled: true
  rules:
    - port: 22
      protocol: "tcp"
      action: "ACCEPT"
      comment: "SSH"
    - port: 8080          # Add this
      protocol: "tcp"     # Add this
      action: "ACCEPT"    # Add this
      comment: "Web App"  # Add this
```

## Troubleshooting

### "No such file or directory" or "lib/lib" in error
This happens when running the script from the wrong directory.

```bash
# ❌ WRONG - Don't run from scripts directory
cd linux_baseline/scripts
bash baseline-config.sh

# ✅ CORRECT - Run from linux_baseline root
cd linux_baseline
sudo bash scripts/baseline-config.sh

# Make sure the directory structure looks like this:
# linux_baseline/
# ├── configs/
# │   └── systems.yaml
# ├── scripts/
# │   ├── baseline-config.sh
# │   └── lib/
# └── README.md
```

### "yq is not installed"
```bash
# Install yq
sudo apt-get install yq
```

### "Permission denied" on SSH
```bash
# Generate SSH key if you don't have one
ssh-keygen -t ed25519

# Copy public key to remote system
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@remote_host
```

### "Cannot connect to remote system"
```bash
# Test SSH connectivity manually
ssh -v user@192.168.1.10

# Check if SSH port is open
nc -zv 192.168.1.10 22
```

### "System locked out after SSH configuration"
Access the system via console and restore the backup:
```bash
sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## Best Practices

1. **Test First**: Always test on a non-production system first
2. **Backup**: The tool automatically backs up SSH config
3. **Review Output**: Read the configuration details before confirming
4. **Document Changes**: Keep notes of modifications to `configs/systems.yaml`
5. **Version Control**: Commit working configurations to git
6. **Security**: Keep `configs/systems.yaml` private if it contains sensitive data

## Next Steps

1. **Customize configs/systems.yaml** for your environment
2. **Test on a development system** first
3. **Deploy to production systems** when confident
4. **Use deploy-remote.sh** for multi-system deployments
5. **Maintain backups** of working configurations

## Getting Help

Review the full README.md for:
- Detailed configuration options
- Security considerations
- Advanced customization
- Project structure
- API reference

## Example Scenarios

### Scenario 1: Deploy web server configuration
```bash
# 1. Edit configs/systems.yaml
nano configs/systems.yaml

# 2. Update system 1 with your web server settings
# 3. Run configuration
sudo bash scripts/baseline-config.sh
# Select option 2, then system 1

# 4. Confirm the configuration
```

### Scenario 2: Add development machine to configuration
```bash
# 1. Run configuration tool
sudo bash scripts/baseline-config.sh

# 2. Select option 4 (Add new system)
# 3. Fill in the details
# 4. Edit configs/systems.yaml to customize further
nano configs/systems.yaml

# 5. Apply to the development machine
sudo bash scripts/baseline-config.sh
# Select option 2, then the new system number
```

### Scenario 3: Configure multiple remote servers
```bash
# 1. Update configs/systems.yaml with all servers
nano configs/systems.yaml

# 2. Use the remote deployment tool
bash scripts/deploy-remote.sh

# 3. Select option 2 (Deploy to all systems)
# 4. Enter SSH username and key path
# 5. Tool will deploy to all systems sequentially
```

---

**Ready to start?** Run this command:
```bash
cd linux_baseline
chmod +x scripts/baseline-config.sh
sudo bash scripts/baseline-config.sh
```
