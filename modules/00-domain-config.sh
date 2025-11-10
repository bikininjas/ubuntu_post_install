#!/bin/bash

# ============================================
# Module 00: Configuration du Domaine
# ============================================
# Description: Demande et configure le nom de domaine principal
#              Sera utilisé pour Nginx, SSH, Let's Encrypt, etc.
# ============================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Fonctions de logging
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_section() { echo -e "\n${YELLOW}=== $1 ===${NC}\n"; }

# Vérification des permissions root
if [[ "${EUID}" -ne 0 ]]; then 
    log_error "Ce script doit être exécuté en tant que root (sudo)"
    exit 1
fi

log_section "Configuration du Domaine Principal"

# Fichier de configuration du domaine
DOMAIN_CONFIG_FILE="/etc/server-domain.conf"

# Vérifier si le domaine est déjà configuré
if [[ -f "${DOMAIN_CONFIG_FILE}" ]]; then
    source "${DOMAIN_CONFIG_FILE}"
    log_info "Domaine déjà configuré: ${SERVER_DOMAIN}"
    log_warning "Pour changer le domaine, éditez ${DOMAIN_CONFIG_FILE}"
    exit 0
fi

# Demander le nom de domaine
echo ""
log_info "Ce domaine sera utilisé pour:"
echo "  - Configuration Nginx (VirtualHost)"
echo "  - Certificat SSL Let's Encrypt"
echo "  - Hostname du serveur"
echo "  - Configuration SSH"
echo ""
log_warning "Assurez-vous que le domaine pointe bien vers ce serveur!"
echo ""

while true; do
    read -p "Entrez votre nom de domaine (ex: example.com): " DOMAIN_INPUT
    
    # Validation du format de domaine
    if [[ -z "${DOMAIN_INPUT}" ]]; then
        log_error "Le domaine ne peut pas être vide"
        continue
    fi
    
    # Validation basique du format (alphanumeric + . et -)
    if [[ ! "${DOMAIN_INPUT}" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        log_error "Format de domaine invalide"
        continue
    fi
    
    # Confirmation
    echo ""
    echo -e "${YELLOW}Domaine configuré:${NC} ${DOMAIN_INPUT}"
    read -p "Confirmer ? [O/n]: " CONFIRM
    CONFIRM=${CONFIRM:-O}
    
    if [[ "${CONFIRM}" =~ ^[Oo]$ ]]; then
        SERVER_DOMAIN="${DOMAIN_INPUT}"
        break
    fi
done

# Demander l'email pour Let's Encrypt
echo ""
log_info "Email pour les notifications Let's Encrypt"
echo "  - Renouvellement de certificats"
echo "  - Alertes de sécurité"
echo ""

while true; do
    read -p "Entrez votre email: " EMAIL_INPUT
    
    if [[ -z "${EMAIL_INPUT}" ]]; then
        log_error "L'email ne peut pas être vide"
        continue
    fi
    
    # Validation basique de l'email
    if [[ ! "${EMAIL_INPUT}" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log_error "Format d'email invalide"
        continue
    fi
    
    echo ""
    echo -e "${YELLOW}Email configuré:${NC} ${EMAIL_INPUT}"
    read -p "Confirmer ? [O/n]: " CONFIRM
    CONFIRM=${CONFIRM:-O}
    
    if [[ "${CONFIRM}" =~ ^[Oo]$ ]]; then
        LETSENCRYPT_EMAIL="${EMAIL_INPUT}"
        break
    fi
done

# Sauvegarder la configuration
log_info "Sauvegarde de la configuration..."
cat > "${DOMAIN_CONFIG_FILE}" << EOF
# Configuration du domaine serveur
# Généré automatiquement par ubuntu_post_install
# Date: $(date)

# Domaine principal du serveur
SERVER_DOMAIN="${SERVER_DOMAIN}"

# Email pour Let's Encrypt
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL}"

# Sous-domaines générés automatiquement
WWW_DOMAIN="www.${SERVER_DOMAIN}"
API_DOMAIN="api.${SERVER_DOMAIN}"
EOF

chmod 644 "${DOMAIN_CONFIG_FILE}"
log_info "✓ Configuration sauvegardée dans ${DOMAIN_CONFIG_FILE}"

# Configurer le hostname
log_info "Configuration du hostname..."
hostnamectl set-hostname "${SERVER_DOMAIN}"
echo "${SERVER_DOMAIN}" > /etc/hostname

# Mettre à jour /etc/hosts
if ! grep -q "${SERVER_DOMAIN}" /etc/hosts; then
    echo "127.0.1.1 ${SERVER_DOMAIN}" >> /etc/hosts
    log_info "✓ Hostname ajouté à /etc/hosts"
fi

log_section "Configuration terminée"

echo ""
log_info "Récapitulatif:"
echo -e "  ${GREEN}Domaine principal:${NC} ${SERVER_DOMAIN}"
echo -e "  ${GREEN}Email Let's Encrypt:${NC} ${LETSENCRYPT_EMAIL}"
echo -e "  ${GREEN}Hostname:${NC} ${SERVER_DOMAIN}"
echo -e "  ${GREEN}Fichier config:${NC} ${DOMAIN_CONFIG_FILE}"
echo ""

log_warning "Important:"
echo "  1. Assurez-vous que votre DNS pointe vers ce serveur"
echo "  2. Les certificats SSL seront générés lors de l'installation du web server"
echo "  3. Le domaine sera utilisé par tous les modules suivants"
echo ""

log_info "✓ Module 00-domain-config terminé avec succès"
