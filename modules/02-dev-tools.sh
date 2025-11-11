#!/bin/bash

################################################################################
# Module 02 - Outils de Développement
# Description: Python 3.13, GitHub CLI, Node.js (bun), Go, Terraform
################################################################################

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

if [[ "${EUID}" -ne 0 ]]; then 
    log_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

log_info "=== Installation des Outils de Développement ==="

# 1. Python 3.13
log_info "Installation de Python 3.13..."
add-apt-repository -y ppa:deadsnakes/ppa
apt update
DEBIAN_FRONTEND=noninteractive apt install -y python3.13 python3.13-venv python3.13-dev python3-pip

# Créer un alias pour python3.13
update-alternatives --install /usr/bin/python3.13 python3.13 /usr/bin/python3.13 1

log_info "✓ Python 3.13 installé"
python3.13 --version

# 2. GitHub CLI
log_info "Installation de GitHub CLI..."
# Supprimer l'ancienne clé si elle existe
rm -f /usr/share/keyrings/githubcli-archive-keyring.gpg
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
apt update
DEBIAN_FRONTEND=noninteractive apt install -y gh

log_info "✓ GitHub CLI installé"
gh --version

# 3. Bun (pour Node.js)
log_info "Installation de Bun..."
curl -fsSL https://bun.sh/install | bash

# Ajouter bun au PATH global
if [ ! -f /usr/local/bin/bun ]; then
    ln -s /root/.bun/bin/bun /usr/local/bin/bun 2>/dev/null || true
fi

log_info "✓ Bun installé"
/root/.bun/bin/bun --version || bun --version

# 4. Node.js (via bun)
log_info "Installation de Node.js (dernière version)..."

# Installation de Node.js via NodeSource pour avoir la dernière version
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
DEBIAN_FRONTEND=noninteractive apt install -y nodejs

log_info "✓ Node.js installé"
node --version
npm --version

# 5. Golang
log_info "Installation de Go (dernière version)..."

# Récupérer la dernière version de Go
GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n1)
GO_TAR="${GO_VERSION}.linux-amd64.tar.gz"

# Télécharger et installer
cd /tmp
wget -q "https://go.dev/dl/${GO_TAR}"
rm -rf /usr/local/go
tar -C /usr/local -xzf "$GO_TAR"
rm "$GO_TAR"

# Ajouter Go au PATH
if ! grep -q '/usr/local/go/bin' /etc/profile; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
fi

# Configurer GOPATH pour les utilisateurs
if ! grep -q 'GOPATH' /etc/profile; then
    echo 'export GOPATH=$HOME/go' >> /etc/profile
    echo 'export PATH=$PATH:$GOPATH/bin' >> /etc/profile
fi

log_info "✓ Go ${GO_VERSION} installé"
/usr/local/go/bin/go version

# 6. Terraform
log_info "Installation de Terraform..."

# Ajouter le repository HashiCorp
rm -f /usr/share/keyrings/hashicorp-archive-keyring.gpg
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update
DEBIAN_FRONTEND=noninteractive apt install -y terraform

log_info "✓ Terraform installé"
terraform --version

# 7. Outils système et monitoring
log_info "Installation d'outils système avancés..."
DEBIAN_FRONTEND=noninteractive apt install -y \
    htop \
    btop \
    ncdu \
    iotop \
    nmon \
    glances \
    duf \
    tree \
    vim \
    nano \
    tmux \
    unzip \
    zip \
    silversearcher-ag \
    ripgrep \
    fd-find \
    bat \
    jq \
    httpie \
    net-tools \
    tldr \
    neofetch

log_info "✓ Outils système installés"

# 8. Outils de qualité de code
log_info "Installation des outils de linting et formatage..."

# ShellCheck pour Bash
DEBIAN_FRONTEND=noninteractive apt install -y shellcheck

# Python linting
DEBIAN_FRONTEND=noninteractive apt install -y \
    python3-pip \
    pylint \
    python3-autopep8 \
    python3-flake8

# Black (formatage Python) via pip
pip3 install --break-system-packages black 2>/dev/null || pip3 install black

# yamllint pour YAML
DEBIAN_FRONTEND=noninteractive apt install -y yamllint

# hadolint pour Dockerfiles
wget -q -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64
chmod +x /usr/local/bin/hadolint

# markdownlint-cli pour Markdown (via npm)
if command -v npm &> /dev/null; then
    npm install -g markdownlint-cli 2>/dev/null || log_warning "markdownlint non installé"
fi

log_info "✓ Outils de qualité de code installés"

# 9. Créer des alias utiles
log_info "Création des alias pour les outils..."

ALIAS_FILE="/etc/profile.d/dev-tools-aliases.sh"
cat > "${ALIAS_FILE}" << 'EOFALIAS'
# Alias pour outils de développement

# Outils de qualité de code
alias check-shell='shellcheck'
alias check-python='pylint'
alias format-python='black'
alias check-yaml='yamllint'
alias check-docker='hadolint'
alias check-markdown='markdownlint'

# Outils système
alias disk-usage='ncdu'
alias sys-monitor='btop'
alias network='glances'
EOFALIAS

chmod +x "${ALIAS_FILE}"
log_info "✓ Alias créés"

log_info "=== Module Outils de Développement Terminé ==="
echo ""
echo -e "${GREEN}Python:${NC} $(python3.13 --version)"
echo -e "${GREEN}GitHub CLI:${NC} $(gh --version | head -n1)"
echo -e "${GREEN}Node.js:${NC} $(node --version)"
echo -e "${GREEN}npm:${NC} $(npm --version)"
echo -e "${GREEN}Bun:${NC} Installé"
echo -e "${GREEN}Go:${NC} $(/usr/local/go/bin/go version)"
echo -e "${GREEN}Terraform:${NC} $(terraform version | head -n1)"
echo ""
echo -e "${YELLOW}Outils système:${NC}"
echo "  - htop, btop, ncdu, glances, duf"
echo "  - ripgrep (rg), fd-find, bat, httpie"
echo "  - neofetch, tldr"
echo ""
echo -e "${YELLOW}Outils qualité de code:${NC}"
echo "  - ShellCheck, Black, Pylint, Flake8"
echo "  - yamllint, hadolint, markdownlint"
echo ""

exit 0
