# Enroll Macs WSO - Structure du Projet

## 📁 Organisation des Fichiers

Le projet a été restructuré pour suivre une architecture modulaire claire :

### 🚀 Point d'Entrée
- **App.swift** - Point d'entrée principal avec `@main`, AppDelegate et menus de l'application

### 📦 Modèles (Models/)
- **ModelsMachine.swift** - Définition du modèle Machine avec encodage JSON
- **ModelsOrganisationGroup.swift** - Groupes d'organisation WSO
- **ModelsEnrollmentProfile.swift** - Profils d'enrollment Mac
- **ModelsMachineNamePrefix.swift** - Préfixes de noms de machines

### 🎨 Vues (Views/)
- **ViewsMachineListView.swift** - Vue principale avec tableau des machines et actions
- **ViewsAddMachineView.swift** - Formulaire d'ajout de machine
- **ViewsDetailsMachineView.swift** - Formulaire d'édition de machine
- **ViewsConfigurationView.swift** - Interface de configuration de l'application
- **ViewsFormFieldsView.swift** - Composants de formulaire réutilisables

### ⚙️ Services (Services/)
- **ServicesCoreDataService.swift** - Singleton pour toutes les opérations Core Data
  - Gestion de la configuration de l'app
  - Persistance des machines
  - Accès aux groupes d'organisation, profils et préfixes
  
- **ServicesKeychainService.swift** - Gestion sécurisée des credentials Samba
  - Stockage/récupération des identifiants
  - Suppression du keychain
  
- **ServicesLDAPService.swift** - Requêtes LDAP pour récupérer les emails
  - Authentification LDAP
  - Recherche d'utilisateurs
  
- **ServicesSambaService.swift** - Upload de fichiers JSON vers Samba
  - Mode test (sauvegarde locale)
  - Mode production (upload SMB)

### 🛠 Utilitaires (Utilities/)
- **UtilitiesExtensions.swift** - Extensions Swift (opérateur `!` pour Binding, SortOrder)
- **ConfigManager.swift** - Gestion du mode test/production
- **Persistence.swift** - Configuration du conteneur Core Data

### 💾 Core Data
- **CoreDataAppConfig+CoreDataClass.swift** - Classe Core Data pour AppConfig
- **CoreDataAppConfig+CoreDataProperties.swift** - Propriétés de l'entité AppConfig
  - platformId
  - ownership
  - messageType
  - sambaPath
  - ldapServer
  - ldapBaseDN
  - organisationGroupsJSON
  - enrollmentProfiles
  - machineNamePrefixesJSON
  - machinesJSON

## 🔄 Migration depuis l'ancien fichier

L'ancien fichier monolithique `Enroll_Macs_WSOApp.swift` (2000+ lignes) a été décomposé en modules logiques.

### Modifications nécessaires dans le modèle Core Data (.xcdatamodeld)

Si votre entité `AppConfig` n'existe pas encore dans le modèle Core Data, créez-la avec les attributs suivants :

| Attribut | Type | Optionnel |
|----------|------|-----------|
| platformId | Integer 32 | Non |
| ownership | String | Oui |
| messageType | Integer 32 | Non |
| sambaPath | String | Oui |
| ldapServer | String | Oui |
| ldapBaseDN | String | Oui |
| organisationGroupsJSON | String | Oui |
| enrollmentProfiles | String | Oui |
| machineNamePrefixesJSON | String | Oui |
| machinesJSON | String | Oui |

### Actions requises

1. ✅ Vérifier que l'entité `AppConfig` existe dans le fichier `.xcdatamodeld`
2. ✅ S'assurer que tous les attributs sont présents
3. ✅ Supprimer l'ancien fichier `Enroll_Macs_WSOApp.swift` du projet Xcode
4. ✅ Supprimer le fichier `AppAppMenus.swift` (maintenant vide)
5. ✅ Compiler et tester

## 🏗 Architecture

