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
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

if [[ "${EUID}" -ne 0 ]]; then 
    log_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

log_info "=== Configuration de la Sécurité ==="

# Utiliser les variables d'environnement exportées par post_install.sh
ALLOWED_SSH_IP="${ALLOWED_SSH_IP:-}"
TARGET_USER="${TARGET_USER:-seb}"

# Vérifier que l'IP SSH est configurée
if [[ -z "${ALLOWED_SSH_IP}" ]]; then
    log_error "Aucune IP autorisée configurée pour SSH!"
    log_error "Veuillez définir ALLOWED_SSH_IP dans votre fichier .env"
    exit 1
fi

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

# Ports Steam pour les serveurs de jeu (ouverts à tous)
log_info "Autorisation des ports Steam/Gaming..."
ufw allow 27015/tcp comment 'Steam SRCDS'
ufw allow 27015/udp comment 'Steam SRCDS'
ufw allow 27005/udp comment 'Steam Client'
ufw allow 27020/udp comment 'Steam SourceTV'

# Ports services (monitoring, dev) UNIQUEMENT depuis votre IP
# Note: Pas de ports de bases de données car gérées via Docker
log_info "Autorisation des services depuis ${ALLOWED_SSH_IP}..."
ufw allow from "${ALLOWED_SSH_IP}" to any port 19999 proto tcp comment 'Netdata depuis IP autorisée'
ufw allow from "${ALLOWED_SSH_IP}" to any port 12345 proto tcp comment 'Grafana Alloy depuis IP autorisée'
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

# Note: Module 08 s'exécute AVANT module 10 (Let's Encrypt)
# La configuration HTTPS sera ajoutée par le module 10

# Netdata écoute sur toutes les interfaces (protégé par UFW)
# Accessible uniquement depuis ALLOWED_SSH_IP grâce aux règles UFW

SERVER_DOMAIN="${SERVER_DOMAIN:-localhost}"

cat > /etc/netdata/netdata.conf << EOF
[global]
    # Écouter sur toutes les interfaces (sécurisé par UFW)
    bind to = 0.0.0.0
    
[web]
    # Permettre les connexions depuis votre IP
    allow connections from = localhost 127.0.0.1 ${ALLOWED_SSH_IP}
    
    # Permettre les dashboards depuis votre IP
    allow dashboard from = localhost 127.0.0.1 ${ALLOWED_SSH_IP}
    
    # SSL sera activé via Nginx reverse proxy (module 10)
    # Le certificat Let's Encrypt sera utilisé
EOF

# Redémarrer Netdata
systemctl restart netdata

# 6. Créer une configuration Nginx pour Netdata avec HTTPS
log_info "Création d'une configuration Nginx pour Netdata..."

if [ -d /etc/nginx/sites-available ]; then
    cat > /etc/nginx/sites-available/netdata << 'EOFNETDATA'
# Configuration Netdata (Monitoring)
# Activé automatiquement par le module 10 (Let's Encrypt)

upstream netdata-backend {
    server 127.0.0.1:19999;
    keepalive 64;
}

# Redirection HTTP -> HTTPS
server {
    listen 80;
    listen [::]:80;
    
    server_name netdata.SERVERDOMAIN;
    
    # Redirection vers HTTPS
    return 301 https://$server_name$request_uri;
}

# Configuration HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    
    server_name netdata.SERVERDOMAIN;
    
    # Certificats Let's Encrypt (seront créés par le module 10)
    ssl_certificate /etc/letsencrypt/live/SERVERDOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/SERVERDOMAIN/privkey.pem;
    
    # Configuration SSL moderne
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Authentification basique (recommandé)
    # Créez le fichier: sudo htpasswd -c /etc/nginx/.htpasswd admin
    # auth_basic "Netdata Monitoring";
    # auth_basic_user_file /etc/nginx/.htpasswd;
    
    # Restriction d'accès par IP (déjà géré par UFW)
    # allow ALLOWEDIP;
    # deny all;
    
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
EOFNETDATA
    
    # Remplacer les variables dans le fichier
    sed -i "s/SERVERDOMAIN/${SERVER_DOMAIN}/g" /etc/nginx/sites-available/netdata
    sed -i "s/ALLOWEDIP/${ALLOWED_SSH_IP}/g" /etc/nginx/sites-available/netdata
    
    log_info "✓ Configuration Nginx pour Netdata créée"
    log_info "  Elle sera activée automatiquement par le module 10 (Let's Encrypt)"
