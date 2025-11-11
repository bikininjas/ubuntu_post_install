# PROMPT - Instructions pour AI Assistant

## Contexte du Projet

Ce projet contient des scripts de post-installation pour un serveur Ubuntu 24.04. L'objectif est d'automatiser la configuration complète d'un serveur depuis une installation fraîche.

## Utilisateur Cible

- **Nom d'utilisateur** : `seb`
- **Git** : SebPikPik / sebpicot@gmail.com
- **Système** : Ubuntu 24.04 LTS
- **Shell préféré** : zsh avec oh-my-zsh

## Architecture du Projet

Le projet est organisé en scripts modulaires pour faciliter la maintenance et permettre une installation sélective :

```
ubuntu_post_install/
├── post_install.sh              # Script principal orchestrateur
├── modules/
│   ├── 00-domain-config.sh     # Configuration du domaine et hostname
│   ├── 01-base-system.sh       # Configuration de base + utilisateur
│   ├── 02-dev-tools.sh         # Outils de développement
│   ├── 03-docker.sh            # Installation Docker
│   ├── 04-databases.sh         # MySQL/MariaDB et PostgreSQL
│   ├── 05-web-server.sh        # Nginx et configuration
│   ├── 06-media-tools.sh       # FFmpeg et outils d'encodage
│   ├── 07-gaming.sh            # SteamCMD et LGSM
│   ├── 08-security.sh          # UFW et configuration sécurité
│   ├── 09-update-checker.sh    # Système de vérification des MAJ
│   └── 10-letsencrypt.sh       # Certificats SSL Let's Encrypt
├── README.md                    # Documentation utilisateur
├── QUICKSTART.md                # Guide de démarrage rapide
├── PROMPT.md                    # Ce fichier (instructions AI)
└── .env.example                 # Fichier de configuration exemple
```

## Fonctionnalités Implémentées

