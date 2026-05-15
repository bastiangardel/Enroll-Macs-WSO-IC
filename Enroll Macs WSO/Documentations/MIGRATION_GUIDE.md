# 🚀 Guide de Migration Rapide

## Étapes à suivre MAINTENANT

### 1️⃣ Nettoyer le Projet Xcode

Dans Xcode, **supprimez** ces fichiers (clic droit → Delete → Move to Trash) :

- ❌ `Enroll_Macs_WSOApp.swift` (l'ancien fichier de 2000+ lignes)
- ❌ `AppAppMenus.swift` (contient des duplications)
- ❌ `Enroll_Macs_WSOApp_OLD.swift` (fichier de documentation temporaire)
- ❌ `DEPRECATED_Enroll_Macs_WSOApp.swift` (fichier de documentation temporaire)
- ❌ `ServicesLDAPService 2.swift` (doublon si présent)
- ❌ `ServicesSambaService 2.swift` (doublon si présent)

### 2️⃣ Vérifier le Modèle Core Data

1. Ouvrez le fichier `.xcdatamodeld` dans Xcode
2. Sélectionnez l'entité `AppConfig` (ou créez-la si elle n'existe pas)
3. Vérifiez que TOUS ces attributs sont présents :

```
platformId              Integer 32      ☐ Optional
ownership               String          ☑ Optional
messageType             Integer 32      ☐ Optional
sambaPath               String          ☑ Optional
ldapServer              String          ☑ Optional
ldapBaseDN              String          ☑ Optional
organisationGroupsJSON  String          ☑ Optional
enrollmentProfiles      String          ☑ Optional
machineNamePrefixesJSON String          ☑ Optional
machinesJSON            String          ☑ Optional
```

### 3️⃣ Gérer les Fichiers Core Data Auto-générés

Si Xcode a généré automatiquement `AppConfig+CoreDataClass.swift` et `AppConfig+CoreDataProperties.swift` :

1. Dans le modèle (.xcdatamodeld), sélectionnez l'entité `AppConfig`
2. Dans l'inspecteur à droite, sous "Codegen", sélectionnez "Manual/None"
3. Supprimez les fichiers auto-générés s'ils existent
4. Utilisez à la place :
   - `CoreDataAppConfig+CoreDataClass.swift`
   - `CoreDataAppConfig+CoreDataProperties.swift`

### 4️⃣ Compiler

1. Nettoyez le build : **Product → Clean Build Folder** (⇧⌘K)
2. Fermez et rouvrez Xcode (optionnel mais recommandé)
3. Compilez : **Product → Build** (⌘B)

### 5️⃣ Résoudre les Erreurs Potentielles

#### Erreur : "Value of type 'AppConfig' has no member 'xxx'"
→ L'attribut manque dans le modèle Core Data. Ajoutez-le (voir étape 2)

#### Erreur : "Multiple commands produce .swiftconstvalues"
→ Fichiers Core Data en double. Voir étape 3 pour désactiver Codegen

#### Erreur : "'AppConfig' is ambiguous"
→ Plusieurs définitions de AppConfig. Supprimez les doublons (voir étape 1 et 3)

#### Erreur : "Cannot find 'xxx' in scope"
→ Un import est peut-être manquant. Vérifiez que tous les fichiers sont dans le projet

### 6️⃣ Tester l'Application

Lancez l'app et testez :

- [ ] Configuration initiale
- [ ] Ajout d'une machine
- [ ] Édition d'une machine
- [ ] Sauvegarde automatique
- [ ] Rechargement au démarrage
- [ ] Suppression de machines
- [ ] Envoi vers Samba (mode test)

## 📋 Structure Finale

Votre projet devrait avoir cette structure :

```
Enroll Macs WSO/
├── App.swift                                    ✅ Point d'entrée
├── Models/
│   ├── ModelsMachine.swift                      ✅
│   ├── ModelsOrganisationGroup.swift            ✅
│   ├── ModelsEnrollmentProfile.swift            ✅
│   └── ModelsMachineNamePrefix.swift            ✅
├── Views/
│   ├── ViewsMachineListView.swift               ✅
│   ├── ViewsAddMachineView.swift                ✅
│   ├── ViewsDetailsMachineView.swift            ✅
│   ├── ViewsConfigurationView.swift             ✅
│   └── ViewsFormFieldsView.swift                ✅
├── Services/
│   ├── ServicesCoreDataService.swift            ✅
│   ├── ServicesKeychainService.swift            ✅
│   ├── ServicesLDAPService.swift                ✅
│   └── ServicesSambaService.swift               ✅
├── Utilities/
│   ├── UtilitiesExtensions.swift                ✅
│   ├── ConfigManager.swift                      ✅
│   └── Persistence.swift                        ✅
├── Core Data/
│   ├── CoreDataAppConfig+CoreDataClass.swift    ✅
│   ├── CoreDataAppConfig+CoreDataProperties.swift ✅
│   └── YourModel.xcdatamodeld                   ✅ (avec entité AppConfig)
└── Documentation/
    ├── PROJECT_STRUCTURE.md                     ✅
    ├── MIGRATION_GUIDE.md                       ✅ (ce fichier)
    └── MACHINES_PERSISTENCE_README.md           ✅

SUPPRIMÉS :
├── Enroll_Macs_WSOApp.swift                     ❌
├── AppAppMenus.swift                            ❌
└── (tous les fichiers dupliqués)                ❌
```

## ⚠️ Important

**NE PAS** supprimer les fichiers du disque directement via Finder.  
**TOUJOURS** supprimer via Xcode pour que le projet reste cohérent.

## 🆘 En Cas de Problème

Si vous rencontrez des erreurs après la migration :

1. Fermez complètement Xcode
2. Supprimez le dossier `DerivedData` :
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```
3. Rouvrez le projet
4. Nettoyez : Product → Clean Build Folder (⇧⌘K)
5. Compilez : Product → Build (⌘B)

## ✅ Vérification Finale

Avant de considérer la migration terminée, vérifiez :

- [ ] Aucune erreur de compilation
- [ ] Aucun warning concernant des fichiers dupliqués
- [ ] L'application se lance correctement
- [ ] La configuration fonctionne
- [ ] L'ajout de machines fonctionne
- [ ] La persistance fonctionne (fermez et rouvrez l'app)
- [ ] Le mode test fonctionne

---

**Questions ou problèmes ?** Consultez `PROJECT_STRUCTURE.md` pour plus de détails.
