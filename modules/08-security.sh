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

if [[ "${EUID}" -ne 0 ]]; then 
    log_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

log_info "=== Configuration de la Sécurité ==="

# Configuration stricte
ALLOWED_SSH_IP="82.65.136.32"  # IP autorisée pour SSH
TARGET_USER="seb"

log_info "Configuration de sécurité stricte activée"
log_info "SSH sera limité à l'IP : ${ALLOWED_SSH_IP}"

# 1. Installation de UFW
log_info "Installation de UFW (Uncomplicated Firewall)..."
apt update
DEBIAN_FRONTEND=noninteractive apt install -y ufw

# 2. Configuration de base UFW
log_info "Configuration des règles de base..."

# Réinitialiser UFW pour partir d'une base propre
ufw --force reset

# Politique par défaut : TOUT BLOQUER
ufw default deny incoming
ufw default deny outgoing
ufw default allow routed

# Autoriser les connexions sortantes essentielles
log_info "Autorisation des connexions sortantes essentielles..."
ufw allow out 53/udp comment 'DNS'
ufw allow out 53/tcp comment 'DNS'
ufw allow out 80/tcp comment 'HTTP sortant'
ufw allow out 443/tcp comment 'HTTPS sortant'
ufw allow out 123/udp comment 'NTP'

# Autoriser SSH UNIQUEMENT depuis votre IP
log_warning "Limitation SSH au port 22 depuis ${ALLOWED_SSH_IP}..."
ufw allow from "${ALLOWED_SSH_IP}" to any port 22 proto tcp comment "SSH depuis IP autorisée"

# Autoriser HTTP et HTTPS depuis n'importe où (pour le serveur web)
log_info "Autorisation HTTP et HTTPS pour le serveur web..."
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Ports Steam pour les serveurs de jeu
log_info "Autorisation des ports Steam/Gaming..."
ufw allow 27015/tcp comment 'Steam SRCDS'
ufw allow 27015/udp comment 'Steam SRCDS'
ufw allow 27005/udp comment 'Steam Client'
ufw allow 27020/udp comment 'Steam SourceTV'
ufw allow from "${ALLOWED_SSH_IP}" to any port 3000:9000 proto tcp comment 'Ports dev depuis IP autorisée'

# Bloquer explicitement les ports de développement depuis l'extérieur (sauf IP autorisée)
log_info "Blocage des ports de développement depuis l'extérieur..."
# Ces règles sont redondantes avec default deny, mais explicites pour la clarté

# 3. Activer UFW
log_info "Activation de UFW..."
# Utiliser 'yes' pour confirmer automatiquement
echo "y" | ufw enable

log_info "✓ UFW activé avec configuration stricte"
echo ""
log_warning "=========================================="
log_warning "  IMPORTANT - RÈGLES DE SÉCURITÉ"
log_warning "=========================================="
echo ""
echo -e "${RED}SSH (port 22) :${NC} LIMITÉ à l'IP ${ALLOWED_SSH_IP}"
echo -e "${GREEN}HTTP (port 80) :${NC} Ouvert à tous"
echo -e "${GREEN}HTTPS (port 443) :${NC} Ouvert à tous"
echo -e "${GREEN}Ports Steam (27015, 27005, 27020) :${NC} Ouverts"
echo -e "${YELLOW}Ports dev (3000-9000) :${NC} Accessibles UNIQUEMENT depuis ${ALLOWED_SSH_IP}"
echo ""
log_warning "Si vous perdez l'accès SSH, vous devrez accéder physiquement au serveur"
log_warning "ou via la console de votre hébergeur pour modifier les règles UFW"
echo ""

ufw status verbose

# 4. Installation de Netdata
log_info "Installation de Netdata (monitoring)..."

# Méthode d'installation recommandée (URL mise à jour)
if curl -fsSL https://get.netdata.cloud/kickstart.sh -o /tmp/netdata-kickstart.sh; then
    bash /tmp/netdata-kickstart.sh --non-interactive --stable-channel --dont-wait
    rm -f /tmp/netdata-kickstart.sh
else
    log_error "Échec du téléchargement du script Netdata"
    # Installer depuis les dépôts Ubuntu en fallback
    log_info "Installation de Netdata depuis les dépôts Ubuntu..."
    DEBIAN_FRONTEND=noninteractive apt install -y netdata
fi

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
echo -e "${GREEN}UFW:${NC} Activé avec configuration stricte"
echo -e "${GREEN}Netdata:${NC} Installé (http://localhost:19999)"
echo -e "${GREEN}Fail2ban:${NC} Activé"
echo -e "${GREEN}Unattended-upgrades:${NC} Configuré"
echo ""
echo -e "${YELLOW}=========================================="
echo -e "  RÈGLES DE SÉCURITÉ ACTIVES"
echo -e "==========================================${NC}"
echo ""
echo -e "${RED}SSH (port 22) :${NC}"
echo "  ✓ Autorisé UNIQUEMENT depuis : ${ALLOWED_SSH_IP}"
echo "  ✗ Bloqué depuis toutes les autres IP"
echo ""
echo -e "${GREEN}Web (ports 80, 443) :${NC}"
echo "  ✓ HTTP : Ouvert à tous"
echo "  ✓ HTTPS : Ouvert à tous"
echo ""
echo -e "${GREEN}Gaming (ports Steam) :${NC}"
echo "  ✓ 27015 TCP/UDP : SRCDS"
echo "  ✓ 27005 UDP : Steam Client"
echo "  ✓ 27020 UDP : SourceTV"
echo ""
echo -e "${YELLOW}Développement (ports 3000-9000) :${NC}"
echo "  ✓ Accessible UNIQUEMENT depuis : ${ALLOWED_SSH_IP}"
echo ""
echo -e "${YELLOW}Règles UFW détaillées:${NC}"
ufw status numbered
echo ""
echo -e "${YELLOW}Accéder à Netdata:${NC}"
echo "  - Localement: http://localhost:19999"
echo "  - Via tunnel SSH: ssh -L 19999:localhost:19999 ${TARGET_USER}@server"
echo "  - Via Nginx: activez /etc/nginx/sites-available/netdata"
echo ""
echo -e "${YELLOW}Commandes UFW utiles:${NC}"
echo "  - Voir le statut: ufw status verbose"
echo "  - Voir numérotées: ufw status numbered"
echo "  - Autoriser une IP pour SSH: ufw allow from <IP> to any port 22"
echo "  - Supprimer une règle: ufw delete <numéro>"
echo "  - Désactiver UFW: ufw disable (⚠️ déconseillé)"
echo ""
echo -e "${RED}⚠️  IMPORTANT :${NC}"
echo "  Si vous changez d'IP et perdez l'accès SSH, vous devrez:"
echo "  1. Accéder à la console de votre hébergeur"
echo "  2. Exécuter: ufw allow from <NOUVELLE_IP> to any port 22"
echo "  3. Ou désactiver temporairement UFW: ufw disable"
echo ""

exit 0
