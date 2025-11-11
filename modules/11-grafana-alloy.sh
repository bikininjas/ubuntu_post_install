#!/bin/bash

################################################################################
# Module 11 - Grafana Alloy (Monitoring)
# Description: Installation de Grafana Alloy et connexion à Grafana Cloud
# Auteur: Seb
# Note: Grafana Alloy remplace Grafana Agent (EOL nov 2025)
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
log_section() { echo -e "\n${CYAN}=== $1 ===${NC}\n"; }

# Variables d'environnement (chargées depuis .env ou saisie interactive)
GCLOUD_HOSTED_METRICS_ID="${GCLOUD_HOSTED_METRICS_ID:-}"
GCLOUD_HOSTED_METRICS_URL="${GCLOUD_HOSTED_METRICS_URL:-}"
GCLOUD_HOSTED_LOGS_ID="${GCLOUD_HOSTED_LOGS_ID:-}"
GCLOUD_HOSTED_LOGS_URL="${GCLOUD_HOSTED_LOGS_URL:-}"
GCLOUD_RW_API_KEY="${GCLOUD_RW_API_KEY:-}"

# Vérification root
if [[ "${EUID}" -ne 0 ]]; then 
    log_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

log_section "Installation de Grafana Alloy"

# Fonction pour demander les credentials de manière interactive
ask_credentials() {
    log_warning "Configuration de Grafana Cloud requise"
    echo ""
    log_info "Pour obtenir vos credentials Grafana Cloud :"
    echo "  1. Connectez-vous à https://grafana.com/"
    echo "  2. Allez dans 'Connections' > 'Add new connection' > 'Linux Server'"
    echo "  3. Dans la section 'Install and run Grafana Alloy', copiez les valeurs suivantes:"
    echo ""
    
    if [[ -z "${GCLOUD_HOSTED_METRICS_ID}" ]]; then
        read -p "GCLOUD_HOSTED_METRICS_ID (ex: 246504): " GCLOUD_HOSTED_METRICS_ID
    fi
    
    if [[ -z "${GCLOUD_HOSTED_METRICS_URL}" ]]; then
        read -p "GCLOUD_HOSTED_METRICS_URL: " GCLOUD_HOSTED_METRICS_URL
    fi
    
    if [[ -z "${GCLOUD_HOSTED_LOGS_ID}" ]]; then
        read -p "GCLOUD_HOSTED_LOGS_ID (ex: 122223): " GCLOUD_HOSTED_LOGS_ID
    fi
    
    if [[ -z "${GCLOUD_HOSTED_LOGS_URL}" ]]; then
        read -p "GCLOUD_HOSTED_LOGS_URL: " GCLOUD_HOSTED_LOGS_URL
    fi
    
    if [[ -z "${GCLOUD_RW_API_KEY}" ]]; then
        read -s -p "GCLOUD_RW_API_KEY (token commençant par glc_): " GCLOUD_RW_API_KEY
        echo ""
    fi
}

# Vérifier si les credentials sont configurés
if [[ -z "${GCLOUD_HOSTED_METRICS_URL}" ]] || [[ -z "${GCLOUD_HOSTED_LOGS_URL}" ]]; then
    ask_credentials
fi

# Validation des credentials
if [[ -z "${GCLOUD_HOSTED_METRICS_ID}" ]] || [[ -z "${GCLOUD_HOSTED_METRICS_URL}" ]] || \
   [[ -z "${GCLOUD_HOSTED_LOGS_ID}" ]] || [[ -z "${GCLOUD_HOSTED_LOGS_URL}" ]] || \
   [[ -z "${GCLOUD_RW_API_KEY}" ]]; then
    log_error "Credentials Grafana Cloud incomplets"
    log_error "Veuillez configurer toutes les variables GCLOUD_* dans le fichier .env"
    exit 1
fi

log_info "✓ Credentials Grafana Cloud configurés"

# 1. Installation de Grafana Alloy
log_info "Ajout du repository Grafana..."

# Créer le répertoire pour les clés GPG
mkdir -p /etc/apt/keyrings/

# Télécharger et ajouter la clé GPG
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null

# Ajouter le repository
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | \
    tee /etc/apt/sources.list.d/grafana.list > /dev/null

# Mettre à jour les repositories
log_info "Mise à jour des repositories..."
apt update

# Installer Grafana Alloy
log_info "Installation de Grafana Alloy..."
DEBIAN_FRONTEND=noninteractive apt install -y alloy

log_info "✓ Grafana Alloy installé"
alloy --version

# 2. Configuration de Grafana Alloy
log_info "Configuration de Grafana Alloy pour Grafana Cloud..."

# Obtenir le hostname
HOSTNAME=$(hostname)

