set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Syntax check
printf "\n${GREEN}==> Running Ansible syntax check...${NC}\n"
ansible-playbook --syntax-check -i inventory playbook.yml

# Lint (if available)
if command -v ansible-lint &> /dev/null; then
  printf "\n${GREEN}==> Running ansible-lint...${NC}\n"
  ansible-lint playbook.yml || true
else
  printf "\n${RED}ansible-lint not found, skipping lint step.${NC}\n"
fi

# Dry-run (check mode)
printf "\n${GREEN}==> Running Ansible dry-run (check mode)...${NC}\n"
ansible-playbook --check -i inventory playbook.yml || true

printf "\n${GREEN}Validation complete.\nIf you see no errors above, your playbook is ready!${NC}\n"