fi

# 7. Installation de GeoIP2 pour géolocalisation des attaques
log_info "Installation de GeoIP2 (géolocalisation des attaques)..."

DEBIAN_FRONTEND=noninteractive apt install -y geoipupdate libmaxminddb0 libmaxminddb-dev mmdb-bin

# Créer le répertoire pour les bases de données
mkdir -p /usr/share/GeoIP

# Télécharger GeoLite2 (version gratuite)
log_info "Téléchargement des bases de données GeoLite2..."
wget -q -O /tmp/GeoLite2-City.tar.gz "https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-City.mmdb.tar.gz"
wget -q -O /tmp/GeoLite2-Country.tar.gz "https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb.tar.gz"

tar -xzf /tmp/GeoLite2-City.tar.gz -C /usr/share/GeoIP/ 2>/dev/null || log_warning "GeoLite2-City non extrait"
tar -xzf /tmp/GeoLite2-Country.tar.gz -C /usr/share/GeoIP/ 2>/dev/null || log_warning "GeoLite2-Country non extrait"

# Nettoyer
rm -f /tmp/GeoLite2-*.tar.gz

log_info "✓ GeoIP2 installé"

# Créer un script d'analyse des attaques avec géolocalisation
log_info "Création du script d'analyse géographique des attaques..."

cat > /usr/local/bin/geoip-attacks << 'EOFGEO'
#!/bin/bash

# Script d'analyse géographique des attaques
# Analyse les logs Fail2ban et auth.log avec géolocalisation

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

