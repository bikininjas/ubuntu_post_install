#!/bin/bash

################################################################################
# Script Principal - Post-Installation Ubuntu 24.04
# Auteur: Seb (sebpicot@gmail.com)
# Date: 2025-11-10
# Description: Script orchestrateur pour l'installation modulaire
################################################################################

set -e  # Arrêt en cas d'erreur

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fonctions de logging
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_section() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}

# Vérification des privilèges root
if [[ "${EUID}" -ne 0 ]]; then 
    log_error "Ce script doit être exécuté en tant que root (sudo)"
    exit 1
fi

# Détection du répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${SCRIPT_DIR}/modules"
ENV_FILE="${SCRIPT_DIR}/.env"

# Vérification de l'existence du dossier modules
if [[ ! -d "${MODULES_DIR}" ]]; then
    log_error "Le dossier modules/ n'existe pas dans ${SCRIPT_DIR}"
    exit 1
fi

################################################################################
# Chargement de la configuration depuis .env ou saisie interactive
################################################################################

load_configuration() {
    log_info "Chargement de la configuration..."
    
    # Variables par défaut
    export TARGET_USER="seb"
    export TARGET_USER_PASSWORD=""
    export GIT_USER="SebPikPik"
    export GIT_EMAIL="sebpicot@gmail.com"
    export SERVER_DOMAIN=""
    export LETSENCRYPT_EMAIL=""
    export ALLOWED_SSH_IP=""
    export GITREPOS_DIR="/home/${TARGET_USER}/GITRepos"
    export GAME_DIR="/home/${TARGET_USER}/gameservers"
    
    # Variables Grafana Cloud (optionnelles)
    export GCLOUD_HOSTED_METRICS_ID=""
    export GCLOUD_HOSTED_METRICS_URL=""
    export GCLOUD_HOSTED_LOGS_ID=""
    export GCLOUD_HOSTED_LOGS_URL=""
    export GCLOUD_RW_API_KEY=""
    
    # Charger le fichier .env s'il existe
    if [[ -f "${ENV_FILE}" ]]; then
        log_info "Fichier .env trouvé, chargement des variables..."
        # Source le fichier .env en ignorant les commentaires et lignes vides
        # shellcheck disable=SC1090
        set -a  # Exporter automatiquement toutes les variables
        source <(grep -v '^#' "${ENV_FILE}" | grep -v '^$')
        set +a
        log_info "✓ Configuration chargée depuis ${ENV_FILE}"
    else
        log_warning "Aucun fichier .env trouvé, passage en mode interactif"
        log_info "💡 Conseil: Créez un fichier .env depuis .env.example pour éviter les questions"
        echo ""
    fi
    
    # Demander les informations manquantes en mode interactif
    if [[ -z "${TARGET_USER}" ]]; then
        read -p "Nom d'utilisateur à créer [seb]: " TARGET_USER
        TARGET_USER=${TARGET_USER:-seb}
    fi
    export TARGET_USER
    export GITREPOS_DIR="/home/${TARGET_USER}/GITRepos"
    export GAME_DIR="/home/${TARGET_USER}/gameservers"
    
    if [[ -z "${GIT_USER}" ]]; then
        read -p "Nom d'utilisateur Git [${TARGET_USER}]: " GIT_USER
        GIT_USER=${GIT_USER:-${TARGET_USER}}
    fi
    export GIT_USER
    
    if [[ -z "${GIT_EMAIL}" ]]; then
        read -p "Email Git: " GIT_EMAIL
    fi
    export GIT_EMAIL
    
    if [[ -z "${SERVER_DOMAIN}" ]]; then
        read -p "Nom de domaine (ex: example.com) [optionnel]: " SERVER_DOMAIN
    fi
    export SERVER_DOMAIN
    
    if [[ -n "${SERVER_DOMAIN}" ]] && [[ -z "${LETSENCRYPT_EMAIL}" ]]; then
        read -p "Email Let's Encrypt [${GIT_EMAIL}]: " LETSENCRYPT_EMAIL
        LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL:-${GIT_EMAIL}}
    fi
    export LETSENCRYPT_EMAIL
    
    if [[ -z "${ALLOWED_SSH_IP}" ]]; then
        echo ""
        log_warning "IMPORTANT: Quelle IP doit être autorisée pour SSH?"
        log_warning "Cette IP sera la SEULE autorisée à se connecter en SSH (port 22)"
        read -p "IP autorisée pour SSH (xxx.xxx.xxx.xxx): " ALLOWED_SSH_IP
    fi
    export ALLOWED_SSH_IP
    
    # Afficher un résumé de la configuration
    echo ""
    log_section "Configuration chargée"
    echo -e "${CYAN}Utilisateur:${NC} ${TARGET_USER}"
    echo -e "${CYAN}Git:${NC} ${GIT_USER} <${GIT_EMAIL}>"
    if [[ -n "${SERVER_DOMAIN}" ]]; then
        echo -e "${CYAN}Domaine:${NC} ${SERVER_DOMAIN}"
        echo -e "${CYAN}Let's Encrypt Email:${NC} ${LETSENCRYPT_EMAIL}"
    fi
    echo -e "${CYAN}SSH autorisé depuis:${NC} ${ALLOWED_SSH_IP}"
    echo -e "${CYAN}Dossier repos:${NC} ${GITREPOS_DIR}"
    
    # Afficher la config Grafana Cloud si configurée
    if [[ -n "${GCLOUD_HOSTED_METRICS_URL}" ]] && [[ -n "${GCLOUD_HOSTED_LOGS_URL}" ]]; then
        echo ""
        echo -e "${GREEN}Grafana Cloud (Monitoring):${NC}"
        echo -e "${CYAN}  Metrics ID:${NC} ${GCLOUD_HOSTED_METRICS_ID}"
        echo -e "${CYAN}  Metrics URL:${NC} ${GCLOUD_HOSTED_METRICS_URL}"
        echo -e "${CYAN}  Logs ID:${NC} ${GCLOUD_HOSTED_LOGS_ID}"
        echo -e "${CYAN}  Logs URL:${NC} ${GCLOUD_HOSTED_LOGS_URL}"
        echo -e "${CYAN}  API Key:${NC} ${GCLOUD_RW_API_KEY:0:20}... (configuré)"
    else
        echo ""
        echo -e "${YELLOW}Grafana Cloud:${NC} Non configuré (module 11 demandera les credentials)"
    fi
    echo ""
    
    # Confirmer avant de continuer
    read -p "Confirmer cette configuration? [O/n]: " CONFIRM
    CONFIRM=${CONFIRM:-O}
    if [[ ! "${CONFIRM}" =~ ^[Oo]$ ]]; then
        log_error "Configuration annulée"
        exit 1
    fi
    
    log_info "✓ Configuration validée"
    echo ""
}

