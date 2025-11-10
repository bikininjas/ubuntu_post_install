#!/bin/bash

################################################################################
# Module 08 - Sécurité
# Description: UFW Firewall + Netdata
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

if [ "$EUID" -ne 0 ]; then 
    log_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

log_info "=== Configuration de la Sécurité ==="

# 1. Installation de UFW
log_info "Installation de UFW (Uncomplicated Firewall)..."
apt update
DEBIAN_FRONTEND=noninteractive apt install -y ufw

# 2. Configuration de base UFW
log_info "Configuration des règles de base..."

# Politique par défaut
ufw default deny incoming
ufw default allow outgoing

# Autoriser SSH (important de le faire AVANT d'activer UFW)
log_warning "Autorisation SSH sur le port 22..."
ufw allow 22/tcp comment 'SSH'

# Autoriser HTTP et HTTPS
log_info "Autorisation HTTP et HTTPS..."
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Autoriser des ports pour le développement
log_info "Autorisation des ports de développement..."
ufw allow 3000/tcp comment 'Node.js dev'
ufw allow 8080/tcp comment 'Alternative web'

# Ports pour Netdata (si nécessaire depuis l'extérieur)
# Par défaut, on ne l'ouvre pas pour la sécurité
# ufw allow 19999/tcp comment 'Netdata'

# 3. Activer UFW
log_info "Activation de UFW..."
# Utiliser 'yes' pour confirmer automatiquement
echo "y" | ufw enable

ufw status verbose

log_info "✓ UFW activé et configuré"

# 4. Installation de Netdata
log_info "Installation de Netdata (monitoring)..."

# Méthode d'installation recommandée
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --non-interactive --stable-channel

# Vérifier si l'installation a réussi
if systemctl is-active --quiet netdata; then
    log_info "✓ Netdata installé et démarré"
else
    log_warning "Netdata pourrait ne pas être démarré"
fi

# 5. Configuration de Netdata
log_info "Configuration de Netdata..."

# Netdata écoute sur localhost:19999 par défaut (sécurisé)
# Pour y accéder depuis l'extérieur, configurer un reverse proxy Nginx ou ouvrir le port

cat > /etc/netdata/netdata.conf << 'EOF'
[global]
    # Écouter uniquement sur localhost (sécurité)
    bind to = 127.0.0.1
    
[web]
    # Permettre les connexions depuis le reverse proxy
    allow connections from = localhost 127.0.0.1
EOF

# Redémarrer Netdata
systemctl restart netdata

# 6. Créer une configuration Nginx pour Netdata (optionnel)
log_info "Création d'une configuration Nginx pour Netdata..."

if [ -d /etc/nginx/sites-available ]; then
    cat > /etc/nginx/sites-available/netdata << 'EOF'
# Configuration Netdata (Monitoring)
# Pour activer: ln -s /etc/nginx/sites-available/netdata /etc/nginx/sites-enabled/

upstream netdata-backend {
    server 127.0.0.1:19999;
    keepalive 64;
}

server {
    listen 80;
    listen [::]:80;
    
    # Changez ce nom de domaine
    server_name netdata.example.com;
    
    # Authentification basique (recommandé)
    # auth_basic "Netdata Monitoring";
    # auth_basic_user_file /etc/nginx/.htpasswd;
    
    location / {
        proxy_pass http://netdata-backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
    log_info "✓ Configuration Nginx pour Netdata créée"
    log_info "  Pour activer: ln -s /etc/nginx/sites-available/netdata /etc/nginx/sites-enabled/"
fi

# 7. Installation d'outils de sécurité supplémentaires
log_info "Installation d'outils de sécurité supplémentaires..."
DEBIAN_FRONTEND=noninteractive apt install -y \
    fail2ban \
    unattended-upgrades \
    apt-listchanges

# Activer fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# Configurer les mises à jour automatiques
dpkg-reconfigure -plow unattended-upgrades

log_info "=== Module Sécurité Terminé ==="
echo ""
echo -e "${GREEN}UFW:${NC} Activé et configuré"
echo -e "${GREEN}Netdata:${NC} Installé (http://localhost:19999)"
echo -e "${GREEN}Fail2ban:${NC} Activé"
echo -e "${GREEN}Unattended-upgrades:${NC} Configuré"
echo ""
echo -e "${YELLOW}Règles UFW actives:${NC}"
ufw status numbered
echo ""
echo -e "${YELLOW}Accéder à Netdata:${NC}"
echo "  - Localement: http://localhost:19999"
echo "  - Via tunnel SSH: ssh -L 19999:localhost:19999 user@server"
echo "  - Via Nginx: activez /etc/nginx/sites-available/netdata"
echo ""
echo -e "${YELLOW}Commandes UFW utiles:${NC}"
echo "  - Voir le statut: ufw status verbose"
echo "  - Autoriser un port: ufw allow 8000/tcp"
echo "  - Supprimer une règle: ufw delete <numéro>"
echo "  - Désactiver UFW: ufw disable"
echo ""

exit 0
