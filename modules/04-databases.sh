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

# Récupérer l'IP autorisée depuis les variables d'environnement
ALLOWED_SSH_IP="${ALLOWED_SSH_IP:-}"

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

# Configurer MariaDB pour écouter sur toutes les interfaces (protégé par UFW)
if [ -f /etc/mysql/mariadb.conf.d/50-server.cnf ]; then
    log_info "Configuration de MariaDB pour écouter sur toutes les interfaces..."
    sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
    systemctl restart mariadb
    log_info "✓ MariaDB configuré pour écouter sur 0.0.0.0 (protégé par UFW)"
fi

log_warning "Pour sécuriser MariaDB, exécutez manuellement: sudo mysql_secure_installation"

# 2. PostgreSQL
log_info "Installation de PostgreSQL..."
DEBIAN_FRONTEND=noninteractive apt install -y postgresql postgresql-contrib

# Démarrer et activer PostgreSQL
systemctl start postgresql
systemctl enable postgresql

log_info "✓ PostgreSQL installé"
sudo -u postgres psql --version

# Configurer PostgreSQL pour accepter les connexions depuis votre IP
log_info "Configuration de PostgreSQL pour écouter sur toutes les interfaces..."
PG_VERSION=$(sudo -u postgres psql -V | grep -oP '\d+' | head -1)
PG_CONF="/etc/postgresql/${PG_VERSION}/main/postgresql.conf"
PG_HBA="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"

if [ -f "$PG_CONF" ]; then
    # Écouter sur toutes les interfaces
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"
    
    # Ajouter la règle pour votre IP dans pg_hba.conf (si ALLOWED_SSH_IP est défini)
    if [ -n "$ALLOWED_SSH_IP" ]; then
        log_info "Autorisation de la connexion PostgreSQL depuis ${ALLOWED_SSH_IP}..."
        echo "# Connexion depuis IP autorisée" >> "$PG_HBA"
        echo "host    all             all             ${ALLOWED_SSH_IP}/32         md5" >> "$PG_HBA"
    fi
    
    systemctl restart postgresql
    log_info "✓ PostgreSQL configuré pour écouter sur * (protégé par UFW)"
fi

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
echo "  - MariaDB: écoute sur 0.0.0.0:3306 (accessible depuis ${ALLOWED_SSH_IP})"
echo "  - PostgreSQL: écoute sur *:5432 (accessible depuis ${ALLOWED_SSH_IP})"
echo "  - MariaDB: exécutez 'sudo mysql_secure_installation' pour sécuriser"
echo "  - PostgreSQL: utilisateur par défaut 'postgres'"
echo ""
echo -e "${YELLOW}Connexion locale:${NC}"
echo "  - MariaDB: sudo mysql"
echo "  - PostgreSQL: sudo -u postgres psql"
echo ""
echo -e "${YELLOW}Connexion depuis ${ALLOWED_SSH_IP}:${NC}"
echo "  - MariaDB: mysql -h <server-ip> -u root -p"
echo "  - PostgreSQL: psql -h <server-ip> -U postgres"
echo ""
echo -e "${RED}⚠️  IMPORTANT :${NC}"
echo "  Créez des utilisateurs avec mots de passe pour les connexions distantes"
echo "  MariaDB: CREATE USER 'user'@'${ALLOWED_SSH_IP}' IDENTIFIED BY 'password';"
echo "  PostgreSQL: CREATE USER user WITH PASSWORD 'password';"
echo ""

exit 0