# Charger la configuration dès le début
load_configuration

# Banner
clear
echo -e "${MAGENTA}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        Ubuntu 24.04 Post-Installation Script             ║
║                                                           ║
║           Configuration Automatisée Complète             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

log_info "Démarrage de l'installation..."
log_info "Répertoire de travail: ${SCRIPT_DIR}"
echo ""

# Liste des modules à exécuter (dans l'ordre)
MODULES=(
    "00-domain-config.sh"
    "01-base-system.sh"
    "02-dev-tools.sh"
    "03-docker.sh"
    "04-databases.sh"
    "08-security.sh"
    "05-web-server.sh"
    "06-media-tools.sh"
    "07-gaming.sh"
    "09-update-checker.sh"
    "10-letsencrypt.sh"
    "11-grafana-alloy.sh"
)

# Menu interactif
echo ""# Menu de sélection
echo -e "${YELLOW}Choisissez le type d'installation:${NC}"
echo "1) Installation complète (tous les modules)"
echo "2) Installation personnalisée (sélection des modules)"
echo "3) Quitter"
echo ""
read -p "Votre choix [1-3]: " INSTALL_CHOICE

case ${INSTALL_CHOICE} in
    1)
        log_info "Installation complète sélectionnée"
        SELECTED_MODULES=("${MODULES[@]}")
        ;;
    2)
        log_info "Installation personnalisée"
        SELECTED_MODULES=()
        echo ""
        echo "Sélectionnez les modules à installer (O/n):"
        for module in "${MODULES[@]}"; do
            # shellcheck disable=SC2312
            module_name=$(basename "${module}" .sh | sed 's/^[0-9]*-//' | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
            read -p "  - ${module_name} ? [O/n]: " response
            response=${response:-O}
            if [[ "${response}" =~ ^[Oo]$ ]]; then
                SELECTED_MODULES+=("${module}")
            fi
        done
        ;;
    3)
        log_info "Installation annulée"
        exit 0
        ;;
    *)
        log_error "Choix invalide"
        exit 1
        ;;
