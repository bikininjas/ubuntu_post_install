# 🚀 Ubuntu 24.04 Post-Installation Script

Scripts automatisés modulaires pour configurer un serveur Ubuntu 24.04 LTS fraîchement installé avec tous les outils nécessaires pour le développement, l'hébergement web, le traitement média et le gaming.

## 📋 Table des Matières

- [Fonctionnalités](#-fonctionnalités)
- [Prérequis](#-prérequis)
- [Installation Rapide](#-installation-rapide)
- [Installation Modulaire](#-installation-modulaire)
- [Modules Disponibles](#-modules-disponibles)
- [Configuration](#-configuration)
- [Utilisation](#-utilisation)
- [Système de Mise à Jour Automatique](#-système-de-mise-à-jour-automatique)
- [Sécurité](#-sécurité)
- [Dépannage](#-dépannage)
- [Contribution](#-contribution)

## 🎯 Fonctionnalités

### Système de Base
- ✅ Création de l'utilisateur `seb` avec privilèges sudo configurés
- ✅ Shell zsh avec oh-my-zsh (thème powerlevel10k)
- ✅ Structure de dossiers personnalisée (GITRepos)
- ✅ Configuration Git globale
- ✅ Mise à jour automatique des packages au démarrage
- ✅ **Vérification automatique des mises à jour tous les 4 jours**
- ✅ **Rappel coloré à chaque connexion SSH si mises à jour disponibles**

### Outils de Développement
- ✅ Python 3.13 (avec venv et pip)
- ✅ GitHub CLI (dernière version)
- ✅ Node.js (dernière version via bun)
- ✅ Golang (dernière version)
- ✅ Terraform (dernière version)

### Infrastructure
- ✅ Docker CE (dernière version gratuite, mise à jour via apt)
- ✅ Docker Compose Plugin
- ✅ **Bases de données via Docker** (MySQL/PostgreSQL) - exemples fournis
- ✅ Nginx (avec configuration pour WordPress et Node.js)
- ✅ **Netdata avec HTTPS** (via reverse proxy Nginx)

### Média
- ✅ FFmpeg (avec x264, x265, libvpx)
- ✅ Outils d'encodage audio/vidéo complets

### Gaming
- ✅ SteamCMD
- ✅ LGSM (Linux Game Server Manager)

### Monitoring & Sécurité
- ✅ Netdata (monitoring temps réel avec HTTPS)
- ✅ UFW (Firewall configuré avec règles strictes)
- ✅ **GeoIP2** (géolocalisation des attaques avec Fail2ban)
- ✅ **Grafana Alloy** (métriques et logs vers Grafana Cloud)
- ✅ Système de mise à jour automatique avec notifications

## 🔧 Prérequis

- Ubuntu 24.04 LTS fraîchement installé
- Accès root ou sudo
- Connexion Internet stable
- Au moins 10 GB d'espace disque libre
- 2 GB de RAM minimum (4 GB recommandé)

## ⚡ Installation Rapide

```bash
# 1. Cloner le repository
git clone https://github.com/bikininjas/ubuntu_post_install.git
cd ubuntu_post_install

# 2. Rendre les scripts exécutables
chmod +x post_install.sh
chmod +x modules/*.sh

# 3. Exécuter l'installation complète (en tant que root)
sudo ./post_install.sh
```

Le script vous proposera deux options :
1. **Installation complète** : Tous les modules seront installés
2. **Installation personnalisée** : Vous choisissez les modules à installer

Le script vous demandera de définir un mot de passe pour l'utilisateur `seb`.

## 🎛️ Installation Modulaire

Vous pouvez exécuter les modules individuellement selon vos besoins :

```bash
# Installer uniquement les outils de développement
sudo ./modules/02-dev-tools.sh

# Installer uniquement Docker
sudo ./modules/03-docker.sh

# Installer uniquement le serveur web
sudo ./modules/05-web-server.sh

# Installer le système de mise à jour automatique
sudo ./modules/09-update-checker.sh
```

## 📦 Modules Disponibles

| Module | Description | Fichier |
|--------|-------------|---------|
| **Domain Config** | Configuration du domaine et hostname du serveur | `00-domain-config.sh` |
| **Base System** | Configuration utilisateur, zsh, oh-my-zsh, sudoers | `01-base-system.sh` |
| **Dev Tools** | Python 3.13, Node.js, Go, Terraform, GitHub CLI | `02-dev-tools.sh` |
| **Docker** | Docker CE + Docker Compose Plugin | `03-docker.sh` |
| **Databases** | Exemples Docker pour MySQL/PostgreSQL (pas d'installation) | `04-databases.sh` |
| **Security** | UFW, Netdata (HTTPS), GeoIP2, Fail2ban | `08-security.sh` |
| **Web Server** | Nginx + PHP + configuration sites | `05-web-server.sh` |
| **Media Tools** | FFmpeg, codecs vidéo/audio | `06-media-tools.sh` |
| **Gaming** | SteamCMD, LGSM | `07-gaming.sh` |
| **Update Checker** | Système de vérification automatique des MAJ | `09-update-checker.sh` |
| **Let's Encrypt** | Certificats SSL automatiques + activation Netdata HTTPS | `10-letsencrypt.sh` |
| **Grafana Alloy** | Monitoring système via Grafana Cloud (métriques + logs) | `11-grafana-alloy.sh` |

### Ordre d'exécution recommandé

Les modules s'exécutent dans cet ordre pour respecter les dépendances :

1. **00-domain-config** → Configure le domaine (requis par Nginx et Let's Encrypt)
2. **01-base-system** → Crée l'utilisateur, configure zsh et sudoers (ordre CRITIQUE)
3. **02-dev-tools** → Installe les outils de développement
4. **03-docker** → Installe Docker (dépend de l'utilisateur créé en 01)
5. **04-databases** → Fournit exemples Docker pour bases de données (informatif)
6. **08-security** → Configure UFW, Netdata, GeoIP2 **AVANT** d'exposer des services
7. **05-web-server** → Installe Nginx (après UFW pour sécurité)
8. **06-media-tools** → Installe FFmpeg
9. **07-gaming** → Installe SteamCMD et LGSM
10. **09-update-checker** → Configure les vérifications automatiques
11. **10-letsencrypt** → Génère les certificats SSL et active Netdata HTTPS
12. **11-grafana-alloy** → Configure le monitoring avec permissions automatiques

## ⚙️ Configuration

### Variables Principales

Les variables sont définies au début de chaque script. Les principales sont :

```bash
TARGET_USER="seb"
GIT_USER="SebPikPik"
GIT_EMAIL="sebpicot@gmail.com"
GITREPOS_DIR="/home/seb/GITRepos"
```

### Permissions Sudo

L'utilisateur `seb` peut exécuter **sans mot de passe** :
- Toutes les commandes `apt` (install, update, upgrade, etc.)
- Toutes les commandes `docker`

**IMPORTANT** : L'ordre des règles dans sudoers est critique. La règle `ALL=(ALL) ALL` doit venir AVANT les règles `NOPASSWD` pour que les permissions sans mot de passe fonctionnent correctement.

Pour les autres commandes sudo, le mot de passe sera demandé.

### Ports Ouverts (UFW)

Par défaut, les ports suivants seront ouverts :
- `22` - SSH (limité à IP spécifique si configuré)
- `80` - HTTP
- `443` - HTTPS
- `19999` - Netdata (limité à IP spécifique)
- `3000-9000` - Développement (limités à IP spécifique)

**Note** : Les ports des bases de données (3306, 5432) ne sont PAS ouverts car les bases de données utilisent Docker avec réseau interne.

## 💻 Utilisation

### Après Installation

1. **Se connecter avec le nouvel utilisateur** :
   ```bash
   su - seb
   # ou redémarrer et se connecter en tant que seb
   ```

2. **Vérifier l'installation** :
   ```bash
   # Vérifier zsh
   echo $SHELL
   
   # Vérifier Docker
   docker --version
   docker compose version
   
   # Vérifier Python
   python3.13 --version
   
   # Vérifier Node.js
   node --version
   bun --version
   
   # Vérifier Go
   go version
   
   # Vérifier Terraform
   terraform --version
   ```

3. **Utiliser Docker sans sudo** :
   ```bash
   docker ps
   docker run hello-world
   ```

### Exemples d'Utilisation

#### Héberger un Site WordPress

```bash
# Exemple avec Docker Compose (bases de données déjà configurées via Docker)
cd ~/GITRepos
mkdir mon-wordpress
cd mon-wordpress

# Créer un docker-compose.yml avec MySQL et WordPress
# Voir exemples dans modules/04-databases.sh
# Nginx est déjà installé pour le reverse proxy
```

#### Déployer des Bases de Données

```bash
# MySQL avec Docker (exemple fourni dans module 04)
docker run -d \
  --name mysql \
  -e MYSQL_ROOT_PASSWORD=votre_password \
  -p 3306:3306 \
  -v /opt/docker/data/mysql:/var/lib/mysql \
  mysql:8.0

# PostgreSQL avec Docker
docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=votre_password \
  -p 5432:5432 \
  -v /opt/docker/data/postgres:/var/lib/postgresql/data \
  postgres:16
```

#### Créer un Serveur de Jeu

```bash
# LGSM est déjà installé
# Exemple pour un serveur CS:GO
su - seb
./linuxgsm.sh csgoserver
```

## 🔄 Système de Mise à Jour Automatique

Le module `09-update-checker.sh` configure un système complet de gestion des mises à jour.

### Fonctionnalités

- ✅ Mise à jour initiale au démarrage du script
- ✅ Vérification automatique tous les 4 jours (cron + systemd timer)
- ✅ Rappel coloré à chaque connexion SSH si des mises à jour sont disponibles
- ✅ Alerte spéciale pour les mises à jour de sécurité
- ✅ Logs persistants de toutes les vérifications

### Commandes rapides

```bash
# Vérifier manuellement les mises à jour
check-updates

# Mettre à jour le système
update-system

# Voir le log des vérifications
update-log
```

### Exemple de rappel

```
╔════════════════════════════════════════════════════════════╗
║  ⚠️  MISES À JOUR DISPONIBLES                              ║
║  🔒 5 mises à jour de SÉCURITÉ                             ║
║  📦 23 packages peuvent être mis à jour                    ║
║  Pour mettre à jour, exécutez:                            ║
║  sudo apt update && sudo apt upgrade -y                    ║
╚════════════════════════════════════════════════════════════╝
```

## 🔒 Sécurité

### Bonnes Pratiques Implémentées

- ✅ Utilisateur non-root pour les opérations quotidiennes
- ✅ Sudo limité aux commandes nécessaires (apt, docker) avec ordre correct
- ✅ Firewall UFW activé et configuré de manière stricte
- ✅ Services exposés uniquement sur les ports nécessaires
- ✅ Pas de mots de passe en clair dans les scripts
- ✅ Vérification automatique des mises à jour de sécurité
- ✅ Netdata accessible uniquement via HTTPS avec Let's Encrypt
- ✅ GeoIP2 pour analyse géographique des attaques
- ✅ Bases de données isolées dans Docker (pas de ports exposés)
- ✅ Grafana Alloy avec permissions automatiquement configurées

### Recommandations Supplémentaires

1. **Configurer l'authentification SSH par clé** :
   ```bash
   ssh-keygen -t ed25519 -C "sebpicot@gmail.com"
   # Copier la clé publique vers le serveur
   ```

2. **Désactiver l'authentification par mot de passe SSH** :
   ```bash
   sudo nano /etc/ssh/sshd_config
   # PasswordAuthentication no
   sudo systemctl restart sshd
   ```

3. **Configurer Fail2ban** (non inclus par défaut) :
   ```bash
   sudo apt install fail2ban
   sudo systemctl enable fail2ban
   ```

4. **Mises à jour régulières** :
   ```bash
   # Maintenant automatisé avec le module 09!
   # Ou manuellement :
   update-system
   ```

## 🐛 Dépannage

### Erreur : "Permission denied"

```bash
# Vérifier que les scripts sont exécutables
chmod +x post_install.sh modules/*.sh

# Exécuter avec sudo
sudo ./post_install.sh
```

### Docker ne fonctionne pas après installation

```bash
# Se déconnecter et se reconnecter pour que les groupes soient appliqués
exit
su - seb

# Ou redémarrer la session
```

### Zsh ne se lance pas automatiquement

```bash
# Vérifier le shell par défaut
echo $SHELL

# Si ce n'est pas zsh, le définir manuellement
chsh -s $(which zsh)
```

### Python 3.13 non trouvé

```bash
# Vérifier si le PPA a été ajouté
apt-cache policy python3.13

# Réinstaller si nécessaire
sudo ./modules/02-dev-tools.sh
```

### Le rappel de mise à jour ne s'affiche pas

```bash
# Vérifier si le module a été exécuté
ls -l /etc/profile.d/update-reminder.sh

# Tester manuellement
bash /etc/profile.d/update-reminder.sh

# Voir les logs
update-log
```

### Problèmes de compilation FFmpeg

FFmpeg nécessite beaucoup de ressources. Si la compilation échoue :
- Vérifiez l'espace disque : `df -h`
- Vérifiez la RAM : `free -h`
- Utilisez la version des repositories : `sudo apt install ffmpeg`

## 📝 Logs

Les logs d'installation sont visibles directement dans le terminal. Pour plus de détails en mode debug :

```bash
sudo bash -x ./post_install.sh 2>&1 | tee install.log
```

## 📚 Documentation Supplémentaire

- [PROMPT.md](PROMPT.md) - Instructions pour une autre IA qui prendrait le relais
- [QUICKSTART.md](QUICKSTART.md) - Guide de démarrage rapide
- [.shellcheck-local.md](.shellcheck-local.md) - Guide pour la vérification ShellCheck locale

## 🧪 Tests et Validation

### Vérification locale avec ShellCheck

Avant de push, vérifiez que tous les scripts passent ShellCheck :

```bash
# Vérifier tous les scripts
./check-shellcheck.sh

# Ou manuellement
shellcheck post_install.sh modules/*.sh
```

### CI/CD Automatique

Les GitHub Actions vérifient automatiquement :
- Syntaxe Bash de tous les scripts
- Validation ShellCheck
- Permissions des fichiers
- Structure du projet

## 🤝 Contribution

Les contributions sont les bienvenues ! 

1. Fork le projet
2. Créer une branche (`git checkout -b feature/amelioration`)
3. Commit les changements (`git commit -am 'Ajout fonctionnalité'`)
4. Push vers la branche (`git push origin feature/amelioration`)
5. Créer une Pull Request

## 📄 Licence

Ce projet est libre d'utilisation pour usage personnel et commercial.

## 👤 Auteur

**Seb**
- GitHub: [@bikininjas](https://github.com/bikininjas)
- Email: sebpicot@gmail.com

## 🙏 Remerciements

- Oh My Zsh community
- Docker team
- LGSM developers
- FFmpeg contributors
- Ubuntu community

---

**Note** : Testez toujours ces scripts dans un environnement de développement avant de les utiliser en production !

**Version** : 1.0.0  
**Dernière mise à jour** : 2025-11-10
