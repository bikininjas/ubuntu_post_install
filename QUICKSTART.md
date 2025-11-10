# 🚀 Guide de Démarrage Rapide

## Installation en 4 étapes

### 1️⃣ Installer Git (si nécessaire)

Sur un serveur tout neuf, Git n'est pas installé par défaut :

```bash
sudo apt update
sudo apt install -y git
```

### 2️⃣ Télécharger le script

```bash
git clone https://github.com/bikininjas/ubuntu_post_install.git
cd ubuntu_post_install
```

### 3️⃣ Rendre les scripts exécutables

```bash
chmod +x post_install.sh modules/*.sh
```

### 4️⃣ Lancer l'installation

```bash
sudo ./post_install.sh
```

## 📋 Ce qui va se passer

1. **Menu de sélection** : Choisissez entre installation complète ou personnalisée
2. **Affichage des modules** : Vous verrez la liste des modules qui seront installés
3. **Countdown** : 3 secondes avant le démarrage
4. **Mot de passe** : Vous devrez créer un mot de passe pour l'utilisateur "seb"
5. **Installation automatique** : Tout le reste se fait automatiquement !

## 💻 Installation complète en une ligne

Si vous préférez tout en une seule commande (sur un serveur neuf) :

```bash
sudo apt update && sudo apt install -y git && git clone https://github.com/bikininjas/ubuntu_post_install.git && cd ubuntu_post_install && chmod +x post_install.sh modules/*.sh && sudo ./post_install.sh
```

## ⏱️ Durée estimée

- **Installation complète** : 20-30 minutes (selon votre connexion Internet)
- **Installation minimale** : 5-10 minutes

## 🎯 Modules disponibles

| Module | Temps estimé | Description |
|--------|--------------|-------------|
| **Base System** | 2-3 min | Utilisateur, zsh, oh-my-zsh |
| **Dev Tools** | 5-7 min | Python 3.13, Node.js, Go, Terraform |
| **Docker** | 2-3 min | Docker CE + Compose |
| **Databases** | 3-4 min | MySQL/MariaDB + PostgreSQL |
| **Web Server** | 2-3 min | Nginx + PHP |
| **Media Tools** | 3-5 min | FFmpeg, codecs |
| **Gaming** | 2-3 min | SteamCMD, LGSM |
| **Security** | 1-2 min | UFW firewall |
| **Update Checker** | 1 min | Système de mise à jour auto |

## ✅ Après l'installation

### 1. Redémarrer ou changer d'utilisateur

```bash
# Option 1 : Changer d'utilisateur
su - seb

# Option 2 : Redémarrer (recommandé pour Docker)
sudo reboot
```

### 2. Vérifier les installations

```bash
# Vérifier zsh
echo $SHELL

# Vérifier Docker
docker --version

# Vérifier Python
python3.13 --version

# Vérifier Node.js
node --version

# Vérifier Go
go version
```

### 3. Utiliser les nouvelles commandes

```bash
# Vérifier les mises à jour
check-updates

# Mettre à jour le système
update-system

# Voir les logs de mise à jour
update-log
```

## 🆘 Besoin d'aide ?

### Serveur tout neuf sans Git

Si vous êtes sur un serveur Ubuntu fraîchement installé :

```bash
# 1. Mettre à jour la liste des paquets
sudo apt update

# 2. Installer Git
sudo apt install -y git

# 3. Cloner le projet
git clone https://github.com/bikininjas/ubuntu_post_install.git

# 4. Entrer dans le dossier
cd ubuntu_post_install

# 5. Rendre les scripts exécutables
chmod +x post_install.sh modules/*.sh

# 6. Lancer l'installation
sudo ./post_install.sh
```

### Le script ne démarre pas

```bash
# Vérifier que vous êtes root
sudo su
./post_install.sh

# Ou avec sudo directement
sudo ./post_install.sh
```

### Erreur de permissions

```bash
chmod +x post_install.sh modules/*.sh
```

### Docker ne fonctionne pas

```bash
# Déconnexion/reconnexion nécessaire
exit
su - seb

# Ou redémarrer
sudo reboot
```

## 📚 Documentation complète

- **README.md** : Documentation complète du projet
- **UPDATE_SYSTEM.md** : Guide du système de mise à jour automatique
- **CHANGELOG.md** : Historique des versions
- **PROMPT.md** : Instructions pour une IA qui prendrait le relais

## 💡 Conseils

### Installation complète recommandée
Si vous ne savez pas quoi choisir, sélectionnez l'installation complète (option 1). Vous aurez tout le nécessaire pour :
- Développer en Python, Node.js, Go
- Héberger des sites web (WordPress, Node.js)
- Utiliser Docker
- Encoder des vidéos
- Créer des serveurs de jeu

### Installation personnalisée
Si vous voulez seulement certains composants :
- **Développeur** : Base System + Dev Tools + Docker
- **Serveur web** : Base System + Docker + Databases + Web Server
- **Serveur de jeu** : Base System + Docker + Gaming
- **Station multimédia** : Base System + Media Tools

### Sécurité
- ✅ Ne partagez JAMAIS votre mot de passe
- ✅ Utilisez un mot de passe fort (12+ caractères)
- ✅ Le firewall sera automatiquement activé
- ✅ Les mises à jour de sécurité seront surveillées

## 🔒 Ce qui est fait automatiquement

- ✅ Mise à jour complète du système
- ✅ Création de l'utilisateur "seb"
- ✅ Configuration des permissions sudo
- ✅ Installation de tous les outils sélectionnés
- ✅ Configuration du firewall
- ✅ Mise en place du système de mise à jour automatique
- ✅ Nettoyage du cache apt

## ⚠️ Important

### Avant de commencer
- [ ] Assurez-vous d'avoir une connexion Internet stable
- [ ] Vérifiez l'espace disque disponible (10 GB minimum)
- [ ] Sauvegardez vos données importantes
- [ ] Notez votre mot de passe quelque part de sûr

### Pendant l'installation
- ⏳ Ne fermez pas le terminal
- ⏳ Ne mettez pas l'ordinateur en veille
- ⏳ Laissez l'installation se terminer complètement

### Après l'installation
- 🔄 Redémarrez pour appliquer tous les changements
- 🔑 Testez votre nouveau mot de passe
- ✅ Vérifiez que tout fonctionne

## 🎉 C'est tout !

Une fois l'installation terminée, vous aurez un serveur Ubuntu 24.04 parfaitement configuré et prêt à l'emploi !

---

**Questions ?** Consultez le README.md ou ouvrez une issue sur GitHub.

**Auteur** : Seb (sebpicot@gmail.com)  
**Version** : 1.1.0
