

# ubuntu_post_install

## Local Validation

After making changes, you can validate your playbook and roles locally:

```bash
./validate.sh
```

This script will:

- Run an Ansible syntax check
- Run ansible-lint (if installed)
- Run a dry-run (check mode) of your playbook

If you see no errors, your playbook is ready!

## Description

Ansible playbook and roles for post-install configuration of Ubuntu servers (VPS). Automates security, monitoring, web management, and development tool setup.

## Usage
### Optional: Create the 'seb' user

You can optionally create a user named `seb` with sudo privileges (NOPASSWD) by setting the `create_seb_user` variable to `true` and providing a password via the `seb_password` variable. This is supported both locally and in the GitHub Actions workflow.

**Example (local run):**

```bash
ansible-playbook -i inventory playbook.yml --extra-vars "create_seb_user=true seb_password='yourpassword'"
```

**In GitHub Actions:**

When running the workflow manually, you will be prompted for:

- `create_seb_user`: Set to `true` to create the user
- `seb_password`: The password for the new user

If you do not want to create the user, leave `create_seb_user` as `false` (default).
1. Clone this repository:

   ```bash
   git clone https://github.com/bikininjas/ubuntu_post_install.git
   cd ubuntu_post_install
   ```

2. Edit `inventory` to add your server(s) under the `[vps]` group.

3. Edit `playbook.yml` as needed (e.g., set `ssh_port`).

4. Run the playbook:

   ```bash
   ansible-playbook -i inventory playbook.yml
   ```

## Roles

- `common`: System update and cleanup
- `security`: SSH hardening, UFW firewall
- `web_management`: Cockpit installation
- `monitoring`: Fail2ban setup
- `dev_tools`: Installs Git, Go, Node.js, Python, Docker

## Notes

- Ensure you have Ansible installed: `pip install ansible`
- Run as a user with sudo privileges.
- The playbook now sets the timezone to Europe/Paris and system language to English (en_US.UTF-8) on all servers (common role).
- All apt packages are updated before any roles run (pre-task in playbook).
- Docker repository setup is compatible with Ubuntu 22.04+ (uses signed-by keyring).
- After all roles, the playbook runs post-setup checks to ensure SSH is not open on port 22, HTTP/HTTPS are open, and only expected ports are accessible (see common/tasks/verify.yml).
- Each role now includes cleanup steps to remove old/conflicting packages and configurations before installing or configuring new ones. This ensures a clean, idempotent setup every time.

- UFW rules for HTTP/HTTPS use port numbers (80, 443) instead of application names because UFW profiles 'http' and 'https' may not exist on all systems.

---

Maintained by bikininjas


## CI/CD: GitHub Actions Workflow

This repository includes a GitHub Actions workflow to automate VPS configuration using Ansible:

- **Manual trigger**: Go to the "Actions" tab and run the `Configure VPS` workflow.
- **Two-step process**:
  1. Changes the SSH port (connects on port 22, runs only security tasks).
  2. Provisions the server (connects on the new port, runs all other tasks).
- **Secrets required**:
  - `VPSZ_SSH_KEY`: Your private SSH key for the VPS.
  - `VPS_HOST`: The IP or hostname of your VPS.
  - `VPS_USER`: The SSH username.

- **Caching**: The workflow caches Python pip modules to speed up Ansible installation.

See `.github/workflows/configure-vps.yml` for details.