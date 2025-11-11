#!/bin/bash

################################################################################
# Module 01 - Configuration Système de Base
# Description: Création utilisateur, zsh, oh-my-zsh, Git config
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

# Variables
TARGET_USER="seb"
GIT_USER="SebPikPik"
GIT_EMAIL="sebpicot@gmail.com"
GITREPOS_DIR="/home/${TARGET_USER}/GITRepos"

# Vérification root
if [[ "${EUID}" -ne 0 ]]; then 
    log_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

log_info "=== Configuration Système de Base ==="

# 0. Mise à jour du système
log_info "Mise à jour du système..."
log_info "Mise à jour des repositories apt..."
apt update -y

log_info "Mise à niveau des packages existants..."
DEBIAN_FRONTEND=noninteractive apt upgrade -y

log_info "✓ Système mis à jour"

# 1. Vérifier si l'utilisateur existe
if id "$TARGET_USER" &>/dev/null; then
    log_warning "L'utilisateur '$TARGET_USER' existe déjà"
else
    log_info "Création de l'utilisateur '$TARGET_USER'..."
    
    # Vérifier si le script est lancé de manière interactive
    if [ -t 0 ]; then
        # Mode interactif : demander le mot de passe
        while true; do
            read -s -p "Entrez le mot de passe pour l'utilisateur $TARGET_USER: " PASSWORD
            echo ""
            read -s -p "Confirmez le mot de passe: " PASSWORD_CONFIRM
            echo ""
            
            if [ "$PASSWORD" = "$PASSWORD_CONFIRM" ]; then
                break
            else
                log_error "Les mots de passe ne correspondent pas. Réessayez."
            fi
        done
    else
        # Mode non-interactif : générer un mot de passe aléatoire
        log_warning "Mode non-interactif détecté"
        PASSWORD=$(openssl rand -base64 32)
        PASSWORD_FILE="/root/.${TARGET_USER}_initial_password.txt"
        echo "$PASSWORD" > "$PASSWORD_FILE"
        chmod 600 "$PASSWORD_FILE"
        log_warning "Mot de passe généré automatiquement et sauvegardé dans $PASSWORD_FILE"
        log_warning "IMPORTANT: Changez ce mot de passe après la première connexion!"
    fi
    
    # Créer l'utilisateur avec home directory
    useradd -m -s /bin/bash "$TARGET_USER"
    echo "$TARGET_USER:$PASSWORD" | chpasswd
    
    # Ajouter au groupe sudo
    usermod -aG sudo "$TARGET_USER"
    
    log_info "✓ Utilisateur '$TARGET_USER' créé avec succès"
fi

# 2. Configuration sudoers (apt et docker sans mot de passe)
log_info "Configuration des permissions sudo..."

SUDOERS_FILE="/etc/sudoers.d/$TARGET_USER"
cat > "$SUDOERS_FILE" << EOF
# Permissions sudo pour l'utilisateur $TARGET_USER
# Commandes apt sans mot de passe
$TARGET_USER ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get

# Commandes docker sans mot de passe
$TARGET_USER ALL=(ALL) NOPASSWD: /usr/bin/docker

# Autres commandes avec mot de passe
$TARGET_USER ALL=(ALL) ALL
EOF

chmod 440 "$SUDOERS_FILE"
log_info "✓ Configuration sudoers appliquée"

# 3. Créer le dossier GITRepos
log_info "Création du dossier GITRepos..."
if [ ! -d "$GITREPOS_DIR" ]; then
    mkdir -p "$GITREPOS_DIR"
    chown "$TARGET_USER:$TARGET_USER" "$GITREPOS_DIR"
    log_info "✓ Dossier $GITREPOS_DIR créé"
else
    log_warning "Le dossier $GITREPOS_DIR existe déjà"
fi

# 4. Installation de zsh
log_info "Installation de zsh..."
DEBIAN_FRONTEND=noninteractive apt install -y zsh

# Définir zsh comme shell par défaut pour l'utilisateur
chsh -s "$(which zsh)" "$TARGET_USER"
log_info "✓ zsh installé et défini comme shell par défaut"

# 5. Installation de oh-my-zsh
log_info "Installation de oh-my-zsh..."

# Télécharger et installer oh-my-zsh pour l'utilisateur
if [ ! -d "/home/$TARGET_USER/.oh-my-zsh" ]; then
    # Installation en tant qu'utilisateur cible
    sudo -u "$TARGET_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    log_info "✓ oh-my-zsh installé"
else
    log_warning "oh-my-zsh est déjà installé"
fi

# Configuration .zshrc basique
ZSHRC_FILE="/home/$TARGET_USER/.zshrc"
if [ -f "$ZSHRC_FILE" ]; then
    # Ajouter quelques configurations utiles si elles n'existent pas
    grep -q "alias ll=" "$ZSHRC_FILE" || echo 'alias ll="ls -lah"' >> "$ZSHRC_FILE"
    grep -q "alias gs=" "$ZSHRC_FILE" || echo 'alias gs="git status"' >> "$ZSHRC_FILE"
    grep -q "alias gp=" "$ZSHRC_FILE" || echo 'alias gp="git pull"' >> "$ZSHRC_FILE"
    grep -q "alias gc=" "$ZSHRC_FILE" || echo 'alias gc="git commit"' >> "$ZSHRC_FILE"
    
    chown "$TARGET_USER:$TARGET_USER" "$ZSHRC_FILE"
    log_info "✓ Configuration .zshrc mise à jour"
fi

# 6. Configuration Git globale
log_info "Configuration de Git..."
sudo -u "$TARGET_USER" git config --global user.name "$GIT_USER"
sudo -u "$TARGET_USER" git config --global user.email "$GIT_EMAIL"
sudo -u "$TARGET_USER" git config --global init.defaultBranch main
sudo -u "$TARGET_USER" git config --global core.editor "nano"

log_info "✓ Git configuré pour $GIT_USER <$GIT_EMAIL>"

# 7. Créer un fichier de bienvenue
WELCOME_FILE="/home/$TARGET_USER/.welcome"
cat > "$WELCOME_FILE" << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║           Bienvenue sur votre serveur Ubuntu!            ║
║                                                           ║
║  Ce serveur a été configuré automatiquement avec:        ║
║  - zsh + oh-my-zsh                                       ║
║  - Docker                                                 ║
║  - Python 3.13, Node.js, Go, Terraform                   ║
║  - Nginx, MySQL, PostgreSQL                              ║
║  - FFmpeg, SteamCMD, LGSM                                ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
chown "$TARGET_USER:$TARGET_USER" "$WELCOME_FILE"

# Ajouter l'affichage du message dans .zshrc
grep -q ".welcome" "$ZSHRC_FILE" || echo '[ -f ~/.welcome ] && cat ~/.welcome' >> "$ZSHRC_FILE"

log_info "=== Module Système de Base Terminé ==="
echo ""
echo -e "${GREEN}Utilisateur:${NC} $TARGET_USER"
echo -e "${GREEN}Shell:${NC} zsh avec oh-my-zsh"
echo -e "${GREEN}Dossier repos:${NC} $GITREPOS_DIR"
echo -e "${GREEN}Git config:${NC} $GIT_USER <$GIT_EMAIL>"
echo ""

exit 0