GEOIP_DB="/usr/share/GeoIP/GeoLite2-City.mmdb"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Analyse géographique des attaques${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Fonction pour obtenir la géolocalisation d'une IP
geolocate_ip() {
    local ip=$1
    if [[ -f "$GEOIP_DB" ]] && command -v mmdblookup &> /dev/null; then
        local country=$(mmdblookup --file "$GEOIP_DB" --ip "$ip" country names en 2>/dev/null | grep -o '"[^"]*"' | tr -d '"' | tail -1)
        local city=$(mmdblookup --file "$GEOIP_DB" --ip "$ip" city names en 2>/dev/null | grep -o '"[^"]*"' | tr -d '"' | tail -1)
        if [[ -n "$country" ]]; then
            echo "${city:-Unknown}, ${country}"
        else
            echo "Unknown"
        fi
    else
        echo "GeoIP unavailable"
    fi
}

# Extraire les IPs bannies de Fail2ban
echo -e "${YELLOW}Top 20 IPs bannies par Fail2ban (dernières 24h):${NC}"
if [[ -f /var/log/fail2ban.log ]]; then
    grep "Ban" /var/log/fail2ban.log | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | \
    sort | uniq -c | sort -rn | head -20 | while read -r count ip; do
        location=$(geolocate_ip "$ip")
        printf "  ${RED}%-4s${NC} ${CYAN}%-15s${NC} %s\n" "$count" "$ip" "$location"
    done
else
    echo "  Aucun log Fail2ban trouvé"
fi

echo ""
echo -e "${YELLOW}Top 20 pays d'origine des attaques:${NC}"
if [[ -f /var/log/fail2ban.log ]]; then
    grep "Ban" /var/log/fail2ban.log | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | \
    sort -u | while read -r ip; do
        geolocate_ip "$ip" | cut -d',' -f2 | xargs
    done | sort | uniq -c | sort -rn | head -20 | while read -r count country; do
        printf "  ${RED}%-4s${NC} %s\n" "$count" "$country"
    done
else
    echo "  Aucune donnée disponible"
fi

echo ""
echo -e "${YELLOW}Dernières tentatives d'intrusion (dernière heure):${NC}"
if [[ -f /var/log/auth.log ]]; then
    grep "Failed password" /var/log/auth.log | tail -10 | while read -r line; do
        ip=$(echo "$line" | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | head -1)
        if [[ -n "$ip" ]]; then
            location=$(geolocate_ip "$ip")
            echo "  ${RED}$ip${NC} - $location"
        fi
    done
else
    echo "  Aucun log auth.log trouvé"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
EOFGEO

chmod +x /usr/local/bin/geoip-attacks

log_info "✓ Script geoip-attacks créé"

# Créer des alias pour faciliter l'analyse de sécurité
log_info "Création des alias pour l'analyse de sécurité..."

ALIAS_FILE="/etc/profile.d/security-aliases.sh"
cat > "${ALIAS_FILE}" << 'EOFALIAS'
# Alias pour l'analyse de sécurité

alias geoip-attacks='/usr/local/bin/geoip-attacks'
alias security-map='geoip-attacks'
alias security-bans='sudo fail2ban-client status'
alias security-ufw='sudo ufw status verbose'
EOFALIAS

chmod +x "${ALIAS_FILE}"
log_info "✓ Alias de sécurité créés"

# 8. Installation d'outils de sécurité supplémentaires
log_info "Installation d'outils de sécurité supplémentaires..."

# Préconfigurer unattended-upgrades pour éviter les prompts interactifs
echo 'unattended-upgrades unattended-upgrades/enable_auto_updates boolean true' | debconf-set-selections

DEBIAN_FRONTEND=noninteractive apt install -y \
    fail2ban \
    unattended-upgrades \
    apt-listchanges

# Activer fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# Configurer les mises à jour automatiques (non-interactif)
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive unattended-upgrades

log_info "=== Module Sécurité Terminé ==="
echo ""
echo -e "${GREEN}UFW:${NC} Activé avec configuration stricte"
echo -e "${GREEN}Netdata:${NC} Installé et accessible sur port 19999"
echo -e "${GREEN}GeoIP2:${NC} Installé pour géolocalisation des attaques"
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
echo "  ✓ 27015 TCP/UDP : SRCDS (ouvert à tous)"
echo "  ✓ 27005 UDP : Steam Client (ouvert à tous)"
echo "  ✓ 27020 UDP : SourceTV (ouvert à tous)"
echo ""
echo -e "${YELLOW}Services (UNIQUEMENT depuis ${ALLOWED_SSH_IP}) :${NC}"
echo "  ✓ Port 19999 : Netdata"
echo "  ✓ Port 12345 : Grafana Alloy"
echo "  ✓ Ports 3000-9000 : Développement"
echo ""
echo -e "${CYAN}Bases de données (via Docker) :${NC}"
echo "  Les bases de données MySQL/PostgreSQL ne sont pas installées"
echo "  Utilisez Docker pour les lancer (voir module 04)"
echo "  Les ports 3306 et 5432 seront accessibles si vous lancez des conteneurs"
echo ""
echo -e "${YELLOW}Règles UFW détaillées:${NC}"
ufw status numbered
echo ""
echo -e "${YELLOW}Accéder aux services depuis ${ALLOWED_SSH_IP}:${NC}"
echo "  - Netdata: https://<server-domain>:19999 (avec certificat Let's Encrypt)"
echo "  - Grafana Alloy: http://<server-ip>:12345"
echo "  - Bases de données Docker: mysql -h <server-ip> -P 3306 ou psql -h <server-ip> -p 5432"
echo ""
echo -e "${YELLOW}Commandes UFW utiles:${NC}"
echo "  - Voir le statut: ufw status verbose"
echo "  - Voir numérotées: ufw status numbered"
echo "  - Autoriser une IP pour SSH: ufw allow from <IP> to any port 22"
echo "  - Supprimer une règle: ufw delete <numéro>"
echo "  - Désactiver UFW: ufw disable (⚠️ déconseillé)"
echo ""
echo -e "${YELLOW}Analyse de sécurité:${NC}"
echo "  - geoip-attacks    # Analyser géographiquement les attaques"
echo "  - security-map     # Alias pour geoip-attacks"
echo ""
echo -e "${RED}⚠️  IMPORTANT :${NC}"
echo "  Si vous changez d'IP et perdez l'accès SSH, vous devrez:"
echo "  1. Accéder à la console de votre hébergeur"
echo "  2. Exécuter: ufw allow from <NOUVELLE_IP> to any port 22"
echo "  3. Ou désactiver temporairement UFW: ufw disable"
echo ""

exit 0
