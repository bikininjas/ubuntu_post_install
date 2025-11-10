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
if [ "$EUID" -ne 0 ]; then 
    log_error "Ce script doit être exécuté en tant que root (sudo)"
    exit 1
fi

# Détection du répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

# Vérification de l'existence du dossier modules
if [ ! -d "$MODULES_DIR" ]; then
    log_error "Le dossier modules/ n'existe pas dans $SCRIPT_DIR"
    exit 1
fi

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
log_info "Répertoire de travail: $SCRIPT_DIR"
echo ""

# Liste des modules à exécuter (dans l'ordre)
MODULES=(
    "01-base-system.sh"
    "02-dev-tools.sh"
    "03-docker.sh"
    "04-databases.sh"
    "05-web-server.sh"
    "06-media-tools.sh"
    "07-gaming.sh"
    "08-security.sh"
    "09-update-checker.sh"
)

# Menu de sélection
echo -e "${YELLOW}Choisissez le type d'installation:${NC}"
echo "1) Installation complète (tous les modules)"
echo "2) Installation personnalisée (sélection des modules)"
echo "3) Quitter"
echo ""
read -p "Votre choix [1-3]: " INSTALL_CHOICE

case $INSTALL_CHOICE in
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
            module_name=$(basename "$module" .sh | sed 's/^[0-9]*-//' | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
            read -p "  - $module_name ? [O/n]: " response
            response=${response:-O}
            if [[ "$response" =~ ^[Oo]$ ]]; then
                SELECTED_MODULES+=("$module")
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
if [ ${#SELECTED_MODULES[@]} -eq 0 ]; then
    log_warning "Aucun module sélectionné. Installation annulée."
    exit 0
fi

# Affichage des modules sélectionnés
echo ""
log_section "Modules sélectionnés pour l'installation"
for module in "${SELECTED_MODULES[@]}"; do
    module_name=$(basename "$module" .sh | sed 's/^[0-9]*-//' | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
    echo -e "  ${GREEN}✓${NC} $module_name"
done
echo ""

log_info "L'installation va démarrer dans 3 secondes..."
sleep 3

# Mise à jour du système avant de commencer (seulement si le module 01 n'est pas sélectionné)
if [[ ! " ${SELECTED_MODULES[*]} " =~ " 01-base-system.sh " ]]; then
    log_section "Mise à jour du système"
    log_info "Mise à jour des repositories apt..."
    apt update

    log_info "Mise à niveau des packages existants..."
    DEBIAN_FRONTEND=noninteractive apt upgrade -y
fi

log_info "Installation des dépendances de base..."
DEBIAN_FRONTEND=noninteractive apt install -y curl wget git build-essential software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Exécution des modules sélectionnés
FAILED_MODULES=()
SUCCESSFUL_MODULES=()

for module in "${SELECTED_MODULES[@]}"; do
    module_path="$MODULES_DIR/$module"
    module_name=$(basename "$module" .sh | sed 's/^[0-9]*-//' | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
    
    if [ ! -f "$module_path" ]; then
        log_error "Module non trouvé: $module_path"
        FAILED_MODULES+=("$module_name")
        continue
    fi
    
    if [ ! -x "$module_path" ]; then
        log_warning "Le module $module n'est pas exécutable, ajout des permissions..."
        chmod +x "$module_path"
    fi
    
    log_section "Exécution: $module_name"
    
    if bash "$module_path"; then
        log_info "✓ Module $module_name terminé avec succès"
        SUCCESSFUL_MODULES+=("$module_name")
    else
        log_error "✗ Échec du module $module_name"
        FAILED_MODULES+=("$module_name")
        
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

if [ ${#SUCCESSFUL_MODULES[@]} -gt 0 ]; then
    echo -e "${GREEN}Modules installés avec succès:${NC}"
    for module in "${SUCCESSFUL_MODULES[@]}"; do
        echo -e "  ${GREEN}✓${NC} $module"
    done
fi

if [ ${#FAILED_MODULES[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}Modules en échec:${NC}"
    for module in "${FAILED_MODULES[@]}"; do
        echo -e "  ${RED}✗${NC} $module"
    done
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

if [ ${#FAILED_MODULES[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ Toutes les installations ont réussi!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Certaines installations ont échoué. Consultez les logs ci-dessus.${NC}"
    exit 1
fi
