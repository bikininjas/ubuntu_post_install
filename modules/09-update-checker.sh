#!/bin/bash

################################################################################
# Module 09 - Vérificateur de Mises à Jour Automatique
# Description: Configure un système de vérification automatique des mises à jour
#              et ajoute un rappel à chaque connexion SSH
################################################################################

set -e

# Import des fonctions de logging si disponibles
if declare -f log_info >/dev/null 2>&1; then
    : # Les fonctions existent déjà
else
    log_info() { echo "[INFO] $1"; }
    log_error() { echo "[ERROR] $1"; }
    log_warning() { echo "[WARNING] $1"; }
fi

log_info "Configuration du système de vérification des mises à jour..."

# Variables
UPDATE_CHECK_SCRIPT="/usr/local/bin/check-updates.sh"
UPDATE_LOG="/var/log/update-checker.log"
UPDATE_FLAG="/var/run/updates-available"

# Créer le script de vérification des mises à jour
log_info "Création du script de vérification..."
cat > "$UPDATE_CHECK_SCRIPT" << 'EOFSCRIPT'
#!/bin/bash

################################################################################
# Script de Vérification des Mises à Jour
# Description: Vérifie si des mises à jour sont disponibles et crée un flag
################################################################################

LOG_FILE="/var/log/update-checker.log"
FLAG_FILE="/var/run/updates-available"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Fonction de logging
log_message() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