# Créer le fichier de configuration
CONFIG_FILE="/etc/alloy/config.alloy"

log_info "Création de la configuration dans ${CONFIG_FILE}..."

cat > "${CONFIG_FILE}" << EOF
// ============================================================================
// Grafana Alloy Configuration
// Generated automatically by ubuntu_post_install
// Server: ${HOSTNAME}
// ============================================================================

// Prometheus Remote Write - Métriques vers Grafana Cloud
prometheus.remote_write "metrics_service" {
  endpoint {
    url = "${GCLOUD_HOSTED_METRICS_URL}"
    
    basic_auth {
      username = "${GCLOUD_HOSTED_METRICS_ID}"
      password = "${GCLOUD_RW_API_KEY}"
    }
  }
}

// Loki Remote Write - Logs vers Grafana Cloud
loki.write "grafana_cloud_loki" {
  endpoint {
    url = "${GCLOUD_HOSTED_LOGS_URL}"
    
    basic_auth {
      username = "${GCLOUD_HOSTED_LOGS_ID}"
      password = "${GCLOUD_RW_API_KEY}"
    }
  }
}

// ============================================================================
// MÉTRIQUES SYSTÈME (Node Exporter)
// ============================================================================

// Configuration du Node Exporter (métriques système)
prometheus.exporter.unix "integrations_node_exporter" {
  // Désactiver les collecteurs non nécessaires
  disable_collectors = ["ipvs", "btrfs", "infiniband", "xfs", "zfs"]
  
  // Configuration filesystem
  filesystem {
    fs_types_exclude     = "^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|tmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$"
    mount_points_exclude = "^/(dev|proc|run/credentials/.+|sys|var/lib/docker/.+)($|/)"
    mount_timeout        = "5s"
  }
  
  // Configuration réseau
  netclass {
    ignored_devices = "^(veth.*|cali.*|[a-f0-9]{15})$"
  }
  
  netdev {
    device_exclude = "^(veth.*|cali.*|[a-f0-9]{15})$"
  }
}

// Relabeling pour Node Exporter
discovery.relabel "integrations_node_exporter" {
  targets = prometheus.exporter.unix.integrations_node_exporter.targets
  
  rule {
    target_label = "instance"
    replacement  = "${HOSTNAME}"
  }
  
  rule {
    target_label = "job"
    replacement = "integrations/node_exporter"
  }
}

// Scraping des métriques Node Exporter
prometheus.scrape "integrations_node_exporter" {
  targets    = discovery.relabel.integrations_node_exporter.output
  forward_to = [prometheus.relabel.integrations_node_exporter.receiver]
}

// Relabeling final avant envoi
prometheus.relabel "integrations_node_exporter" {
  forward_to = [prometheus.remote_write.metrics_service.receiver]
  
  // Supprimer les métriques de scraping non nécessaires
  rule {
    source_labels = ["__name__"]
    regex         = "node_scrape_collector_.+"
    action        = "drop"
  }
}

// ============================================================================
// LOGS SYSTÈME (Systemd Journal + Files)
// ============================================================================

// Relabeling pour les logs
loki.relabel "integrations_node_exporter" {
  forward_to = [loki.write.grafana_cloud_loki.receiver]
  
  rule {
    target_label = "job"
    replacement  = "integrations/node_exporter"
  }
  
  rule {
    target_label = "instance"
    replacement  = "${HOSTNAME}"
  }
}

// Collecte des logs systemd journal
loki.source.journal "default" {
  max_age       = "12h0m0s"
  forward_to    = [loki.process.default.receiver]
  relabel_rules = loki.relabel.journal_relabel.rules
}

// Relabeling pour systemd journal
loki.relabel "journal_relabel" {
  rule {
    source_labels = ["__journal__systemd_unit"]
    target_label  = "unit"
  }
  
  rule {
    source_labels = ["__journal__boot_id"]
    target_label  = "boot_id"
  }
  
  rule {
    source_labels = ["__journal__transport"]
    target_label  = "transport"
  }
  
  rule {
    source_labels = ["__journal_priority_keyword"]
    target_label  = "level"
  }
  
  forward_to = []
}

// Processing des logs avant envoi
loki.process "default" {
  forward_to = [loki.relabel.integrations_node_exporter.receiver]
}

// Collecte des fichiers de logs (/var/log)
local.file_match "default" {
  path_targets = [{
    __address__ = "localhost",
    __path__    = "/var/log/{syslog,messages,*.log}",
  }]
}

loki.source.file "default" {
  targets    = local.file_match.default.targets
  forward_to = [loki.relabel.integrations_node_exporter.receiver]
}

// ============================================================================
// FIN DE LA CONFIGURATION
// ============================================================================
EOF

