# Common Role


**Purpose:**

- System update and cleanup
- Set timezone and locale
- Create user (optional)


**Main Tasks:**

- Update/upgrade apt packages
- Set timezone to Europe/Paris
- Set system language to en_US.UTF-8
- Optionally create a sudo user


**Tags:**

- `common`


**Usage Example:**

```bash
ansible-playbook -i inventory playbook.yml --tags "common"
```
