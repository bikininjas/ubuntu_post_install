# 🔄 Système de Mise à Jour Automatique

Le script de post-installation configure un système complet et automatisé de gestion des mises à jour pour votre serveur Ubuntu 24.04.

## ✅ Fonctionnalités

### 1. Mise à jour initiale
- Le script principal effectue `apt update && apt upgrade -y` au démarrage
- Garantit que le système est à jour avant toute installation

### 2. Vérification automatique tous les 4 jours
- **Cron job** : Tous les 4 jours à 3h00 du matin
- **Systemd timer** : Alternative moderne et persistante (survit aux redémarrages)
- Vérifie les packages disponibles pour mise à jour
- Détecte spécifiquement les mises à jour de sécurité

### 3. Rappel à chaque connexion SSH
- Message coloré automatique si des mises à jour sont disponibles
- Affiche le nombre total de packages à mettre à jour
- Alerte spéciale en rouge pour les mises à jour de sécurité
- Commande exacte à exécuter pour mettre à jour

### 4. Logs persistants
- Toutes les vérifications sont enregistrées dans `/var/log/update-checker.log`
- Rotation automatique si le fichier dépasse 10MB
- Historique complet des vérifications

## 📊 Commandes disponibles

Une fois le module `09-update-checker.sh` exécuté, vous aurez accès à ces alias pratiques :

```bash
# Vérifier manuellement les mises à jour disponibles
check-updates

# Mettre à jour le système complet (update + upgrade + autoremove)
update-system

# Voir le log des vérifications automatiques (50 dernières lignes)
update-log
```

## 🎯 Architecture du système

### Fichiers créés

| Fichier | Description |
|---------|-------------|
| `/usr/local/bin/check-updates.sh` | Script de vérification des mises à jour |
| `/var/log/update-checker.log` | Log de toutes les vérifications |
| `/var/run/updates-available` | Flag temporaire si des mises à jour existent |
| `/etc/profile.d/update-reminder.sh` | Script exécuté à chaque login |
| `/etc/systemd/system/update-checker.service` | Service systemd |
| `/etc/systemd/system/update-checker.timer` | Timer systemd (tous les 4 jours) |

### Processus de vérification

```
┌─────────────────────────────────────────────────────┐
│ Déclenchement (tous les 4 jours ou manuel)         │
└───────────────────┬─────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────┐
│ apt update (mise à jour de la liste des packages)  │
└───────────────────┬─────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────┐
│ Vérification : apt list --upgradable                │
└───────────────────┬─────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼
┌────────────────┐    ┌──────────────────┐
│ Mises à jour   │    │ Pas de mise      │
│ disponibles    │    │ à jour           │
└────────┬───────┘    └────────┬─────────┘
         │                     │
         ▼                     ▼
┌────────────────┐    ┌──────────────────┐
│ Créer flag     │    │ Supprimer flag   │
│ avec détails   │    │ s'il existe      │
└────────┬───────┘    └──────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│ Écrire dans le log avec la liste des packages      │
└─────────────────────────────────────────────────────┘
```

## 📝 Exemple de rappel SSH

Lorsque vous vous connectez au serveur et que des mises à jour sont disponibles :

```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║  ⚠️  MISES À JOUR DISPONIBLES                              ║
║                                                            ║
║  🔒 5 mises à jour de SÉCURITÉ                             ║
║  📦 23 packages peuvent être mis à jour                    ║
║                                                            ║
║  Dernière vérification: 2025-11-10 03:00:15                ║
║                                                            ║
║  Pour mettre à jour, exécutez:                            ║
║  sudo apt update && sudo apt upgrade -y                    ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

## 🔍 Commandes de gestion

### Vérifier le statut du timer systemd

```bash
# Voir le statut du timer
systemctl status update-checker.timer

# Voir quand sera la prochaine vérification
systemctl list-timers update-checker.timer

# Voir les logs du service
journalctl -u update-checker.service
```

### Gérer le timer

```bash
# Arrêter le timer
sudo systemctl stop update-checker.timer

# Désactiver le timer (ne démarre plus au boot)
sudo systemctl disable update-checker.timer

# Réactiver le timer
sudo systemctl enable update-checker.timer
sudo systemctl start update-checker.timer
```

### Forcer une vérification manuelle

```bash
# Exécuter le script manuellement
sudo /usr/local/bin/check-updates.sh

