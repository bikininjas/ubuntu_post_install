#!/bin/bash

################################################################################
# Module 03 - Docker
# Description: Docker CE (dernière version gratuite) + Docker Compose
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

TARGET_USER="seb"

if [ "$EUID" -ne 0 ]; then 
    log_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

log_info "=== Installation de Docker ==="

# 1. Désinstaller les anciennes versions
log_info "Nettoyage des anciennes versions de Docker..."
apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# 2. Installer les prérequis
log_info "Installation des prérequis..."
apt update
DEBIAN_FRONTEND=noninteractive apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 3. Ajouter la clé GPG officielle de Docker
log_info "Ajout de la clé GPG Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# 4. Ajouter le repository Docker
log_info "Ajout du repository Docker..."
# shellcheck disable=SC1091
. /etc/os-release
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  ${VERSION_CODENAME} stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. Installer Docker Engine
log_info "Installation de Docker Engine..."
apt update
DEBIAN_FRONTEND=noninteractive apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 6. Démarrer et activer Docker
log_info "Démarrage de Docker..."
systemctl start docker
systemctl enable docker

# 7. Ajouter l'utilisateur au groupe docker
if id "$TARGET_USER" &>/dev/null; then
    log_info "Ajout de l'utilisateur $TARGET_USER au groupe docker..."
    usermod -aG docker "$TARGET_USER"
    log_info "✓ Utilisateur ajouté au groupe docker (reconnexion nécessaire)"
else
    log_warning "L'utilisateur $TARGET_USER n'existe pas encore"
fi

# 8. Tester Docker
log_info "Test de Docker..."
docker --version
docker compose version

# Exécuter un conteneur de test
log_info "Exécution d'un conteneur de test..."
docker run --rm hello-world

log_info "✓ Docker fonctionne correctement"

# 9. Configuration supplémentaire (logging, etc.)
log_info "Configuration de Docker..."

# Créer le fichier de configuration daemon.json
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# Redémarrer Docker pour appliquer la configuration
systemctl restart docker

log_info "=== Module Docker Terminé ==="
echo ""
echo -e "${GREEN}Docker:${NC} $(docker --version)"
echo -e "${GREEN}Docker Compose:${NC} $(docker compose version)"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC} L'utilisateur $TARGET_USER doit se déconnecter et se reconnecter"
echo "           pour utiliser Docker sans sudo, ou redémarrer le système."
echo ""

exit 0
