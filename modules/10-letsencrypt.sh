#!/bin/bash

###############################################################################
# Module 10 : Installation et configuration de Let's Encrypt (Certbot)
# Description : Installe Certbot et génère les certificats SSL
# Auteur : Seb
# Dépendances : 00-domain-config.sh, 05-web-server.sh (Nginx)
###############################################################################

set -e

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonctions de logging
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_section() { echo -e "\n${YELLOW}=== $1 ===${NC}\n"; }

# Vérification des privilèges root
if [[ "${EUID}" -ne 0 ]]; then 
   log_error "Ce script doit être exécuté en tant que root"
   exit 1
fi

log_section "Installation de Let's Encrypt (Certbot)"

# Charger la configuration du domaine
DOMAIN_CONFIG_FILE="/etc/server-domain.conf"

if [[ ! -f "${DOMAIN_CONFIG_FILE}" ]]; then
    log_error "Configuration du domaine introuvable !"
    log_error "Le module 00-domain-config.sh doit être exécuté en premier"
    exit 1
fi

# shellcheck disable=SC1090
source "${DOMAIN_CONFIG_FILE}"

if [[ -z "${SERVER_DOMAIN}" ]] || [[ -z "${LETSENCRYPT_EMAIL}" ]]; then
    log_error "Configuration du domaine incomplète"
    exit 1
fi

log_info "Domaine configuré : ${SERVER_DOMAIN}"
log_info "Email Let's Encrypt : ${LETSENCRYPT_EMAIL}"

# Vérifier si Nginx est installé
if ! command -v nginx &> /dev/null; then
    log_error "Nginx n'est pas installé !"
    log_error "Le module 05-web-server.sh doit être exécuté avant celui-ci"
    exit 1
fi

# Installation de Certbot et du plugin Nginx
log_info "Installation de Certbot et du plugin Nginx..."

export DEBIAN_FRONTEND=noninteractive
apt-get install -y certbot python3-certbot-nginx

log_info "✓ Certbot installé"

# Vérifier que le domaine pointe vers ce serveur
log_warning "Vérification DNS en cours..."
echo ""
log_info "IMPORTANT : Votre domaine ${SERVER_DOMAIN} doit pointer vers ce serveur"
log_info "Vérifiez que :"
echo "  1. Un enregistrement A pointe vers l'IP publique de ce serveur"
echo "  2. Les enregistrements DNS sont propagés (peut prendre jusqu'à 48h)"
echo ""

# En mode non-interactif ou si confirmé via variable d'environnement, continuer automatiquement
if [[ "${DNS_CONFIGURED:-}" == "yes" ]] || [[ ! -t 0 ]]; then
    log_info "Mode automatique : DNS considéré comme configuré"
    DNS_READY="o"
else
    read -p "Votre DNS est-il correctement configuré ? [o/N]: " DNS_READY
    DNS_READY=${DNS_READY:-N}
fi

if [[ ! "${DNS_READY}" =~ ^[Oo]$ ]]; then
    log_warning "Configuration DNS non confirmée"
    log_warning "Les certificats SSL ne seront pas générés maintenant"
    log_info "Vous pourrez les générer plus tard avec la commande :"
    echo ""
    echo "  sudo certbot --nginx -d ${SERVER_DOMAIN} -d www.${SERVER_DOMAIN}"
    echo ""
    
    # Créer un script pour faciliter la génération ultérieure
    CERTBOT_SCRIPT="/usr/local/bin/generate-ssl"
    cat > "${CERTBOT_SCRIPT}" << 'EOFSCRIPT'
#!/bin/bash
# Script de génération des certificats SSL

source /etc/server-domain.conf

echo "Génération des certificats SSL pour ${SERVER_DOMAIN}..."
certbot --nginx -d "${SERVER_DOMAIN}" -d "www.${SERVER_DOMAIN}" \
    --non-interactive \
    --agree-tos \
    --email "${LETSENCRYPT_EMAIL}" \
    --redirect

echo ""
echo "✓ Certificats SSL générés avec succès"
echo "✓ HTTPS activé et redirection automatique configurée"
EOFSCRIPT
    
    chmod +x "${CERTBOT_SCRIPT}"
    log_info "✓ Script de génération créé : ${CERTBOT_SCRIPT}"
    
    exit 0
fi

# Générer les certificats SSL
log_info "Génération des certificats SSL..."
echo ""

