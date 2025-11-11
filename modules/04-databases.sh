#!/bin/bash

################################################################################
# Module 04 - Bases de Données (Docker)
# Description: Instructions pour utiliser MySQL/MariaDB + PostgreSQL via Docker
################################################################################

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

if [[ "${EUID}" -ne 0 ]]; then 
    log_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

log_info "=== Configuration Bases de Données (Docker) ==="

# Récupérer l'IP autorisée depuis les variables d'environnement
ALLOWED_SSH_IP="${ALLOWED_SSH_IP:-}"

log_info "Ce module ne configure pas de bases de données directement"
log_info "Les bases de données seront gérées via Docker pour plus de flexibilité"

# Créer un répertoire pour les données Docker
log_info "Création des répertoires pour les données..."
mkdir -p /opt/docker/data/{mysql,postgres}
chown -R 1000:1000 /opt/docker/data

log_info "=== Module Bases de Données Terminé ==="
echo ""
echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║         Bases de Données - Configuration Docker              ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Les bases de données ne sont PAS installées directement.${NC}"
echo -e "${CYAN}Utilisez Docker pour lancer vos bases de données.${NC}"
echo ""
echo -e "${GREEN}Répertoires créés:${NC}"
echo "  - /opt/docker/data/mysql  (pour MySQL/MariaDB)"
echo "  - /opt/docker/data/postgres  (pour PostgreSQL)"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  Exemples de commandes Docker:${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}1. MySQL/MariaDB:${NC}"
echo ""
cat << 'EOFMYSQL'
docker run -d \
  --name mysql \
  --restart unless-stopped \
  -e MYSQL_ROOT_PASSWORD=your_secure_password \
  -e MYSQL_DATABASE=myapp \
  -e MYSQL_USER=myuser \
  -e MYSQL_PASSWORD=myuser_password \
  -v /opt/docker/data/mysql:/var/lib/mysql \
  -p 3306:3306 \
  mysql:8.0

# Connexion au conteneur:
docker exec -it mysql mysql -u root -p

# Logs:
docker logs mysql -f
EOFMYSQL
echo ""
echo -e "${CYAN}2. PostgreSQL:${NC}"
echo ""
cat << 'EOFPG'
docker run -d \
  --name postgres \
  --restart unless-stopped \
  -e POSTGRES_PASSWORD=your_secure_password \
  -e POSTGRES_DB=myapp \
  -e POSTGRES_USER=myuser \
  -v /opt/docker/data/postgres:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:16

# Connexion au conteneur:
docker exec -it postgres psql -U myuser -d myapp

# Logs:
docker logs postgres -f
EOFPG
echo ""
echo -e "${CYAN}3. Docker Compose (recommandé):${NC}"
echo ""
echo "Créez un fichier ${GREEN}docker-compose.yml${NC} :"
echo ""
cat << 'EOFCOMPOSE'
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: your_secure_password
      MYSQL_DATABASE: myapp
      MYSQL_USER: myuser
      MYSQL_PASSWORD: myuser_password
    volumes:
      - /opt/docker/data/mysql:/var/lib/mysql
    ports:
      - "3306:3306"
    networks:
      - db-network

  postgres:
    image: postgres:16
    container_name: postgres
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: your_secure_password
      POSTGRES_DB: myapp
      POSTGRES_USER: myuser
    volumes:
      - /opt/docker/data/postgres:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    networks:
      - db-network

networks:
  db-network:
    driver: bridge
EOFCOMPOSE
echo ""
echo "Puis lancez avec : ${GREEN}docker-compose up -d${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${RED}⚠️  SÉCURITÉ :${NC}"
echo "  - Changez tous les mots de passe par défaut"
echo "  - Les bases de données sont accessibles depuis ${ALLOWED_SSH_IP} (ports 3306, 5432)"
echo "  - UFW protège ces ports depuis les autres IP"
echo ""
echo -e "${CYAN}Commandes Docker utiles:${NC}"
echo "  docker ps                    # Liste des conteneurs actifs"
echo "  docker logs <container>      # Voir les logs"
echo "  docker exec -it <container> bash  # Accéder au shell"
echo "  docker stop <container>      # Arrêter un conteneur"
echo "  docker start <container>     # Démarrer un conteneur"
echo "  docker restart <container>   # Redémarrer un conteneur"
echo ""

exit 0
