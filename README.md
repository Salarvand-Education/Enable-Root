
```markdown
# Enable Root SSH Configuration Script

This script automates the process of enabling and configuring root access via SSH on your server. It includes:

- Backup of the current SSH configuration.
- Option to set a random or custom root password.
- Configuration of SSH settings such as port, authentication methods, and more.
- Restarting the SSH service with the new configuration.

## Quick Install

To quickly install and run the script, use the following command:

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Salarvand-Education/Enable-Root/main/Run.sh)"
```

This command will download and execute the script directly on your server.

---

### Notes:
- **Root Access Required**: Ensure you have `sudo` or root privileges to run the script.
- **Security Warning**: Be cautious when running scripts from external sources. Always review the script before execution.
- **Backup**: The script automatically backs up your current SSH configuration (`/etc/ssh/sshd_config.backup`) in case you need to revert changes.

For more details, check the script's repository: [GitHub Repository](https://github.com/Salarvand-Education/Enable-Root)