# Rotation du log si trop volumineux (> 10MB)
if [ -f "$LOG_FILE" ] && [ $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE") -gt 10485760 ]; then
    mv "$LOG_FILE" "$LOG_FILE.old"
    log_message "Log rotated"
fi

log_message "Démarrage de la vérification des mises à jour..."

# Mise à jour de la liste des packages
apt update > /dev/null 2>&1

# Vérifier les mises à jour disponibles
UPDATES=$(apt list --upgradable 2>/dev/null | grep -v "Listing" | wc -l)
SECURITY_UPDATES=$(apt list --upgradable 2>/dev/null | grep -i security | wc -l)

if [ "$UPDATES" -gt 0 ]; then
    log_message "Mises à jour disponibles: $UPDATES packages (dont $SECURITY_UPDATES mises à jour de sécurité)"
    
    # Créer le fichier flag avec les informations
    cat > "$FLAG_FILE" << EOF
UPDATES=$UPDATES
SECURITY_UPDATES=$SECURITY_UPDATES
LAST_CHECK=$TIMESTAMP
EOF
    
    chmod 644 "$FLAG_FILE"
    log_message "Flag créé: $FLAG_FILE"
    
    # Liste des packages à mettre à jour (limitée aux 20 premiers)
    echo "[$TIMESTAMP] Packages à mettre à jour:" >> "$LOG_FILE"
    apt list --upgradable 2>/dev/null | grep -v "Listing" | head -20 >> "$LOG_FILE"
    
else
    log_message "Aucune mise à jour disponible"
    # Supprimer le flag s'il existe
    rm -f "$FLAG_FILE"
fi

log_message "Vérification terminée"
EOFSCRIPT

chmod +x "$UPDATE_CHECK_SCRIPT"
log_info "✓ Script de vérification créé: $UPDATE_CHECK_SCRIPT"

# Créer le fichier de log
touch "$UPDATE_LOG"
chmod 644 "$UPDATE_LOG"

# Ajouter la tâche cron (tous les 4 jours à 3h du matin)
log_info "Configuration de la tâche cron (tous les 4 jours)..."
CRON_JOB="0 3 */4 * * $UPDATE_CHECK_SCRIPT"

# Vérifier si la tâche existe déjà
if crontab -l 2>/dev/null | grep -q "$UPDATE_CHECK_SCRIPT"; then
    log_warning "La tâche cron existe déjà"
else
    # Ajouter la tâche au crontab
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    log_info "✓ Tâche cron ajoutée"
fi

# Créer le script de rappel pour le shell
log_info "Configuration du rappel de connexion SSH..."
MOTD_SCRIPT="/etc/profile.d/update-reminder.sh"

cat > "$MOTD_SCRIPT" << 'EOFMOTD'
#!/bin/bash

# Script de rappel des mises à jour au login
FLAG_FILE="/var/run/updates-available"

if [ -f "$FLAG_FILE" ]; then
    source "$FLAG_FILE"
    
    echo ""
    echo -e "\033[1;33m╔════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;33m║                                                            ║\033[0m"
    echo -e "\033[1;33m║  ⚠️  MISES À JOUR DISPONIBLES                              ║\033[0m"
    echo -e "\033[1;33m║                                                            ║\033[0m"
    
    if [ "$SECURITY_UPDATES" -gt 0 ]; then
        printf "\033[1;33m║  \033[1;31m🔒 %2d mises à jour de SÉCURITÉ\033[1;33m                         ║\033[0m\n" "$SECURITY_UPDATES"
    fi
    
    printf "\033[1;33m║  📦 %2d packages peuvent être mis à jour\033[1;33m                  ║\033[0m\n" "$UPDATES"
    echo -e "\033[1;33m║                                                            ║\033[0m"
    echo -e "\033[1;33m║  Dernière vérification: $LAST_CHECK              ║\033[0m"
    echo -e "\033[1;33m║                                                            ║\033[0m"
    echo -e "\033[1;33m║  Pour mettre à jour, exécutez:                            ║\033[0m"
    echo -e "\033[1;33m║  \033[1;32msudo apt update && sudo apt upgrade -y\033[1;33m                 ║\033[0m"
    echo -e "\033[1;33m║                                                            ║\033[0m"
    echo -e "\033[1;33m╚════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
fi
EOFMOTD

chmod +x "$MOTD_SCRIPT"
log_info "✓ Script de rappel créé: $MOTD_SCRIPT"

# Ajouter le rappel au .zshrc de l'utilisateur seb
if [ -d "/home/seb" ]; then
    log_info "Configuration du rappel dans .zshrc pour l'utilisateur seb..."
    
    ZSHRC_FILE="/home/seb/.zshrc"
    
    if [ -f "$ZSHRC_FILE" ]; then
        # Vérifier si le rappel existe déjà
        if ! grep -q "update-reminder.sh" "$ZSHRC_FILE"; then
            cat >> "$ZSHRC_FILE" << 'EOFZSHRC'

# Rappel des mises à jour disponibles
if [ -f /etc/profile.d/update-reminder.sh ]; then
    source /etc/profile.d/update-reminder.sh
fi
EOFZSHRC
            chown seb:seb "$ZSHRC_FILE"
            log_info "✓ Rappel ajouté à .zshrc"
        else
            log_warning "Le rappel existe déjà dans .zshrc"
        fi
    else
        log_warning ".zshrc n'existe pas encore pour l'utilisateur seb"
    fi
fi

# Ajouter aussi au .bashrc pour compatibilité
if [ -f "/home/seb/.bashrc" ]; then
    if ! grep -q "update-reminder.sh" "/home/seb/.bashrc"; then
        cat >> "/home/seb/.bashrc" << 'EOFBASHRC'

# Rappel des mises à jour disponibles
if [ -f /etc/profile.d/update-reminder.sh ]; then
    source /etc/profile.d/update-reminder.sh
fi
EOFBASHRC
        chown seb:seb "/home/seb/.bashrc"
        log_info "✓ Rappel ajouté à .bashrc"
    fi
fi

# Exécuter une première vérification immédiatement
log_info "Exécution d'une première vérification..."
bash "$UPDATE_CHECK_SCRIPT"

# Créer un service systemd timer comme alternative (plus moderne que cron)
log_info "Configuration d'un timer systemd (alternative moderne)..."

# Service
cat > /etc/systemd/system/update-checker.service << 'EOFSERVICE'
[Unit]
Description=Check for system updates
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/check-updates.sh
StandardOutput=journal
StandardError=journal
EOFSERVICE

# Timer
cat > /etc/systemd/system/update-checker.timer << 'EOFTIMER'
[Unit]
Description=Check for system updates every 4 days
Requires=update-checker.service

[Timer]
# Démarrer 5 minutes après le boot
OnBootSec=5min
# Puis tous les 4 jours
OnUnitActiveSec=4d
# Continuer même si le système était éteint
Persistent=true

[Install]
WantedBy=timers.target
EOFTIMER

# Recharger systemd et activer le timer
systemctl daemon-reload
systemctl enable update-checker.timer
systemctl start update-checker.timer

log_info "✓ Timer systemd configuré et activé"

# Afficher le statut du timer
log_info "Statut du timer:"
systemctl status update-checker.timer --no-pager || true

# Créer un alias pratique pour vérifier manuellement
log_info "Configuration d'alias pratiques..."

if [ -f "/home/seb/.zsh_aliases" ]; then
    ALIAS_FILE="/home/seb/.zsh_aliases"
else
    ALIAS_FILE="/home/seb/.zshrc"
fi

if ! grep -q "alias check-updates=" "$ALIAS_FILE" 2>/dev/null; then
    cat >> "$ALIAS_FILE" << 'EOFALIAS'

# Alias pour la gestion des mises à jour
alias check-updates='sudo /usr/local/bin/check-updates.sh && cat /var/log/update-checker.log | tail -30'
alias update-system='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
alias update-log='sudo tail -50 /var/log/update-checker.log'
EOFALIAS
    chown seb:seb "$ALIAS_FILE"
    log_info "✓ Alias ajoutés: check-updates, update-system, update-log"
fi

# Résumé
echo ""
log_info "=========================================="
log_info "Configuration terminée!"
log_info "=========================================="
echo ""
log_info "✓ Script de vérification: $UPDATE_CHECK_SCRIPT"
log_info "✓ Log des vérifications: $UPDATE_LOG"
log_info "✓ Cron job: Tous les 4 jours à 3h00"
log_info "✓ Systemd timer: Tous les 4 jours (plus persistant)"
log_info "✓ Rappel SSH: Configuré dans .zshrc et .bashrc"
echo ""
log_info "Commandes disponibles:"
log_info "  - check-updates     : Vérifier manuellement"
log_info "  - update-system     : Mettre à jour le système"
log_info "  - update-log        : Voir le log des vérifications"
echo ""
log_info "Prochaine vérification automatique:"
systemctl list-timers update-checker.timer --no-pager | grep update-checker || echo "  Dans 4 jours"
echo ""
