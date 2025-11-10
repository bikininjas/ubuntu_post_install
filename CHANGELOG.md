# Changelog - Ubuntu Post-Installation Script

## Version 1.1.0 - 2025-11-10

### ✅ Nouvelles fonctionnalités

#### Module 09 - Système de mise à jour automatique
- **Vérification automatique** : Les mises à jour sont vérifiées tous les 4 jours
- **Double système** : Cron job + Systemd timer pour plus de fiabilité
- **Rappel SSH** : Message coloré à chaque connexion si des mises à jour sont disponibles
- **Alertes de sécurité** : Détection spécifique des mises à jour de sécurité
- **Logs persistants** : Historique complet dans `/var/log/update-checker.log`
- **Alias pratiques** : `check-updates`, `update-system`, `update-log`

#### Mise à jour automatique au démarrage
- **Module 01** : Exécute `apt update && apt upgrade` avant toute installation
- **Script principal** : Mise à jour du système si le module 01 n'est pas sélectionné

### 🔧 Améliorations

#### Suppression des validations manuelles
- ✅ Plus besoin de confirmer après la sélection des modules
- ✅ Countdown de 3 secondes avant le démarrage de l'installation
- ✅ Continuation automatique en cas d'erreur d'un module
- ✅ La seule interaction manuelle reste le mot de passe de l'utilisateur "seb"

#### Mode non-interactif complet
- ✅ `DEBIAN_FRONTEND=noninteractive` ajouté à toutes les commandes `apt install`
- ✅ Aucune question posée par APT pendant l'installation
- ✅ Installation entièrement automatisée (sauf mot de passe utilisateur)

### 📝 Modifications des fichiers

#### Scripts modifiés
- `post_install.sh`
  - Suppression de la confirmation après sélection des modules
  - Ajout d'un countdown de 3 secondes
  - Suppression de la confirmation en cas d'erreur
  - Ajout de `DEBIAN_FRONTEND=noninteractive`
  - Module 09 ajouté à la liste des modules

- `modules/01-base-system.sh`
  - Ajout de `apt update && apt upgrade` au début
  - Mode non-interactif pour toutes les installations

- Tous les modules (`modules/*.sh`)
  - `DEBIAN_FRONTEND=noninteractive` ajouté à toutes les commandes `apt install`

#### Nouveaux fichiers
- `modules/09-update-checker.sh` : Système de vérification automatique des mises à jour
- `UPDATE_SYSTEM.md` : Documentation complète du système de mise à jour
- `README_NEW.md` : README mis à jour avec toutes les nouvelles fonctionnalités
- `CHANGELOG.md` : Ce fichier

### 📚 Documentation

#### Documentation ajoutée
- Guide complet du système de mise à jour automatique (`UPDATE_SYSTEM.md`)
- Section dédiée dans le README
- Exemples d'utilisation des nouvelles commandes
- Instructions de personnalisation

#### Documentation mise à jour
- README principal avec les nouvelles fonctionnalités
- Table des matières mise à jour
- Exemples de rappels SSH
- Commandes de gestion du système

### 🎯 Comportement du script

#### Avant (Version 1.0.0)
```bash
sudo ./post_install.sh
# 1. Choix du type d'installation
# 2. Sélection des modules (si personnalisé)
# 3. Confirmation "Continuer avec cette configuration ?"
# 4. Installation des modules
# 5. En cas d'erreur : "Continuer malgré l'erreur ?"
```

#### Après (Version 1.1.0)
```bash
sudo ./post_install.sh
# 1. Choix du type d'installation
# 2. Sélection des modules (si personnalisé)
# 3. Affichage des modules sélectionnés
# 4. Countdown de 3 secondes
# 5. Mise à jour système automatique
# 6. Installation automatique de tous les modules
# 7. Continuation automatique en cas d'erreur
# 8. Seule interaction : mot de passe pour l'utilisateur "seb"
```

### 🔄 Système de mise à jour

#### Fichiers créés par le module 09
```
/usr/local/bin/check-updates.sh      # Script de vérification
/var/log/update-checker.log           # Log des vérifications
/var/run/updates-available            # Flag temporaire
/etc/profile.d/update-reminder.sh     # Script au login
/etc/systemd/system/update-checker.service
/etc/systemd/system/update-checker.timer
```

#### Alias créés
```bash
check-updates   # Vérifier manuellement les mises à jour
update-system   # apt update && apt upgrade && apt autoremove
update-log      # Voir les logs des vérifications
```

#### Exemple de rappel
```
╔════════════════════════════════════════════════════════════╗
║  ⚠️  MISES À JOUR DISPONIBLES                              ║
║  🔒 5 mises à jour de SÉCURITÉ                             ║
║  📦 23 packages peuvent être mis à jour                    ║
║  Pour mettre à jour, exécutez:                            ║
║  sudo apt update && sudo apt upgrade -y                    ║
╚════════════════════════════════════════════════════════════╝
```

### 🐛 Corrections

- Correction du double apt update/upgrade (maintenant fait une seule fois)
- Meilleure gestion des erreurs avec continuation automatique
- Mode non-interactif complet pour éviter les blocages

### 📊 Statistiques

- **Modules** : 9 (nouveau : update-checker)
- **Fichiers modifiés** : 10
- **Nouveaux fichiers** : 4
- **Lignes de code ajoutées** : ~300
- **Interactions manuelles** : 2 (type d'installation + mot de passe seb)

### 🚀 Prochaines étapes suggérées

Pour les versions futures :
- [ ] Ajouter un mode totalement silencieux (--silent)
- [ ] Permettre de passer le mot de passe en variable d'environnement
- [ ] Ajouter des tests automatisés
- [ ] Créer un mode "rollback" en cas d'échec
- [ ] Ajouter la configuration de Fail2ban
- [ ] Créer un fichier de configuration externe pour les variables

---

## Version 1.0.0 - 2025-11-10 (Initial)

### Fonctionnalités initiales

- Script principal avec menu interactif
- 8 modules d'installation
- Configuration utilisateur avec sudo
- Installation de zsh + oh-my-zsh
- Outils de développement (Python, Node.js, Go, Terraform)
- Docker CE + Docker Compose
- Bases de données (MySQL, PostgreSQL)
- Serveur web Nginx
- Outils média (FFmpeg)
- Gaming (SteamCMD, LGSM)
- Sécurité (UFW)

---

**Mainteneur** : Seb (sebpicot@gmail.com)  
**Repository** : https://github.com/bikininjas/ubuntu_post_install
