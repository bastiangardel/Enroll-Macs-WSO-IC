# ✅ Checklist de Vérification Core Data

## Modèle Core Data - Entité AppConfig

Ouvrez votre fichier `.xcdatamodeld` dans Xcode et vérifiez que l'entité `AppConfig` contient EXACTEMENT ces attributs :

### Liste des Attributs

| # | Nom de l'attribut | Type | Optionnel | ✓ |
|---|-------------------|------|-----------|---|
| 1 | `platformId` | Integer 32 | ☐ Non | ☐ |
| 2 | `ownership` | String | ☑ Oui | ☐ |
| 3 | `messageType` | Integer 32 | ☐ Non | ☐ |
| 4 | `sambaPath` | String | ☑ Oui | ☐ |
| 5 | `ldapServer` | String | ☑ Oui | ☐ |
| 6 | `ldapBaseDN` | String | ☑ Oui | ☐ |
| 7 | `organisationGroupsJSON` | String | ☑ Oui | ☐ |
| 8 | `enrollmentProfiles` | String | ☑ Oui | ☐ |
| 9 | `machineNamePrefixesJSON` | String | ☑ Oui | ☐ |
| 10 | `machinesJSON` | String | ☑ Oui | ☐ |

### Instructions Détaillées

#### Si l'entité AppConfig n'existe PAS :

1. Cliquez sur le bouton "Add Entity" en bas de la fenêtre
2. Nommez l'entité `AppConfig`
3. Ajoutez tous les attributs listés ci-dessus

#### Si l'entité AppConfig existe DÉJÀ :

1. Sélectionnez l'entité `AppConfig`
2. Vérifiez chaque attribut dans la liste
3. Cochez ✓ dans la colonne de droite pour chaque attribut présent
4. Si un attribut manque, ajoutez-le :
   - Cliquez sur "+" dans la section Attributes
   - Entrez le nom exactement comme indiqué (sensible à la casse !)
   - Sélectionnez le type
   - Cochez/décochez "Optional" selon la colonne "Optionnel"

### Configuration de Codegen

**IMPORTANT** : Pour éviter les conflits avec les fichiers manuels, configurez :

1. Sélectionnez l'entité `AppConfig`
2. Dans l'inspecteur à droite (Data Model Inspector)
3. Trouvez la section "Codegen"
4. Sélectionnez **"Manual/None"**

### Comment Ajouter un Attribut

1. Sélectionnez l'entité `AppConfig`
2. Dans la section "Attributes", cliquez sur le bouton "+"
3. Double-cliquez sur le nom "attribute" et renommez-le
4. Dans l'inspecteur à droite :
   - **Name** : Le nom de l'attribut (ex: `platformId`)
   - **Type** : Le type de données (ex: `Integer 32` ou `String`)
   - **Optional** : Cochez si "☑ Oui" dans le tableau ci-dessus
   - **Default Value** : (Laissez vide sauf indication contraire)

### Exemple Visuel

```
AppConfig Entity
├── platformId              (Integer 32, Required)
├── ownership               (String, Optional)
├── messageType             (Integer 32, Required)
├── sambaPath               (String, Optional)
├── ldapServer              (String, Optional)
├── ldapBaseDN              (String, Optional)
├── organisationGroupsJSON  (String, Optional)
├── enrollmentProfiles      (String, Optional)
├── machineNamePrefixesJSON (String, Optional)
└── machinesJSON            (String, Optional)
```

### Vérification Rapide

Après avoir ajouté/vérifié tous les attributs :

```bash
# Nombre total d'attributs
10 attributs

# Attributs Required (non-optional)
2 attributs : platformId, messageType

# Attributs Optional
8 attributs : tous les autres
```

## ⚠️ Erreurs Courantes

### ❌ Faute de frappe dans le nom
```
enrollmentProfile  ← INCORRECT
enrollmentProfiles ← CORRECT (avec 's')
```

### ❌ Mauvais type
```
platformId : String     ← INCORRECT
platformId : Integer 32 ← CORRECT
```

### ❌ Optional/Required inversé
```
platformId : Optional   ← INCORRECT
platformId : Required   ← CORRECT
```

### ❌ Codegen sur "Class Definition"
```
Codegen: Class Definition  ← INCORRECT (crée des conflits)
Codegen: Manual/None       ← CORRECT
```

## 🔍 Vérification Post-Configuration

Après avoir configuré le modèle Core Data :

1. ✅ Sauvegarder le fichier .xcdatamodeld (⌘S)
2. ✅ Fermer et rouvrir Xcode (recommandé)
3. ✅ Clean Build Folder (⇧⌘K)
4. ✅ Compiler (⌘B)

Si la compilation réussit sans erreur concernant AppConfig, le modèle est correct ! ✅

## 🆘 En Cas de Problème

### Erreur : "Value of type 'AppConfig' has no member 'xxx'"

→ L'attribut `xxx` manque ou a une faute de frappe

**Solution :**
1. Ouvrez .xcdatamodeld
2. Vérifiez l'orthographe exacte de l'attribut
3. Vérifiez que le nom correspond EXACTEMENT au code
4. Ajoutez l'attribut s'il manque

### Erreur : "Multiple commands produce .swiftconstvalues"

→ Codegen est encore sur "Class Definition"

**Solution :**
1. Ouvrez .xcdatamodeld
2. Sélectionnez AppConfig
3. Codegen → "Manual/None"
4. Supprimez les fichiers auto-générés (AppConfig+CoreDataClass.swift, AppConfig+CoreDataProperties.swift) s'ils sont dans le projet ET différents de CoreDataAppConfig+...
5. Clean Build Folder

### Erreur : "Cannot find type 'AppConfig'"

→ Les fichiers CoreData n'ont pas été ajoutés au projet

**Solution :**
1. Vérifiez que `CoreDataAppConfig+CoreDataClass.swift` est dans le projet
2. Vérifiez que `CoreDataAppConfig+CoreDataProperties.swift` est dans le projet
3. Clean Build Folder

## ✅ Validation Finale

Copiez ce code Swift dans un fichier test pour valider :

```swift
// Test de validation du modèle Core Data
func validateCoreDataModel() {
    let config = CoreDataService.shared.getAppConfig()
    
    // Ces lignes ne doivent produire AUCUNE erreur de compilation
    let _ = config?.platformId              // Int32
    let _ = config?.ownership               // String?
    let _ = config?.messageType             // Int32
    let _ = config?.sambaPath               // String?
    let _ = config?.ldapServer              // String?
    let _ = config?.ldapBaseDN              // String?
    let _ = config?.organisationGroupsJSON  // String?
    let _ = config?.enrollmentProfiles      // String?
    let _ = config?.machineNamePrefixesJSON // String?
    let _ = config?.machinesJSON            // String?
    
    print("✅ Modèle Core Data validé avec succès !")
}
```

Si ce code compile sans erreur, votre modèle Core Data est correctement configuré ! 🎉

---

**Note** : Ce fichier fait partie de la restructuration du projet.  
Consultez `MIGRATION_GUIDE.md` pour le guide complet de migration.