```
┌─────────────────┐
│     App.swift   │  ← Point d'entrée @main
└────────┬────────┘
         │
         ├──────────────────────────────────┐
         │                                  │
┌────────▼────────┐              ┌─────────▼────────┐
│  MachineList    │              │  Configuration   │
│      View       │              │       View       │
└────────┬────────┘              └─────────┬────────┘
         │                                  │
         ├──────────────────────────────────┤
         │                                  │
┌────────▼────────────────────────▼─────────┐
│           Services Layer                  │
│  ┌──────────────────────────────────┐    │
│  │  CoreDataService                  │    │
│  │  KeychainService                  │    │
│  │  LDAPService                      │    │
│  │  SambaService                     │    │
│  └──────────────────────────────────┘    │
└───────────────────────────────────────────┘
         │
┌────────▼────────┐
│   Core Data     │
│   Persistence   │
└─────────────────┘
```

## 🔧 Utilisation des Services

### CoreDataService
```swift
// Sauvegarder des machines
CoreDataService.shared.saveMachines(machines)

// Charger les machines
let machines = CoreDataService.shared.loadMachines()

// Récupérer la configuration
if let config = CoreDataService.shared.getAppConfig() {
    // Utiliser config
}

// Récupérer les groupes d'organisation
let groups = CoreDataService.shared.getOrganisationGroups()
```

### KeychainService
```swift
// Enregistrer un mot de passe
KeychainService.shared.set("password", for: .sambaPassword)

// Récupérer un mot de passe
if let password = KeychainService.shared.get(.sambaPassword) {
    // Utiliser password
}
```

### LDAPService
```swift
// Rechercher un email
LDAPService.shared.fetchEmail(username: "jdoe") { result in
    switch result {
    case .found(let email):
        print("Email: \(email)")
    case .noMail:
        print("Pas d'email")
    case .notFound:
        print("Utilisateur non trouvé")
    case .error:
        print("Erreur LDAP")
    }
}
```

### SambaService
```swift
// Enregistrer un fichier
SambaService.shared.saveFile(filename: "machine.json", content: jsonData) { success, message in
    if success {
        print("Succès: \(message)")
    } else {
        print("Échec: \(message)")
    }
}
```

## 📝 Notes Importantes

1. **Singleton Pattern** : Tous les services utilisent le pattern Singleton (`shared`)
2. **Async Operations** : Les services LDAP et Samba utilisent des callbacks asynchrones
3. **Error Handling** : Tous les services incluent une gestion d'erreur appropriée
4. **Test Mode** : Le `ConfigManager` permet de basculer entre mode test et production

## 🐛 Résolution des Erreurs

### "Value of type 'AppConfig' has no member 'xxx'"
→ Vérifiez que l'entité AppConfig dans le modèle Core Data (.xcdatamodeld) contient tous les attributs listés ci-dessus.

### "Multiple commands produce .swiftconstvalues"
→ Assurez-vous qu'il n'y a qu'une seule définition de AppConfig+CoreDataClass et AppConfig+CoreDataProperties. Supprimez les doublons générés automatiquement par Xcode si nécessaire.

### "AppConfig is ambiguous for type lookup"
→ Vérifiez qu'il n'y a pas de définition en double de la classe AppConfig dans le projet.

### "Invalid redeclaration of 'AppMenu'"
→ Supprimez le fichier AppAppMenus.swift car les menus sont maintenant dans App.swift.

## ✅ Checklist de Migration

- [ ] Vérifier le modèle Core Data (.xcdatamodeld)
- [ ] Ajouter tous les attributs manquants à AppConfig
- [ ] Supprimer Enroll_Macs_WSOApp.swift de Xcode
- [ ] Supprimer AppAppMenus.swift de Xcode
- [ ] Nettoyer les fichiers en double (ex: ServicesLDAPService 2.swift)
- [ ] Compiler le projet
- [ ] Tester l'ajout d'une machine
- [ ] Tester la sauvegarde/chargement
- [ ] Tester la configuration
- [ ] Tester l'upload Samba

---

**Créé le : 15 mai 2026**  
**Dernière mise à jour : 15 mai 2026**
