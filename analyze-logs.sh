#!/bin/bash

###############################################################################
# Script d'analyse des logs d'installation
# Utilisation: ./analyze-logs.sh
###############################################################################

LOG_DIR="/var/log/ubuntu-post-install"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  ANALYSE DES LOGS D'INSTALLATION${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [[ ! -d "${LOG_DIR}" ]]; then
    echo -e "${RED}✗ Aucun répertoire de logs trouvé: ${LOG_DIR}${NC}"
    exit 1
fi

# Vérifier si des logs existent
if [[ -z "$(ls -A "${LOG_DIR}" 2>/dev/null)" ]]; then
    echo -e "${YELLOW}⚠ Aucun fichier de log trouvé dans ${LOG_DIR}${NC}"
    exit 0
fi

echo -e "${GREEN}📁 Répertoire des logs: ${LOG_DIR}${NC}"
echo ""

# Liste tous les fichiers de log
echo -e "${YELLOW}Fichiers de log disponibles:${NC}"
ls -lht "${LOG_DIR}/" | grep -v "^total" | head -20
echo ""

# Demander quel module analyser
echo -e "${CYAN}Modules détectés:${NC}"
echo ""
echo "=== Modules disponibles ==="
# shellcheck disable=SC2207,SC2011
MODULES=($(ls "${LOG_DIR}"/*.log 2>/dev/null | xargs -n1 basename | sed 's/-[0-9]*\.log$//' | sort -u))

if [[ ${#MODULES[@]} -eq 0 ]]; then
    echo -e "${YELLOW}Aucun module trouvé${NC}"
    exit 0
fi

for i in "${!MODULES[@]}"; do
    echo "  $((i+1)). ${MODULES[$i]}"
done

echo ""
read -p "Sélectionnez un module (numéro) ou 'all' pour tout voir [1]: " CHOICE
CHOICE=${CHOICE:-1}

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ "${CHOICE}" == "all" ]]; then
    echo -e "${YELLOW}Analyse de tous les logs...${NC}"
    echo ""
    
    for module in "${MODULES[@]}"; do
        echo -e "${CYAN}▶ ${module}${NC}"
        echo -e "${YELLOW}─────────────────────────────────────────${NC}"
        
        LATEST_LOG=$(ls -t "${LOG_DIR}/${module}"-*.log 2>/dev/null | head -1)
        
        if [[ -f "${LATEST_LOG}" ]]; then
            # Chercher les erreurs
            ERRORS=$(grep -iE "(error|erreur|failed|échec|cannot|unable|exception)" "${LATEST_LOG}" | head -10)
            
            if [[ -n "${ERRORS}" ]]; then
                echo -e "${RED}Erreurs détectées:${NC}"
                echo "${ERRORS}"
            else
                echo -e "${GREEN}Aucune erreur évidente détectée${NC}"
            fi
        else
            echo -e "${YELLOW}Aucun log trouvé${NC}"
        fi
        
        echo ""
    done
else
    # Afficher le log d'un module spécifique
    if [[ "${CHOICE}" =~ ^[0-9]+$ ]] && [[ ${CHOICE} -ge 1 ]] && [[ ${CHOICE} -le ${#MODULES[@]} ]]; then
        MODULE="${MODULES[$((CHOICE-1))]}"
        echo -e "${YELLOW}Analyse du module: ${MODULE}${NC}"
        echo ""
        
        LATEST_LOG=$(ls -t "${LOG_DIR}/${MODULE}"-*.log 2>/dev/null | head -1)
        
        if [[ -f "${LATEST_LOG}" ]]; then
            echo -e "${CYAN}Fichier: ${LATEST_LOG}${NC}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            
            # Afficher les erreurs
            echo -e "${RED}🔍 Erreurs détectées:${NC}"
            grep -iE "(error|erreur|failed|échec|cannot|unable|exception)" "${LATEST_LOG}" || echo "Aucune erreur évidente"
            echo ""
            
            # Afficher les dernières lignes
            echo -e "${YELLOW}📄 Dernières 30 lignes du log:${NC}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            tail -30 "${LATEST_LOG}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            
            echo -e "${GREEN}💡 Pour voir le log complet:${NC}"
            echo "   cat ${LATEST_LOG}"
            echo ""
            echo -e "${GREEN}💡 Pour voir en temps réel:${NC}"
            echo "   tail -f ${LATEST_LOG}"
        else
            echo -e "${RED}✗ Aucun log trouvé pour ce module${NC}"
        fi
    else
        echo -e "${RED}✗ Choix invalide${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Analyse terminée${NC}"
