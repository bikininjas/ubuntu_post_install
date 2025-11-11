#!/bin/bash

###############################################################################
# Script de vérification ShellCheck locale
# Utilisation: ./check-shellcheck.sh
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  ShellCheck - Vérification Locale${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Vérifier si shellcheck est installé
if ! command -v shellcheck &> /dev/null; then
    echo -e "${RED}✗ ShellCheck n'est pas installé${NC}"
    echo ""
    echo "Installation:"
    echo "  sudo apt install shellcheck"
    echo "  ou: sudo snap install shellcheck"
    exit 1
fi

echo -e "${GREEN}✓ ShellCheck version:${NC} $(shellcheck --version | grep version:)"
echo ""

# Trouver tous les scripts shell
SCRIPTS=$(find . -type f -name "*.sh" -not -path "./.git/*" -not -path "./.github/*")
SCRIPT_COUNT=$(echo "$SCRIPTS" | wc -l)

echo -e "${YELLOW}Vérification de ${SCRIPT_COUNT} scripts...${NC}"
echo ""

ERRORS=0
WARNINGS=0

# Vérifier chaque script
while IFS= read -r script; do
    echo -e "${CYAN}▶${NC} $(basename "$script")"
    
    # Exécuter shellcheck et capturer la sortie
    if OUTPUT=$(shellcheck -x "$script" 2>&1); then
        echo -e "  ${GREEN}✓ Aucun problème${NC}"
    else
        echo "$OUTPUT" | while IFS= read -r line; do
            if echo "$line" | grep -q "error:"; then
                ((ERRORS++)) || true
                echo -e "  ${RED}$line${NC}"
            elif echo "$line" | grep -q "warning:"; then
                ((WARNINGS++)) || true
                echo -e "  ${YELLOW}$line${NC}"
            else
                echo -e "  $line"
            fi
        done
    fi
    echo ""
done <<< "$SCRIPTS"

# Résumé
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Résumé${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Scripts vérifiés: ${SCRIPT_COUNT}"
echo -e "${RED}Erreurs: ${ERRORS}${NC}"
echo -e "${YELLOW}Avertissements: ${WARNINGS}${NC}"
echo ""

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}✓ Tous les scripts sont valides !${NC}"
    echo -e "${GREEN}✓ Vous pouvez commit en toute sécurité.${NC}"
    exit 0
else
    echo -e "${RED}✗ Des erreurs ont été détectées.${NC}"
    echo -e "${RED}✗ Veuillez les corriger avant de commit.${NC}"
    exit 1
fi
