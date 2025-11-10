#!/bin/bash

################################################################################
# Module 07 - Gaming
# Description: SteamCMD + LGSM (Linux Game Server Manager)
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

TARGET_USER="seb"

if [ "$EUID" -ne 0 ]; then 
    log_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

log_info "=== Installation des Outils Gaming ==="

# 1. Activer l'architecture i386 (32-bit) nécessaire pour SteamCMD
log_info "Activation de l'architecture i386..."
dpkg --add-architecture i386
apt update

# 2. Installation des dépendances SteamCMD
log_info "Installation des dépendances SteamCMD..."
DEBIAN_FRONTEND=noninteractive apt install -y \
    lib32gcc-s1 \
    lib32stdc++6 \
    libsdl2-2.0-0:i386 \
    steamcmd

log_info "✓ SteamCMD installé"

# 3. Installation des dépendances LGSM
log_info "Installation des dépendances LGSM..."
DEBIAN_FRONTEND=noninteractive apt install -y \
    curl \
    wget \
    file \
    tar \
    bzip2 \
    gzip \
    unzip \
    bsdmainutils \
    python3 \
    util-linux \
    ca-certificates \
    binutils \
    bc \
    jq \
    tmux \
    netcat \
    lib32gcc-s1 \
    lib32stdc++6 \
    libsdl2-2.0-0:i386

# Dépendances supplémentaires
DEBIAN_FRONTEND=noninteractive apt install -y \
    libstdc++6 \
    libstdc++6:i386 \
    libcurl4-gnutls-dev:i386 \
    libcurl4 \
    libcurl4:i386

log_info "✓ Dépendances LGSM installées"

# 4. Créer un répertoire pour les serveurs de jeu
if id "$TARGET_USER" &>/dev/null; then
    GAME_DIR="/home/$TARGET_USER/gameservers"
    
    log_info "Création du répertoire pour les serveurs de jeu..."
    mkdir -p "$GAME_DIR"
    chown "$TARGET_USER:$TARGET_USER" "$GAME_DIR"
    
    # Télécharger le script LGSM dans le home de l'utilisateur
    log_info "Téléchargement de LinuxGSM..."
    sudo -u "$TARGET_USER" bash -c "cd $GAME_DIR && curl -Lo linuxgsm.sh https://linuxgsm.sh && chmod +x linuxgsm.sh"
    
    log_info "✓ LinuxGSM installé dans $GAME_DIR"
else
    log_warning "L'utilisateur $TARGET_USER n'existe pas, LGSM non configuré"
fi

# 5. Créer un script d'aide
if id "$TARGET_USER" &>/dev/null; then
    HELP_FILE="$GAME_DIR/README.txt"
    cat > "$HELP_FILE" << 'EOF'
═══════════════════════════════════════════════════════════
  Linux Game Server Manager (LGSM) - Guide d'utilisation
═══════════════════════════════════════════════════════════

LGSM vous permet d'installer et gérer facilement des serveurs de jeux.

INSTALLATION D'UN SERVEUR DE JEU:
---------------------------------

1. Lister les serveurs disponibles:
   ./linuxgsm.sh list

2. Installer un serveur (exemple: CS:GO):
   ./linuxgsm.sh csgoserver

3. Suivre les instructions à l'écran

GESTION DU SERVEUR:
------------------

Une fois installé, utilisez ces commandes (remplacez csgoserver par votre serveur):

./csgoserver start          # Démarrer le serveur
./csgoserver stop           # Arrêter le serveur
./csgoserver restart        # Redémarrer le serveur
./csgoserver update         # Mettre à jour le serveur
./csgoserver details        # Voir les détails
./csgoserver console        # Accéder à la console
./csgoserver monitor        # Monitoring
./csgoserver install        # (Ré)installer

SERVEURS POPULAIRES:
-------------------
- csgoserver (Counter-Strike: Global Offensive)
- tf2server (Team Fortress 2)
- gmodserver (Garry's Mod)
- mcserver (Minecraft)
- rustserver (Rust)
- arkserver (ARK: Survival Evolved)
- sdtdserver (7 Days to Die)
- squadserver (Squad)

DOCUMENTATION:
-------------
https://linuxgsm.com/

═══════════════════════════════════════════════════════════
EOF
    chown "$TARGET_USER:$TARGET_USER" "$HELP_FILE"
fi

log_info "=== Module Gaming Terminé ==="
echo ""
echo -e "${GREEN}SteamCMD:${NC} Installé"
echo -e "${GREEN}LinuxGSM:${NC} Installé"
echo ""

if id "$TARGET_USER" &>/dev/null; then
    echo -e "${YELLOW}Répertoire des serveurs:${NC} $GAME_DIR"
    echo ""
    echo -e "${YELLOW}Pour installer un serveur de jeu:${NC}"
    echo "  1. Connectez-vous en tant que $TARGET_USER"
    echo "  2. cd $GAME_DIR"
    echo "  3. ./linuxgsm.sh <gameserver>"
    echo ""
    echo -e "${YELLOW}Exemple pour CS:GO:${NC}"
    echo "  ./linuxgsm.sh csgoserver"
    echo ""
    echo -e "${YELLOW}Documentation:${NC}"
    echo "  Consultez $GAME_DIR/README.txt"
    echo "  Ou visitez: https://linuxgsm.com/"
fi

echo ""

exit 0