# Ou utiliser l'alias
check-updates
```

### Consulter les logs

```bash
# Voir les 50 dernières lignes
update-log

# Ou directement
sudo tail -50 /var/log/update-checker.log

# Voir tout le log
sudo less /var/log/update-checker.log

# Voir en temps réel (si vous lancez une vérification)
sudo tail -f /var/log/update-checker.log
```

## ⚙️ Personnalisation

### Modifier la fréquence de vérification

#### Pour le cron job

```bash
# Éditer le crontab
sudo crontab -e

# Changer la ligne (actuellement : 0 3 */4 * *)
# Format : minute heure jour_du_mois mois jour_de_la_semaine
# Exemples :
#   Tous les jours à 2h : 0 2 * * *
#   Toutes les semaines le lundi à 3h : 0 3 * * 1
#   Tous les 2 jours à 4h : 0 4 */2 * *
```

#### Pour le systemd timer

```bash
# Éditer le timer
sudo nano /etc/systemd/system/update-checker.timer

# Modifier la ligne OnUnitActiveSec
# Actuellement : OnUnitActiveSec=4d
# Exemples :
#   Tous les jours : OnUnitActiveSec=1d
#   Toutes les semaines : OnUnitActiveSec=7d
#   Toutes les 12 heures : OnUnitActiveSec=12h

# Recharger systemd
sudo systemctl daemon-reload
sudo systemctl restart update-checker.timer
```

### Désactiver le rappel à la connexion

```bash
# Commenter ou supprimer les lignes dans .zshrc
nano ~/.zshrc

# Chercher et commenter ces lignes :
# if [ -f /etc/profile.d/update-reminder.sh ]; then
#     source /etc/profile.d/update-reminder.sh
# fi
```

### Changer l'heure de vérification du cron

```bash
# Éditer le crontab
sudo crontab -e

# Changer l'heure (actuellement : 0 3 = 3h du matin)
# Par exemple, pour 23h : 0 23 */4 * *
```

## 🚨 Dépannage

### Le rappel ne s'affiche pas à la connexion

```bash
# Vérifier si le fichier profile.d existe
ls -l /etc/profile.d/update-reminder.sh

# Vérifier si c'est bien sourcé dans .zshrc
grep "update-reminder" ~/.zshrc

# Tester manuellement le script
bash /etc/profile.d/update-reminder.sh
```

### Le timer ne se lance pas

```bash
# Vérifier le statut
systemctl status update-checker.timer

# Voir les erreurs
journalctl -u update-checker.timer -n 50

# Recharger et redémarrer
sudo systemctl daemon-reload
sudo systemctl restart update-checker.timer
```

### Les vérifications ne se font pas

```bash
# Vérifier le cron job
sudo crontab -l | grep check-updates

# Tester manuellement le script
sudo /usr/local/bin/check-updates.sh

# Voir les logs du cron
sudo grep CRON /var/log/syslog | tail -20
```

### Le log est trop volumineux

Le log est automatiquement rotaté à 10MB, mais vous pouvez le nettoyer manuellement :

```bash
# Sauvegarder l'ancien log
sudo mv /var/log/update-checker.log /var/log/update-checker.log.old

# Créer un nouveau log
sudo touch /var/log/update-checker.log
sudo chmod 644 /var/log/update-checker.log
```

## 🔐 Sécurité

### Permissions des fichiers

```bash
# Script de vérification (exécutable par root)
-rwxr-xr-x /usr/local/bin/check-updates.sh

# Log (lisible par tous)
-rw-r--r-- /var/log/update-checker.log

# Flag temporaire (lisible par tous)
-rw-r--r-- /var/run/updates-available

# Script profile (exécutable par tous)
-rwxr-xr-x /etc/profile.d/update-reminder.sh
```

### Le script ne modifie jamais le système

- ✅ Lecture seule : ne fait que vérifier les mises à jour disponibles
- ✅ Pas d'installation automatique : vous gardez le contrôle
- ✅ Pas de redémarrage automatique
- ✅ Seulement des notifications

## 📚 Ressources

- [Documentation UFW](https://help.ubuntu.com/community/UFW)
- [Systemd Timers](https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
- [Cron Format](https://crontab.guru/)
- [APT Update Security](https://ubuntu.com/security/notices)

---

**Auteur**: Seb (sebpicot@gmail.com)  
**Projet**: ubuntu_post_install  
**Licence**: Libre d'utilisation