# Construire la liste des domaines
DOMAINS="-d ${SERVER_DOMAIN} -d www.${SERVER_DOMAIN}"

log_info "Certificats pour : ${SERVER_DOMAIN}, www.${SERVER_DOMAIN}"

# Générer les certificats avec Certbot
# shellcheck disable=SC2086
if certbot --nginx ${DOMAINS} \
    --non-interactive \
    --agree-tos \
    --email "${LETSENCRYPT_EMAIL}" \
    --redirect; then
    
    log_info "✓ Certificats SSL générés avec succès !"
    
    # Vérifier le renouvellement automatique
    log_info "Vérification du renouvellement automatique..."
    
    if certbot renew --dry-run; then
        log_info "✓ Renouvellement automatique configuré"
    else
        log_warning "Attention : Le renouvellement automatique pourrait avoir un problème"
    fi
    
    # Créer un script de test de renouvellement
    RENEW_TEST_SCRIPT="/usr/local/bin/test-ssl-renewal"
    cat > "${RENEW_TEST_SCRIPT}" << 'EOFRENEW'
#!/bin/bash
# Test du renouvellement des certificats SSL

echo "Test du renouvellement des certificats SSL..."
certbot renew --dry-run

if [ $? -eq 0 ]; then
    echo "✓ Le renouvellement automatique fonctionne correctement"
else
    echo "✗ Problème avec le renouvellement automatique"
    exit 1
fi
EOFRENEW
    
    chmod +x "${RENEW_TEST_SCRIPT}"
    log_info "✓ Script de test créé : ${RENEW_TEST_SCRIPT}"
    
else
    log_error "Échec de la génération des certificats SSL"
    log_error "Vérifiez que :"
    echo "  1. Le domaine ${SERVER_DOMAIN} pointe vers ce serveur"
    echo "  2. Les ports 80 et 443 sont ouverts"
    echo "  3. Nginx est bien démarré"
    echo ""
    log_info "Vous pouvez réessayer manuellement avec :"
    echo "  sudo certbot --nginx -d ${SERVER_DOMAIN} -d www.${SERVER_DOMAIN}"
    exit 1
fi

# Configuration du renouvellement automatique (déjà fait par Certbot, mais on vérifie)
log_info "Vérification de la tâche cron de renouvellement..."

if systemctl is-active --quiet certbot.timer; then
    log_info "✓ Timer systemd certbot.timer actif"
else
    log_warning "Timer certbot.timer non actif, activation..."
    systemctl enable certbot.timer
    systemctl start certbot.timer
    log_info "✓ Timer activé"
fi

# Créer un alias pour faciliter la gestion
log_info "Création des alias de commande..."

ALIAS_FILE="/etc/profile.d/ssl-aliases.sh"
cat > "${ALIAS_FILE}" << 'EOFALIAS'
# Alias pour la gestion SSL

alias ssl-renew='sudo certbot renew'
alias ssl-status='sudo certbot certificates'
alias ssl-test='sudo certbot renew --dry-run'
alias ssl-generate='sudo /usr/local/bin/generate-ssl'
EOFALIAS

chmod +x "${ALIAS_FILE}"

log_section "Installation Let's Encrypt - Résumé"

echo ""
echo -e "${GREEN}Certificats SSL :${NC} ✓ Générés et installés"
echo -e "${GREEN}Domaine principal :${NC} ${SERVER_DOMAIN}"
echo -e "${GREEN}Domaine www :${NC} www.${SERVER_DOMAIN}"
echo -e "${GREEN}Email :${NC} ${LETSENCRYPT_EMAIL}"
echo -e "${GREEN}Renouvellement :${NC} Automatique (tous les 60 jours)"
echo -e "${GREEN}HTTPS :${NC} Activé avec redirection automatique"
echo ""

log_info "Commandes disponibles :"
echo "  ssl-status   : Afficher les certificats installés"
echo "  ssl-renew    : Renouveler les certificats manuellement"
echo "  ssl-test     : Tester le renouvellement automatique"
echo ""

log_info "Fichiers importants :"
echo "  Certificats : /etc/letsencrypt/live/${SERVER_DOMAIN}/"
echo "  Logs : /var/log/letsencrypt/"
echo ""

log_warning "RAPPEL : Les certificats se renouvellent automatiquement"
log_warning "Vous recevrez un email à ${LETSENCRYPT_EMAIL} en cas de problème"

echo ""
log_info "✓ Module 10-letsencrypt terminé avec succès"

exit 0
