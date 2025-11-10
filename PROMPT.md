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
│   ├── 01-base-system.sh       # Configuration de base + utilisateur
│   ├── 02-dev-tools.sh         # Outils de développement
│   ├── 03-docker.sh            # Installation Docker
│   ├── 04-databases.sh         # MySQL/MariaDB et PostgreSQL
│   ├── 05-web-server.sh        # Nginx et configuration
│   ├── 06-media-tools.sh       # FFmpeg et outils d'encodage
│   ├── 07-gaming.sh            # SteamCMD et LGSM
│   └── 08-security.sh          # UFW et configuration sécurité
├── config/
│   └── sudoers-seb             # Configuration sudoers pour l'utilisateur
├── README.md                    # Documentation utilisateur
└── PROMPT.md                    # Ce fichier (instructions AI)
```

## Fonctionnalités Implémentées

### 1. Système de Base (`01-base-system.sh`)
- Création de l'utilisateur `seb` avec demande de mot de passe
- Configuration sudoers : commandes `apt` et `docker` sans mot de passe
- Création du dossier `~/GITRepos`
- Installation et configuration de zsh
- Installation de oh-my-zsh
- Configuration Git globale

### 2. Outils de Développement (`02-dev-tools.sh`)
- Python 3.13 (avec venv et pip)
- GitHub CLI (gh)
- Node.js (dernière version via bun)
- Golang (dernière version)
- Terraform (dernière version)

### 3. Docker (`03-docker.sh`)
- Docker CE (dernière version gratuite)
- Configuration du repository officiel Docker
- Ajout de l'utilisateur au groupe docker
- Docker Compose plugin
- Mise à jour possible via `apt upgrade`

### 4. Bases de Données (`04-databases.sh`)
- MySQL/MariaDB (dernière version stable)
- PostgreSQL (dernière version)
- Configuration de base sécurisée

### 5. Serveur Web (`05-web-server.sh`)
- Nginx (dernière version)
- Configuration pour héberger :
  - Sites WordPress
  - Applications Node.js
  - Sites statiques
- Configuration reverse proxy
- Préparation pour SSL/TLS

### 6. Outils Média (`06-media-tools.sh`)
- FFmpeg (compilation complète)
- Codecs : x264, x265, libvpx
- Support pour lecture et encodage vidéo/audio

### 7. Gaming (`07-gaming.sh`)
- SteamCMD
- LGSM (Linux Game Server Manager)
- Dépendances nécessaires

### 8. Sécurité (`08-security.sh`)
- UFW (Uncomplicated Firewall)
- Configuration des ports par défaut
- Règles de base sécurisées

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

# Vérifier la syntaxe
shellcheck *.sh modules/*.sh
```

## Ressources et Documentation

- [Ubuntu 24.04 Documentation](https://help.ubuntu.com/)
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Oh My Zsh](https://ohmyz.sh/)
- [LGSM Documentation](https://linuxgsm.com/)

## Prochaines Étapes Possibles

1. **Automatisation complète** :
   - Ajouter un mode non-interactif
   - Configuration via fichier YAML/JSON
   - Support pour Ansible

2. **Monitoring** :
   - Intégration complète Netdata
   - Alertes personnalisées
   - Dashboards

3. **Backup** :
   - Scripts de backup automatique
   - Rotation des backups
   - Backup vers cloud

4. **CI/CD** :
   - Tests automatisés des scripts
   - Validation avec GitHub Actions
   - Déploiement automatique

## Contact et Support

Si vous avez des questions ou besoin d'aide :
- Email : sebpicot@gmail.com
- GitHub : @SebPikPik

---

**Note pour AI Assistants** : Ce projet est conçu pour être modulaire et extensible. Respectez la structure existante et suivez les conventions de codage établies. Toujours tester les modifications dans un environnement isolé avant de les déployer en production.
