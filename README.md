
# ubuntu_post_install

## Description

Ansible playbook and roles for post-install configuration of Ubuntu servers (VPS). Automates security, monitoring, web management, and development tool setup.

## Usage

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