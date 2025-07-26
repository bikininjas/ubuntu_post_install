#!/bin/bash
set +e

# Robust color handling
if [ -t 1 ] && command -v tput &> /dev/null; then
  RED="$(tput setaf 1)"
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  NC="$(tput sgr0)"
else
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  NC='\033[0m'
fi

# Temp files for outputs
SYNTAX_OUT=$(mktemp)
LINT_OUT=$(mktemp)
YAML_OUT=$(mktemp)
SHELL_OUT=$(mktemp)
MD_OUT=$(mktemp)

# Run checks and capture output
printf "\n%s==> Running Ansible syntax check...%s\n" "$GREEN" "$NC"
ansible-playbook --syntax-check -i inventory playbook.yml 2>&1 | tee "$SYNTAX_OUT"

if command -v ansible-lint &> /dev/null; then
  printf "\n%s==> Running ansible-lint...%s\n" "$GREEN" "$NC"
  ansible-lint playbook.yml 2>&1 | tee "$LINT_OUT"
else
  printf "\n%sansible-lint not found, skipping ansible lint step.%s\n" "$RED" "$NC"
fi

if command -v yamllint &> /dev/null; then
  printf "\n%s==> Running yamllint on all YAML files...%s\n" "$GREEN" "$NC"
  yamllint . 2>&1 | tee "$YAML_OUT"
else
  printf "\n%syamllint not found, skipping YAML lint step.%s\n" "$RED" "$NC"
fi

if command -v shellcheck &> /dev/null; then
  printf "\n%s==> Running shellcheck on all shell scripts...%s\n" "$GREEN" "$NC"
  find . -type f -name '*.sh' -exec shellcheck {} + 2>&1 | tee "$SHELL_OUT"
else
  printf "\n%sshellcheck not found, skipping shell lint step.%s\n" "$RED" "$NC"
fi

if command -v markdownlint &> /dev/null; then
  printf "\n%s==> Running markdownlint on all Markdown files...%s\n" "$GREEN" "$NC"
  find . -type f -name '*.md' -exec markdownlint {} + 2>&1 | tee "$MD_OUT"
else
  printf "\n%smarkdownlint not found, skipping markdown lint step.%s\n" "$RED" "$NC"
fi

# Summarize issues and errors
printf "\n%s==> Summarizing issues and errors...%s\n" "$YELLOW" "$NC"

ALL_ISSUES=$(mktemp)
ALL_ERRORS=$(mktemp)

summarize() {
  local file="$1"
  local label="$2"
  if [ -s "$file" ]; then
    printf "\n--- %s ---\n" "$label" >> "$ALL_ISSUES"
    cat "$file" >> "$ALL_ISSUES"
    grep -iE 'error|failed|fatal' "$file" >> "$ALL_ERRORS"
  fi
}

summarize "$SYNTAX_OUT" "Ansible Syntax Check"
summarize "$LINT_OUT" "Ansible Lint"
summarize "$YAML_OUT" "YAML Lint"
summarize "$SHELL_OUT" "ShellCheck"
summarize "$MD_OUT" "MarkdownLint"

# Always print issues summary if any output
if [ -s "$ALL_ISSUES" ]; then
  printf "\n%s==> Issues found during validation:%s\n" "$YELLOW" "$NC"
  cat "$ALL_ISSUES"
else
  printf "\n%sNo issues found during validation.%s\n" "$GREEN" "$NC"
fi

if [ -s "$ALL_ERRORS" ]; then
  printf "\n%s==> Errors found during validation:%s\n" "$RED" "$NC"
  cat "$ALL_ERRORS"
else
  printf "\n%sNo errors found during validation.%s\n" "$GREEN" "$NC"
fi

# Clean up
rm -f "$SYNTAX_OUT" "$LINT_OUT" "$YAML_OUT" "$SHELL_OUT" "$MD_OUT" "$ALL_ISSUES" "$ALL_ERRORS"

printf "\n%sValidation complete.\nIf you see no errors above, your playbook is ready!%s\n" "$GREEN" "$NC"
