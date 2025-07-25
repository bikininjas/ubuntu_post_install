
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

---

Maintained by bikininjas