### 0. Configuration du Domaine (`00-domain-config.sh`)
- Demande interactive ou automatique du nom de domaine principal
- Configuration du hostname du serveur
- Sauvegarde de la configuration dans `/etc/server-domain.conf`
- Mise à jour de `/etc/hosts`
- Validation du format de domaine et d'email
- Utilisé par les modules suivants (Nginx, Let's Encrypt, SSH)

### 1. Système de Base (`01-base-system.sh`)
- Mise à jour complète du système au démarrage
- Création de l'utilisateur `seb` avec demande de mot de passe
- Configuration sudoers : commandes `apt` et `docker` sans mot de passe
- Création du dossier `~/GITRepos`
- Installation et configuration de zsh
- Installation de oh-my-zsh
- Configuration Git globale
- Alias shell utiles (ll, gs, gp, gc)

### 2. Outils de Développement (`02-dev-tools.sh`)
- Python 3.13 (avec venv et pip) depuis PPA deadsnakes
- GitHub CLI (gh) depuis repository officiel
- Bun (gestionnaire de paquets JavaScript moderne)
- Node.js LTS (dernière version via NodeSource)
- npm (inclus avec Node.js)
- Golang (dernière version depuis go.dev)
- Terraform (depuis repository HashiCorp)
- Outils supplémentaires : jq, htop, tree, vim, nano, tmux, unzip, zip, ncdu

### 3. Docker (`03-docker.sh`)
- Docker CE (dernière version depuis repository officiel Docker)
- Configuration du repository officiel Docker
- Ajout de l'utilisateur au groupe docker
- Docker Compose plugin (v2)
- Configuration daemon.json (logs, storage driver)
- Mise à jour possible via `apt upgrade`
- Test automatique avec conteneur hello-world

### 4. Bases de Données (`04-databases.sh`)
- MariaDB (dernière version stable depuis repositories Ubuntu)
- PostgreSQL (dernière version depuis repositories Ubuntu)
- Outils clients : mycli (pour MariaDB) et pgcli (pour PostgreSQL)
- Services activés et démarrés automatiquement
- Note : mysql_secure_installation doit être exécuté manuellement

### 5. Serveur Web (`05-web-server.sh`)
- Nginx (dernière version depuis repositories Ubuntu)
- PHP-FPM avec extensions pour WordPress (php-mysql, php-curl, php-gd, etc.)
- Configuration Nginx optimisée (gzip, SSL, logs)
- Structure de dossiers : /var/www/html, /var/www/sites-available, /var/www/logs
- Templates de configuration :
  - Site par défaut avec le domaine configuré
  - Template WordPress complet
  - Template Node.js (reverse proxy)
- Page d'accueil par défaut
- Configuration automatique avec le domaine du module 00

### 6. Outils Média (`06-media-tools.sh`)
- FFmpeg (installation depuis repositories Ubuntu avec tous les codecs)
- Support des codecs : x264, x265, libvpx, AAC, Opus
- Dépendances de compilation : autoconf, cmake, nasm, yasm
- Outils supplémentaires :
  - mediainfo (informations sur fichiers média)
  - imagemagick (traitement d'images)
  - sox (traitement audio)
  - lame, flac, vorbis-tools (encodage audio)

### 7. Gaming (`07-gaming.sh`)
- Activation de l'architecture i386 (32-bit)
- SteamCMD (depuis repositories Ubuntu)
- Dépendances 32-bit nécessaires
- LGSM (Linux Game Server Manager) - script téléchargé
- Dossier `/home/seb/gameservers` créé
- Fichier README.txt avec guide d'utilisation
- Pré-acceptation de la licence Steam pour installation non-interactive
- Support pour : CS:GO, TF2, Garry's Mod, Minecraft, Rust, ARK, etc.

### 8. Sécurité (`08-security.sh`)
- UFW (Uncomplicated Firewall) configuré de manière stricte
- Configuration par défaut : TOUT BLOQUÉ sauf règles explicites
- Règles sortantes : DNS (53), HTTP/HTTPS (80/443), NTP (123)
- SSH (port 22) : **LIMITÉ à l'IP 82.65.136.32 UNIQUEMENT**
- Ports web : HTTP (80) et HTTPS (443) ouverts à tous
- Ports Steam : 27015 (TCP/UDP), 27005 (UDP), 27020 (UDP) ouverts
- Ports développement (3000-9000) : accessibles UNIQUEMENT depuis IP autorisée
- Netdata (monitoring temps réel) installé et configuré
- Configuration Nginx pour Netdata (optionnelle)
- Fail2ban installé et activé
- Unattended-upgrades configuré pour les mises à jour de sécurité
- Affichage détaillé des règles de sécurité après installation

### 9. Vérificateur de Mises à Jour (`09-update-checker.sh`)
- Script de vérification automatique des mises à jour
- Vérification tous les 4 jours (cron + systemd timer)
- Détection des mises à jour de sécurité
- Création d'un flag `/var/run/updates-available` avec informations
- Rappel coloré à chaque connexion SSH si mises à jour disponibles
- Log persistant : `/var/log/update-checker.log`
- Alias créés :
  - `check-updates` : vérification manuelle
  - `update-system` : mise à jour complète
  - `update-log` : affichage des logs
- Intégration dans .zshrc et .bashrc

### 10. Let's Encrypt (`10-letsencrypt.sh`)
- Certbot + plugin Nginx
- Génération automatique des certificats SSL
- Certificats pour le domaine principal et www
- Redirection HTTP vers HTTPS automatique
- Renouvellement automatique (systemd timer certbot.timer)
- Vérification DNS avant génération
- Script de génération ultérieure si DNS non configuré : `/usr/local/bin/generate-ssl`
- Script de test de renouvellement : `/usr/local/bin/test-ssl-renewal`
- Alias créés :
  - `ssl-status` : afficher les certificats
  - `ssl-renew` : renouveler manuellement
  - `ssl-test` : tester le renouvellement
  - `ssl-generate` : générer les certificats

## Comment Continuer ce Projet

### Si vous devez modifier ou étendre les scripts :

1. **Ajouter un nouveau module** :
   - Créez un fichier `modules/0X-nom-module.sh`
   - Suivez le template des modules existants
   - Ajoutez-le à la liste dans `post_install.sh`

2. **Modifier une installation** :
   - Localisez le module concerné
   - Les scripts utilisent des fonctions pour la gestion d'erreurs
   - Testez toujours dans un environnement de développement

3. **Déboguer** :
   - Chaque module peut être exécuté indépendamment
   - Les logs sont verbeux pour faciliter le débogage
   - Utilisez `bash -x module.sh` pour le mode debug

### Structure d'un Module Type

```bash
#!/bin/bash

# Description du module
# Auteur: Assistant AI
# Date: 2025-11-10

set -e  # Arrêt en cas d'erreur

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Vérification des privilèges
if [ "$EUID" -ne 0 ]; then 
    log_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

# Code du module...
```

## Points d'Attention

### Sécurité
- Les mots de passe ne sont JAMAIS stockés en clair
- Les fichiers de configuration sensibles sont en 600
- Toujours valider les entrées utilisateur

### Compatibilité
- Scripts testés sur Ubuntu 24.04 LTS
- Vérifier les versions des dépendances
- Utiliser les repositories officiels quand possible

### Performance
- Installation parallèle quand possible
- Nettoyage des caches apt
- Optimisation des compilations

## Dépendances Critiques

- `curl` et `wget` pour les téléchargements
- `git` pour les clones de repository
- `build-essential` pour les compilations
- `software-properties-common` pour les PPA

## Ordre d'Exécution et Dépendances

L'ordre d'exécution des modules est critique :

1. **00-domain-config** : Doit s'exécuter en premier (requis par 05 et 10)
2. **01-base-system** : Crée l'utilisateur (requis par 03, 07, 09)
3. **02-dev-tools** : Indépendant
4. **03-docker** : Dépend de 01 (utilisateur)
5. **04-databases** : Indépendant
6. **08-security** : **AVANT 05** pour configurer UFW avant d'exposer Nginx
7. **05-web-server** : Dépend de 00 (domaine) et 08 (sécurité)
8. **06-media-tools** : Indépendant
9. **07-gaming** : Dépend de 01 (utilisateur)
10. **09-update-checker** : Dépend de 01 (utilisateur)
11. **10-letsencrypt** : Dépend de 00 (domaine) et 05 (Nginx)

## Variables d'Environnement Importantes

```bash
TARGET_USER="seb"           # Utilisateur cible
GIT_USER="SebPikPik"       # Nom Git
GIT_EMAIL="sebpicot@gmail.com"  # Email Git
GITREPOS_DIR="/home/seb/GITRepos"  # Dossier des repos
```

## Commandes Utiles pour Maintenance

```bash
# Exécuter le script complet
sudo ./post_install.sh

# Exécuter un module spécifique
sudo ./modules/02-dev-tools.sh

# Mode debug
sudo bash -x ./post_install.sh

# Vérifier la syntaxe avec ShellCheck (avant commit)
./check-shellcheck.sh

# Vérifier la syntaxe Bash
bash -n post_install.sh
```

## Tests et Validation

### ShellCheck Local

Avant de commit, toujours exécuter :
```bash
./check-shellcheck.sh
```

Le projet utilise `.shellcheckrc` pour désactiver certains avertissements non pertinents.

### CI/CD GitHub Actions

Deux workflows valident automatiquement :
- `.github/workflows/shellcheck.yml` : Vérification ShellCheck
- `.github/workflows/ci.yml` : Validation complète (syntaxe, permissions, structure)

## Ressources et Documentation

- [Ubuntu 24.04 Documentation](https://help.ubuntu.com/)
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Oh My Zsh](https://ohmyz.sh/)
- [LGSM Documentation](https://linuxgsm.com/)

## Prochaines Étapes Possibles

1. **Module Grafana Agent (branche grafanaAgent)** :
   - Module `11-grafana-agent.sh` en développement
   - Installation de Grafana Agent
   - Connexion automatique à Grafana Cloud
   - Monitoring complet du serveur

2. **Améliorations futures** :
   - Scripts de backup automatique
   - Rotation des backups
   - Backup vers cloud (S3, etc.)

## Contact et Support

Si vous avez des questions ou besoin d'aide :
- Email : sebpicot@gmail.com
- GitHub : @SebPikPik

---

**Note pour AI Assistants** : Ce projet est conçu pour être modulaire et extensible. Respectez la structure existante et suivez les conventions de codage établies. Toujours tester les modifications dans un environnement isolé avant de les déployer en production.
