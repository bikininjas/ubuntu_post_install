# Security Role


**Purpose:**

- SSH hardening
- UFW firewall configuration


**Main Tasks:**

- Change SSH port
- Install and configure UFW
- Allow only required ports (SSH, HTTP, HTTPS)


**Tags:**

- `security`


**Usage Example:**

```bash
ansible-playbook -i inventory playbook.yml --tags "security"
```