chmod 640 "${CONFIG_FILE}"
chown alloy:alloy "${CONFIG_FILE}"

log_info "✓ Configuration créée : ${CONFIG_FILE}"

# 3. Valider la configuration
log_info "Validation de la configuration..."
if alloy fmt "${CONFIG_FILE}" > /dev/null 2>&1; then
    log_info "✓ Configuration valide"
else
    log_warning "La validation de la configuration a échoué, mais nous continuons..."
fi

# 4. Activer et démarrer le service
log_info "Activation du service Grafana Alloy..."
systemctl daemon-reload
systemctl enable alloy
systemctl restart alloy

# Attendre que le service démarre
sleep 3

# Vérifier le statut
if systemctl is-active --quiet alloy; then
    log_info "✓ Grafana Alloy démarré avec succès"
else
    log_error "Échec du démarrage de Grafana Alloy"
    log_error "Vérifiez les logs : journalctl -u alloy -n 50"
    exit 1
fi

# 5. Créer un script de vérification
log_info "Création d'un script de vérification..."

cat > /usr/local/bin/check-grafana-alloy << 'EOFCHECK'
#!/bin/bash

# Script de vérification Grafana Alloy

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Grafana Alloy - Vérification${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Vérifier le statut du service
echo -e "${YELLOW}Service Status:${NC}"
systemctl status alloy --no-pager | head -10
echo ""

# Vérifier les derniers logs
echo -e "${YELLOW}Derniers logs (20 dernières lignes):${NC}"
journalctl -u alloy -n 20 --no-pager
echo ""

# Vérifier la connectivité vers Grafana Cloud
echo -e "${YELLOW}Métriques envoyées:${NC}"
journalctl -u alloy --since "10 minutes ago" | grep -i "remote_write" | tail -5 || echo "Aucune métrique récente trouvée"
echo ""

echo -e "${YELLOW}Logs envoyés:${NC}"
journalctl -u alloy --since "10 minutes ago" | grep -i "loki" | tail -5 || echo "Aucun log récent trouvé"
echo ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
EOFCHECK

chmod +x /usr/local/bin/check-grafana-alloy

log_info "✓ Script de vérification créé : /usr/local/bin/check-grafana-alloy"

# 6. Créer des alias
log_info "Création des alias..."

ALIAS_FILE="/etc/profile.d/grafana-alloy-aliases.sh"
cat > "${ALIAS_FILE}" << 'EOFALIAS'
# Alias pour Grafana Alloy

alias alloy-status='sudo systemctl status alloy'
alias alloy-restart='sudo systemctl restart alloy'
alias alloy-logs='sudo journalctl -u alloy -f'
alias alloy-check='sudo /usr/local/bin/check-grafana-alloy'
alias alloy-config='sudo nano /etc/alloy/config.alloy'
EOFALIAS

chmod +x "${ALIAS_FILE}"
log_info "✓ Alias créés"

log_section "Installation Terminée !"

echo ""
echo -e "${GREEN}✓ Grafana Alloy installé et configuré${NC}"
echo -e "${GREEN}✓ Service démarré et actif${NC}"
echo -e "${GREEN}✓ Connexion à Grafana Cloud établie${NC}"
echo ""
echo -e "${CYAN}Informations importantes:${NC}"
echo -e "  Serveur: ${HOSTNAME}"
echo -e "  Config: ${CONFIG_FILE}"
echo ""
echo -e "${YELLOW}Commandes utiles:${NC}"
echo "  alloy-status      # Voir le statut du service"
echo "  alloy-logs        # Voir les logs en temps réel"
echo "  alloy-check       # Vérifier la santé d'Alloy"
echo "  alloy-restart     # Redémarrer le service"
echo "  alloy-config      # Éditer la configuration"
echo ""
echo -e "${YELLOW}Vérification dans Grafana Cloud:${NC}"
echo "  1. Connectez-vous à https://grafana.com/"
echo "  2. Allez dans 'Explore' > 'Prometheus'"
echo "  3. Recherchez les métriques avec instance=\"${HOSTNAME}\""
echo "  4. Allez dans 'Explore' > 'Loki'"
echo "  5. Recherchez les logs avec instance=\"${HOSTNAME}\""
echo ""
echo -e "${GREEN}Dashboards disponibles dans Grafana Cloud:${NC}"
echo "  - Linux node / Overview"
echo "  - Linux node / CPU and system"
echo "  - Linux node / Memory"
echo "  - Linux node / Network"
echo "  - Linux node / Filesystem and disks"
echo "  - Linux node / Logs"
echo ""

log_info "✓ Module 11-grafana-alloy terminé avec succès"

exit 0