esac

# Vérification que des modules ont été sélectionnés
if [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then
    log_warning "Aucun module sélectionné. Installation annulée."
    exit 0
fi

# Affichage des modules sélectionnés
echo ""
log_section "Modules sélectionnés pour l'installation"
for module in "${SELECTED_MODULES[@]}"; do
    # shellcheck disable=SC2312
    module_name=$(basename "${module}" .sh | sed 's/^[0-9]*-//' | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
    echo -e "  ${GREEN}✓${NC} ${module_name}"
done
echo ""

log_info "L'installation va démarrer dans 3 secondes..."
sleep 3

# Mise à jour du système avant de commencer (seulement si le module 01 n'est pas sélectionné)
# Le module 00 (domain-config) doit toujours s'exécuter en premier s'il est sélectionné
if [[ ! " ${SELECTED_MODULES[*]} " == *" 01-base-system.sh "* ]]; then
    log_section "Mise à jour du système"
    log_info "Mise à jour des repositories apt..."
    apt update

    log_info "Mise à niveau des packages existants..."
    DEBIAN_FRONTEND=noninteractive apt upgrade -y
fi

log_info "Installation des dépendances de base..."
DEBIAN_FRONTEND=noninteractive apt install -y curl wget git build-essential software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Créer un répertoire pour les logs
LOG_DIR="/var/log/ubuntu-post-install"
mkdir -p "${LOG_DIR}"
MAIN_LOG="${LOG_DIR}/installation-$(date +%Y%m%d-%H%M%S).log"

log_info "Logs détaillés: ${MAIN_LOG}"
echo ""

# Exécution des modules sélectionnés
FAILED_MODULES=()
SUCCESSFUL_MODULES=()
declare -A MODULE_ERRORS  # Associative array pour stocker les erreurs

for module in "${SELECTED_MODULES[@]}"; do
    module_path="${MODULES_DIR}/${module}"
    # shellcheck disable=SC2312
    module_name=$(basename "${module}" .sh | sed 's/^[0-9]*-//' | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
    
    # Créer un fichier de log pour ce module
    MODULE_LOG="${LOG_DIR}/${module%.sh}-$(date +%Y%m%d-%H%M%S).log"
    
    if [[ ! -f "${module_path}" ]]; then
        log_error "Module non trouvé: ${module_path}"
        FAILED_MODULES+=("${module_name}")
        MODULE_ERRORS["${module_name}"]="Fichier module introuvable: ${module_path}"
        continue
    fi
    
    if [[ ! -x "${module_path}" ]]; then
        log_warning "Le module ${module} n'est pas exécutable, ajout des permissions..."
        chmod +x "${module_path}"
    fi
    
    log_section "Exécution: ${module_name}"
    
    # Exécuter le module avec capture des erreurs
    set +e  # Désactiver l'arrêt automatique pour ce module
    bash "${module_path}" 2>&1 | tee "${MODULE_LOG}"
    EXIT_CODE=${PIPESTATUS[0]}
    set -e  # Réactiver l'arrêt automatique
    
    if [[ ${EXIT_CODE} -eq 0 ]]; then
        log_info "✓ Module ${module_name} terminé avec succès"
        SUCCESSFUL_MODULES+=("${module_name}")
    else
        log_error "✗ Échec du module ${module_name} (code de sortie: ${EXIT_CODE})"
        FAILED_MODULES+=("${module_name}")
        
        # Capturer les dernières lignes d'erreur en excluant les faux positifs
        ERROR_CONTEXT=$(tail -30 "${MODULE_LOG}" | \
            grep -iE "(error|erreur|failed|échec|exception|cannot|unable|no such)" | \
            grep -viE "(libgpg-error|unable to delete old directory|Unable to find image|SyntaxWarning|dpkg: warning|Python modules in the official Ubuntu)" || \
            tail -20 "${MODULE_LOG}")
        MODULE_ERRORS["${module_name}"]="${ERROR_CONTEXT}"
        
        echo ""
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "ERREUR DÉTAILLÉE - ${module_name}"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${YELLOW}Dernières lignes du log:${NC}"
        echo "${ERROR_CONTEXT}"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        log_info "📁 Log complet: ${MODULE_LOG}"
        log_info "💡 Pour voir: cat ${MODULE_LOG}"
        echo ""
        
        log_warning "Continuation automatique malgré l'erreur..."
    fi
    
    echo ""
done

# Nettoyage final
log_section "Nettoyage Final"
log_info "Nettoyage du cache apt..."
apt autoremove -y
apt autoclean

# Rapport final
log_section "Rapport d'Installation"

if [[ ${#SUCCESSFUL_MODULES[@]} -gt 0 ]]; then
    echo -e "${GREEN}Modules installés avec succès:${NC}"
    for module in "${SUCCESSFUL_MODULES[@]}"; do
        echo -e "  ${GREEN}✓${NC} ${module}"
    done
fi

if [[ ${#FAILED_MODULES[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}Modules en échec:${NC}"
    for module in "${FAILED_MODULES[@]}"; do
        echo -e "  ${RED}✗${NC} ${module}"
    done
    
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  DÉTAILS DES ERREURS${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    for module in "${FAILED_MODULES[@]}"; do
        echo -e "${RED}▶ ${module}:${NC}"
        if [[ -n "${MODULE_ERRORS[${module}]}" ]]; then
            echo "${MODULE_ERRORS[${module}]}" | head -10
        else
            echo "  Aucun détail d'erreur disponible"
        fi
        echo ""
    done
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📁 Logs complets disponibles dans:${NC} ${LOG_DIR}"
    echo ""
    echo -e "${CYAN}Pour voir les logs détaillés d'un module:${NC}"
    echo "  ls -lht ${LOG_DIR}/"
    echo "  cat ${LOG_DIR}/<nom-module>*.log"
    echo ""
fi

echo ""
log_section "Installation Terminée!"

# Messages post-installation
echo ""
echo -e "${CYAN}Prochaines étapes:${NC}"
echo ""
echo "1. Si l'utilisateur 'seb' a été créé, redémarrez votre session:"
echo -e "   ${YELLOW}su - seb${NC}"
echo ""
echo "2. Si Docker a été installé, déconnectez-vous et reconnectez-vous pour que"
echo "   les groupes soient appliqués, ou redémarrez le système:"
echo -e "   ${YELLOW}sudo reboot${NC}"
echo ""
echo "3. Vérifiez les installations:"
echo -e "   ${YELLOW}docker --version${NC}"
echo -e "   ${YELLOW}python3.13 --version${NC}"
echo -e "   ${YELLOW}node --version${NC}"
echo -e "   ${YELLOW}go version${NC}"
echo ""
echo "4. Consultez les logs en cas de problème:"
echo -e "   ${YELLOW}sudo journalctl -xe${NC}"
echo ""

if [[ ${#FAILED_MODULES[@]} -eq 0 ]]; then
    echo -e "${GREEN}✓ Toutes les installations ont réussi!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Certaines installations ont échoué. Consultez les logs ci-dessus.${NC}"
    exit 1
fi
