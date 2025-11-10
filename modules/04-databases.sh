#!/bin/bash

################################################################################
# Module 04 - Bases de Données
# Description: MySQL/MariaDB + PostgreSQL
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

log_info "=== Installation des Bases de Données ==="

# 1. MySQL/MariaDB
log_info "Installation de MariaDB..."
apt update
DEBIAN_FRONTEND=noninteractive apt install -y mariadb-server mariadb-client

# Démarrer et activer MariaDB
systemctl start mariadb
systemctl enable mariadb

log_info "✓ MariaDB installé"
mysql --version

# Configuration sécurisée de base
log_warning "Configuration de MariaDB..."
log_warning "Pour sécuriser MariaDB, exécutez manuellement: sudo mysql_secure_installation"

# 2. PostgreSQL
log_info "Installation de PostgreSQL..."
DEBIAN_FRONTEND=noninteractive apt install -y postgresql postgresql-contrib

# Démarrer et activer PostgreSQL
systemctl start postgresql
systemctl enable postgresql

log_info "✓ PostgreSQL installé"
sudo -u postgres psql --version

# 3. Outils client
log_info "Installation des outils clients..."
DEBIAN_FRONTEND=noninteractive apt install -y \
    mycli \
    pgcli

log_info "=== Module Bases de Données Terminé ==="
echo ""
echo -e "${GREEN}MariaDB:${NC} $(mysql --version)"
echo -e "${GREEN}PostgreSQL:${NC} $(sudo -u postgres psql --version | head -n1)"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  - MariaDB: exécutez 'sudo mysql_secure_installation' pour sécuriser"
echo "  - PostgreSQL: utilisateur par défaut 'postgres'"
echo ""
echo -e "${YELLOW}Connexion:${NC}"
echo "  - MariaDB: sudo mysql"
echo "  - PostgreSQL: sudo -u postgres psql"
echo ""

exit 0
