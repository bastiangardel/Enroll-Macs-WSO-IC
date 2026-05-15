# 🗑 Fichiers à Supprimer

## ⚠️ IMPORTANT : Comment Supprimer Correctement

**NE PAS** supprimer via Finder  
**NE PAS** supprimer du système de fichiers directement

**TOUJOURS** supprimer via Xcode :
1. Clic droit sur le fichier dans le navigateur de projet
2. **Delete**
3. Choisir **"Move to Trash"** (pas "Remove Reference")

---

## 📋 Liste des Fichiers à Supprimer

### 1. Ancien Fichier Principal (OBLIGATOIRE)

- ❌ **Enroll_Macs_WSOApp.swift**
  - Raison : Fichier monolithique de 2000+ lignes remplacé par une architecture modulaire
  - Remplacé par : `App.swift` + tous les fichiers Services/ et Views/

### 2. Menus Dupliqués (OBLIGATOIRE)

- ❌ **AppAppMenus.swift**
  - Raison : Crée des redéclarations de `AppMenu`, `FileMenu`, `EditMenu`
  - Remplacé par : Menus dans `App.swift` (AppMenuCommands, FileMenuCommands, EditMenuCommands)

### 3. Fichiers de Documentation Temporaires (RECOMMANDÉ)

- ❌ **Enroll_Macs_WSOApp_OLD.swift**
  - Raison : Fichier de documentation temporaire créé durant la migration
  - Contenu : Juste des commentaires de redirection

- ❌ **DEPRECATED_Enroll_Macs_WSOApp.swift**
  - Raison : Fichier de documentation temporaire créé durant la migration
  - Contenu : Juste des commentaires de redirection

### 4. Fichiers Dupliqués (SI PRÉSENTS)

- ❌ **ServicesLDAPService 2.swift** (si présent)
  - Raison : Doublon créé accidentellement
  - Garder : `ServicesLDAPService.swift`

- ❌ **ServicesSambaService 2.swift** (si présent)
  - Raison : Doublon créé accidentellement
  - Garder : `ServicesSambaService.swift`

- ❌ Tout autre fichier avec " 2" dans le nom

### 5. Fichiers Core Data Auto-générés (SI PRÉSENTS ET DIFFÉRENTS)

Si Xcode a auto-généré ces fichiers ET qu'ils sont différents de nos versions manuelles :

- ❌ **AppConfig+CoreDataClass.swift** (auto-généré par Xcode)
  - Garder à la place : `CoreDataAppConfig+CoreDataClass.swift`

- ❌ **AppConfig+CoreDataProperties.swift** (auto-généré par Xcode)
  - Garder à la place : `CoreDataAppConfig+CoreDataProperties.swift`

**Comment vérifier :**
1. Cherchez "AppConfig" dans le navigateur de projet
2. S'il y a 4 fichiers (2 auto-générés + 2 manuels), supprimez les auto-générés
3. S'il y a seulement 2 fichiers (CoreDataAppConfig+...), c'est OK !

---

## ✅ Fichiers à GARDER (Ne PAS Supprimer)

### Application
- ✅ **App.swift** - NOUVEAU point d'entrée

### Models
- ✅ **ModelsMachine.swift**
- ✅ **ModelsOrganisationGroup.swift**
- ✅ **ModelsEnrollmentProfile.swift**
- ✅ **ModelsMachineNamePrefix.swift**

### Views
- ✅ **ViewsMachineListView.swift**
- ✅ **ViewsAddMachineView.swift**
- ✅ **ViewsDetailsMachineView.swift**
- ✅ **ViewsConfigurationView.swift**
- ✅ **ViewsFormFieldsView.swift**

### Services
- ✅ **ServicesCoreDataService.swift**
- ✅ **ServicesKeychainService.swift**
- ✅ **ServicesLDAPService.swift**
- ✅ **ServicesSambaService.swift**

### Utilities
- ✅ **UtilitiesExtensions.swift**
- ✅ **ConfigManager.swift**
- ✅ **Persistence.swift**

### Core Data
- ✅ **CoreDataAppConfig+CoreDataClass.swift**
- ✅ **CoreDataAppConfig+CoreDataProperties.swift**
- ✅ **YourModel.xcdatamodeld** (le fichier du modèle Core Data)

### Documentation
- ✅ **PROJECT_STRUCTURE.md**
- ✅ **MIGRATION_GUIDE.md**
- ✅ **SUMMARY.md**
- ✅ **CORE_DATA_CHECKLIST.md**
- ✅ **BACKWARDS_COMPATIBILITY.swift**
- ✅ **FILES_TO_DELETE.md** (ce fichier)
- ✅ **MACHINES_PERSISTENCE_README.md**

### Resources
- ✅ Tous les fichiers Assets, Info.plist, etc.

---

## 📝 Procédure de Suppression Étape par Étape

