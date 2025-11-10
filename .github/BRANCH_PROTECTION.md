# Configuration GitHub - Branch Protection

Ce document explique comment configurer les règles de protection de branche sur GitHub pour le projet `ubuntu_post_install`.

## 🔒 Configuration recommandée pour la branche `master`

### Étapes de configuration

1. Allez sur GitHub : `https://github.com/bikininjas/ubuntu_post_install/settings/branches`

2. Cliquez sur **"Add rule"** ou **"Add branch protection rule"**

3. Configurez les paramètres suivants :

#### Branch name pattern
```
master
```

#### Règles de protection à activer

✅ **Require a pull request before merging**
   - ✅ Require approvals: 0 (ou 1 si vous voulez une review)
   - ✅ Dismiss stale pull request approvals when new commits are pushed
   - ✅ Require review from Code Owners (optionnel)

✅ **Require status checks to pass before merging**
   - ✅ Require branches to be up to date before merging
   - Status checks requis :
     - `ShellCheck Validation`
     - `Bash Syntax Check`
     - `Check File Permissions`
     - `Validate Project Structure`

✅ **Require conversation resolution before merging**
   - Force la résolution de tous les commentaires

✅ **Require linear history** (optionnel)
   - Force un historique Git linéaire (pas de merge commits)

✅ **Do not allow bypassing the above settings**
   - Même les admins doivent passer par les checks

❌ **Allow force pushes** - DÉSACTIVÉ
   - Interdit les force push sur master

❌ **Allow deletions** - DÉSACTIVÉ
   - Interdit la suppression de la branche master

### Configuration alternative (plus stricte)

Si vous voulez une protection maximale :

✅ **Require a pull request before merging**
   - ✅ Require approvals: 1
   - ✅ Require approval from Code Owners

✅ **Require status checks to pass before merging**
   - ✅ Require branches to be up to date before merging

✅ **Require signed commits**
   - Force l'utilisation de commits GPG signés

## 🔄 Workflow GitHub Actions

### Fichiers créés

1. **`.github/workflows/shellcheck.yml`**
   - Exécute ShellCheck sur tous les scripts
   - Se déclenche sur les PRs et pushs vers master/main

2. **`.github/workflows/ci.yml`**
   - Validation complète (ShellCheck, syntaxe, permissions, structure)
   - 4 jobs parallèles pour une validation rapide

### Ce qui est vérifié

#### ✅ ShellCheck Validation
- Analyse statique de tous les scripts shell
- Détection des erreurs communes
- Suggestions d'amélioration

#### ✅ Bash Syntax Check
- Validation de la syntaxe bash
- Détection des erreurs de parsing

#### ✅ File Permissions
- Vérification que `post_install.sh` est exécutable
- Vérification que tous les modules sont exécutables

#### ✅ Project Structure
- Présence des fichiers requis (README, PROMPT, etc.)
- Présence du dossier modules
- Vérification que modules/ contient des scripts

## 📝 Comment créer une Pull Request

### 1. Créer une branche

```bash
git checkout -b feature/ma-nouvelle-fonctionnalite
```

### 2. Faire vos modifications

```bash
# Modifier les fichiers
nano modules/01-base-system.sh

# Ajouter les modifications
git add .
git commit -m "feat: ajout de nouvelle fonctionnalité"
```

### 3. Pousser la branche

```bash
git push origin feature/ma-nouvelle-fonctionnalite
```

### 4. Créer la Pull Request

1. Allez sur GitHub
2. Cliquez sur "Compare & pull request"
3. Remplissez la description
4. Attendez que les checks passent au vert ✅
5. Mergez quand tout est vert !

## 🚨 Si les checks échouent

### ShellCheck échoue

```bash
# Installer ShellCheck localement
sudo apt install shellcheck

# Vérifier vos scripts
shellcheck post_install.sh
shellcheck modules/*.sh

# Corriger les erreurs détectées
```

### Syntaxe bash invalide

```bash
# Tester la syntaxe
bash -n post_install.sh
bash -n modules/*.sh
```

### Permissions incorrectes

```bash
# Rendre les scripts exécutables
chmod +x post_install.sh
chmod +x modules/*.sh

# Commiter les changements de permissions
git add -u
git commit -m "fix: permissions des scripts"
git push
```

## 🎯 Bonnes pratiques

### Avant de pousser

```bash
# Vérifier localement
shellcheck post_install.sh modules/*.sh
bash -n post_install.sh modules/*.sh

# S'assurer que les permissions sont correctes
ls -la post_install.sh modules/

# Tester le script (dans une VM ou container)
sudo ./post_install.sh
```

### Nommage des branches

- `feature/` - Nouvelles fonctionnalités
- `fix/` - Corrections de bugs
- `docs/` - Modifications de documentation
- `refactor/` - Refactoring de code
- `test/` - Ajout de tests

### Messages de commit

Utilisez des messages clairs :
```
feat: ajout du module de monitoring
fix: correction de l'installation de Docker
docs: mise à jour du README
refactor: simplification du module base-system
```

## 📊 Status Badges

Vous pouvez ajouter des badges dans votre README :

```markdown
![CI Status](https://github.com/bikininjas/ubuntu_post_install/workflows/CI%20-%20Validation/badge.svg)
![ShellCheck](https://github.com/bikininjas/ubuntu_post_install/workflows/ShellCheck/badge.svg)
```

## 🔧 Configuration locale

### Pre-commit hook (optionnel)

Créez `.git/hooks/pre-commit` :

```bash
#!/bin/bash

echo "Running ShellCheck before commit..."

# Check all staged .sh files
for file in $(git diff --cached --name-only --diff-filter=ACM | grep "\.sh$"); do
    if [ -f "$file" ]; then
        shellcheck "$file"
        if [ $? -ne 0 ]; then
            echo "ShellCheck failed for $file"
            exit 1
        fi
    fi
done

echo "✓ All checks passed!"
exit 0
```

Puis :
```bash
chmod +x .git/hooks/pre-commit
```

---

**Note** : Ces configurations assurent la qualité du code et évitent les erreurs avant qu'elles n'arrivent en production !
