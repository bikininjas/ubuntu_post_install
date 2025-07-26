# Ubuntu Server Setup (for Everyone)

This project helps you set up your Ubuntu server automatically. You don't need to be a computer expert!

## Quick Start

1. **Install Ansible**

   Open a terminal and type:
   
   ```bash
   
   ```bash

   pip install ansible

   ```bash


2. **Download this project**

   In the terminal, type:
   
   ```bash
   
   ```bash
   git clone https://github.com/bikininjas/ubuntu_post_install.git
   cd ubuntu_post_install

   ```
   
   ```


3. **Tell the computer about your server**


   Open the file called `inventory` in a text editor. Add your server's address (ask someone if you don't know it).


4. **Run the setup**


   In the terminal, type:

   ```bash
   ansible-playbook -i inventory playbook.yml
   ```


5. **Check your work (optional, but recommended!)**

   In the terminal, type:
   ```bash
   ./local-validation.sh
   ```
   If you see "Validation complete" and no errors, everything is good!

---

## What does this do?

- Makes your server safer
- Installs useful programs (like Docker, Git, Python, Node.js)
- Sets up web management and monitoring
- Keeps your server up to date

---


## GitHub Actions

This project includes a GitHub Actions workflow that will run automatically on every push to this repository. It checks your setup and helps keep everything working.

---

## Need help?

Ask a friend or family member who knows computers, or open an issue on GitHub.

---

Maintained by bikininjas


   


Ansible playbook and roles for post-install configuration of Ubuntu servers (VPS). Automates security, monitoring, web management, and development tool setup.
This repository provides a comprehensive Ansible playbook and roles to automate the post-installation configuration of Ubuntu servers (VPS). It includes tasks for security hardening, monitoring setup, web management, and development tool installation.

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

This script will:

- Run an Ansible syntax check
- Run ansible-lint (if installed)
- Run a dry-run (check mode) of your playbook

If you see no errors, your playbook is ready!

## Description

Ansible playbook and roles for post-install configuration of Ubuntu servers (VPS).
Automates security, monitoring, web management, and development tool setup.

Ansible playbook and roles for post-install configuration of Ubuntu servers (VPS). Automates security, monitoring, web management, and development tool setup.

## Usage

1. Clone this repository:

   ```bash
   git clone https://github.com/bikininjas/ubuntu_post_install.git
   cd ubuntu_post_install
   ```bash
   ```bash

2. Edit `inventory` to add your server(s) under the `[vps]` group.

3. Edit `playbook.yml` as needed (e.g., set `ssh_port`).

4. Run the playbook:

   ```bash
   ansible-playbook -i inventory playbook.yml
   
   ```bash
   
   ```bash
   
### Optional: Create the 'seb' user

You can optionally create a user named `seb` with sudo privileges (NOPASSWD) by
setting the `create_seb_user` variable to `true` and providing a password via the
`seb_password` variable. This is supported both locally and in the GitHub Actions
workflow.

```bash
ansible-playbook -i inventory playbook.yml --extra-vars "create_seb_user=true seb_password='yourpassword'"
```

**In GitHub Actions:**

If you do not want to create the user, leave `create_seb_user` as `false` (default).



**In GitHub Actions:**
When running the workflow manually, you will be prompted for:

- `create_seb_user`: Set to `true` to create the user

1. Clone this repository:

   ```bash
   cd ubuntu_post_install
   ```

2. Edit `inventory` to add your server(s) under the `[vps]` group.

4. Run the playbook:
   
   ```bash
   
   ```bash
   ansible-playbook -i inventory playbook.yml
   ```


- `common`: System update and cleanup
- `security`: SSH hardening, UFW firewall
- `web_management`: Cockpit installation
- `monitoring`: Fail2ban setup
- `dev_tools`: Installs Git, Go, Node.js, Python, Docker

- `common`: System update and cleanup
- `security`: SSH hardening, UFW firewall
- `web_management`: Cockpit installation
- `monitoring`: Fail2ban setup
- `dev_tools`: Installs Git, Go, Node.js, Python, Docker

## Notes

- Ensure you have Ansible installed: `pip install ansible`
- Run as a user with sudo privileges.
- The playbook now sets the timezone to Europe/Paris and system language to
  English (en_US.UTF-8) on all servers (common role).
- All apt packages are updated before any roles run (pre-task in playbook).
- Docker repository setup is compatible with Ubuntu 22.04+ (uses signed-by keyring).
- After all roles, the playbook runs post-setup checks to ensure SSH is not open
  on port 22, HTTP/HTTPS are open, and only expected ports are accessible (see
  common/tasks/verify.yml).
- Each role now includes cleanup steps to remove old/conflicting packages and
  configurations before installing or configuring new ones. This ensures a clean,
  idempotent setup every time.



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



## Using SSH Keys with GitHub Actions (webfactory/ssh-agent)

To allow GitHub Actions to connect to your server via SSH, you need to generate an SSH key, add it to your server, and add the private key as a GitHub secret:

### 1. Generate an SSH key on your local machine or server

```bash
ssh-keygen -t ed25519 -C "github-actions-vps" -f ~/.ssh/github-actions-vps
```
Press Enter to skip the passphrase (recommended for automation).

### 2. Add the public key to your server's authorized_keys

```bash
cat ~/.ssh/github-actions-vps.pub | ssh youruser@yourserver 'cat >> ~/.ssh/authorized_keys'
```

### 3. Add the private key to your GitHub repository secrets

- Open the private key file:
  ```bash
  cat ~/.ssh/github-actions-vps
  ```
- Copy the entire contents.
- Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret.
- Name it `VPSZ_SSH_KEY` and paste the private key contents.

### 4. The workflow will use this secret automatically

Your workflow already uses:
```yaml
with:
  ssh-private-key: ${{ secrets.VPSZ_SSH_KEY }}
```


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