### Étape 1 : Sauvegarder (Optionnel mais Recommandé)

```bash
# Créer une copie de sauvegarde du projet
cd /path/to/your/project/parent/folder
cp -R "Enroll Macs WSO" "Enroll Macs WSO - Backup"
```

Ou simplement faire un commit Git :
```bash
git add .
git commit -m "Sauvegarde avant suppression des fichiers obsolètes"
```

### Étape 2 : Ouvrir Xcode

1. Ouvrez votre projet dans Xcode
2. Attendez que l'indexation soit terminée

### Étape 3 : Supprimer les Fichiers Obsolètes

Pour chaque fichier de la liste "Fichiers à Supprimer" :

1. **Localisez** le fichier dans le navigateur de projet (panneau de gauche)
2. **Clic droit** sur le fichier
3. **Delete**
4. Quand Xcode demande, choisissez **"Move to Trash"**

### Étape 4 : Vérifier les Doublons

1. Dans Xcode, appuyez sur **⌘+Shift+O** (Open Quickly)
2. Tapez "AppConfig"
3. Vérifiez qu'il n'y a que 2 fichiers :
   - CoreDataAppConfig+CoreDataClass.swift
   - CoreDataAppConfig+CoreDataProperties.swift
4. Si vous voyez d'autres fichiers AppConfig+CoreData..., supprimez-les

### Étape 5 : Nettoyer le Build

1. **Product → Clean Build Folder** (⇧⌘K)
2. Fermez Xcode
3. Supprimez DerivedData :
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Enroll_Macs_WSO*
   ```
4. Rouvrez Xcode

### Étape 6 : Compiler

1. **Product → Build** (⌘B)
2. Résolvez les erreurs éventuelles (voir MIGRATION_GUIDE.md)

### Étape 7 : Tester

1. Lancez l'application (⌘R)
2. Testez les fonctionnalités de base
3. Vérifiez que tout fonctionne

---

## 🔍 Vérification Post-Suppression

Après avoir supprimé les fichiers, vérifiez :

### Dans le Navigateur de Projet Xcode

- [ ] Aucun fichier " 2.swift" visible
- [ ] Aucun fichier "OLD" ou "DEPRECATED" visible (sauf si vous voulez les garder pour référence)
- [ ] Pas de fichier "Enroll_Macs_WSOApp.swift" (l'ancien de 2000+ lignes)
- [ ] Pas de fichier "AppAppMenus.swift"

### Dans le Dossier du Projet (Finder)

```bash
cd /path/to/your/project
find . -name "*OLD*" -o -name "*DEPRECATED*" -o -name "* 2.swift"
```

Cette commande ne devrait rien retourner (ou seulement les fichiers de documentation si vous les gardez).

### Compilation

- [ ] Aucune erreur de compilation
- [ ] Aucun warning concernant des fichiers dupliqués
- [ ] Aucun warning concernant des symboles ambigus

### Tests Fonctionnels

- [ ] L'application se lance
- [ ] La configuration s'affiche
- [ ] L'ajout de machine fonctionne
- [ ] La sauvegarde fonctionne
- [ ] Le rechargement au démarrage fonctionne

---

## 🚨 Que Faire en Cas de Problème

### Si l'application ne compile plus

1. Vérifiez que vous n'avez pas supprimé un fichier de la liste "À GARDER"
2. Restaurez votre sauvegarde ou utilisez Git :
   ```bash
   git reset --hard HEAD
   ```
3. Recommencez la suppression plus prudemment

### Si vous avez supprimé un mauvais fichier

1. **Ne paniquez pas !**
2. Si vous avez une sauvegarde ou Git :
   ```bash
   git checkout -- <nom-du-fichier>
   ```
3. Si pas de sauvegarde, consultez les fichiers de documentation pour recréer le fichier

### Si vous voyez "File not found"

- C'est normal après suppression
- Clean Build Folder (⇧⌘K)
- Rebuild (⌘B)

---

## 📊 Récapitulatif

### Fichiers à Supprimer (Minimum)

1. ❌ Enroll_Macs_WSOApp.swift
2. ❌ AppAppMenus.swift

**C'est le strict minimum pour que le projet compile.**

### Fichiers à Supprimer (Recommandé)

1. ❌ Enroll_Macs_WSOApp.swift
2. ❌ AppAppMenus.swift
3. ❌ Enroll_Macs_WSOApp_OLD.swift
4. ❌ DEPRECATED_Enroll_Macs_WSOApp.swift
5. ❌ Tous les fichiers " 2.swift"
6. ❌ Fichiers Core Data auto-générés en double

**C'est ce qu'il faut supprimer pour un projet propre.**

---

**Date de création** : 15 mai 2026  
**Dernière mise à jour** : 15 mai 2026

Pour plus d'informations, consultez `MIGRATION_GUIDE.md`.
