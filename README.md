# 🖥️ Enroll Macs WSO

**Application macOS pour l'enrôlement automatique de machines dans Workspace ONE (WSO)**

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 📖 Table des Matières

- [Vue d'ensemble](#-vue-densemble)
- [Fonctionnalités](#-fonctionnalités)
- [Architecture](#-architecture)
- [Prérequis](#-prérequis)
- [Installation](#-installation)
- [Utilisation](#-utilisation)
- [Configuration](#️-configuration)
- [Flux de Fonctionnement](#-flux-de-fonctionnement)
- [Technologies](#-technologies)
- [Structure du Projet](#-structure-du-projet)
- [Développement](#-développement)
- [FAQ](#-faq)
- [Licence](#-licence)

---

## 🎯 Vue d'ensemble

**Enroll Macs WSO** est une application native macOS développée en SwiftUI qui automatise le processus d'enrôlement de machines Mac dans Workspace ONE (WSO). Elle permet de :

- ✅ Créer des profils d'enrôlement pré-configurés
- ✅ Récupérer automatiquement les emails depuis Active Directory (LDAP)
- ✅ Générer des fichiers JSON conformes aux spécifications WSO
- ✅ Envoyer les fichiers d'enrôlement vers un partage Samba/SMB
- ✅ Gérer plusieurs machines en lot
- ✅ Mode test pour validation sans envoi réel

L'application simplifie considérablement le processus d'enrôlement qui nécessiterait normalement de nombreuses étapes manuelles, réduisant les erreurs et accélérant le déploiement.

---

## ✨ Fonctionnalités

### Gestion des Machines

- **Ajout de machines** : Interface intuitive pour saisir les informations d'enrôlement
- **Édition** : Modification des machines avant envoi
- **Suppression** : Retrait individuel ou en lot
- **Tri et recherche** : Organisation facile des machines en attente
- **Persistance** : Sauvegarde automatique avec Core Data

### Intégration Active Directory

- **Recherche LDAP** : Récupération automatique des emails utilisateur
- **Configuration flexible** : Support de différents serveurs LDAP
- **Authentification sécurisée** : Credentials stockés dans le Keychain

### Profils d'Enrôlement

- **Organisation Groups** : Définition de groupes organisationnels WSO
- **Enrollment Profiles** : Configuration de profils d'enrôlement personnalisés
- **Préfixes de noms** : Génération automatique de noms de machines cohérents
- **Validation** : Vérification des données avant envoi

### Upload Automatique

- **Samba/SMB** : Envoi sécurisé vers partage réseau
- **Mode test** : Sauvegarde locale pour validation
- **Authentification biométrique** : Touch ID / Face ID pour sécuriser l'envoi
- **Progression** : Suivi en temps réel de l'upload

---

## 🏗️ Architecture

L'application suit une architecture modulaire avec séparation claire des responsabilités :

```
┌─────────────────────────────────────────┐
│         SwiftUI Views (UI Layer)        │
│   MachineList • AddMachine • Config     │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│          Services (Business Logic)       │
│  CoreData • Keychain • LDAP • Samba     │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│      Models & Persistence (Data)        │
│  Machine • Config • Core Data Stack     │
└─────────────────────────────────────────┘
```

### Principes de conception

- **Singleton Pattern** : Services réutilisables avec instance unique
- **Separation of Concerns** : Chaque fichier a une seule responsabilité
- **SwiftUI MVVM** : Vues réactives avec `@State` et `@Binding`
- **Async/Await** : Opérations asynchrones modernes

---

## 📋 Prérequis

### Système

- **macOS** : 13.0 (Ventura) ou supérieur
- **Xcode** : 15.0+ (pour compilation)
- **Swift** : 5.9+

### Réseau & Infrastructure

- **Accès Active Directory** : Serveur LDAP accessible
- **Partage Samba/SMB** : Pour le dépôt des fichiers d'enrôlement
- **Workspace ONE** : Environnement WSO configuré

### Dépendances Swift Packages

L'application utilise les Swift Packages suivants :

- **[KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess)** : Gestion sécurisée du Keychain macOS
- **[SMBClient](https://github.com/kishikawakatsumi/SMBClient)** : Client Swift pour connexions Samba/SMB

---

## 🚀 Installation

### 1. Cloner le Dépôt

```bash
git clone https://github.com/votre-organisation/enroll-macs-wso.git
cd enroll-macs-wso
```

### 2. Ouvrir dans Xcode

```bash
open "Enroll Macs WSO.xcodeproj"
```

### 3. Installer les Dépendances

Xcode devrait automatiquement télécharger les Swift Packages via SPM (Swift Package Manager).

Si nécessaire, ajoutez-les manuellement :

1. **File** → **Add Packages...**
2. Ajoutez les packages suivants :

   **KeychainAccess** :
   - URL : `https://github.com/kishikawakatsumi/KeychainAccess`
   - Version : `4.2.2` ou supérieure

   **SMBClient** :
   - URL : `https://github.com/kishikawakatsumi/SMBClient`
   - Version : Dernière version disponible

### 4. Configurer le Signing

1. Sélectionnez le projet dans Xcode
2. Sous **Signing & Capabilities**, configurez votre équipe de développement
3. Assurez-vous que **Keychain Sharing** est activé pour l'accès au Keychain

### 5. Build & Run

```
Product → Build (⌘B)
Product → Run (⌘R)
```

---

## 💡 Utilisation

### Premier Lancement : Configuration

Au premier lancement, l'application affiche l'écran de configuration :

1. **Paramètres WSO** :
   - Platform ID (ex: `1`)
   - Ownership (ex: `Corporate`)
   - Message Type (ex: `1`)

2. **Connexion Samba** :
   - Chemin du partage (ex: `smb://serveur.domaine.ch/partage/enrollments`)
   - Nom d'utilisateur
   - Mot de passe (stocké de manière sécurisée dans le Keychain via KeychainAccess)

3. **Serveur LDAP** :
   - URL du serveur (ex: `ldap://ad.domaine.ch:3268`)
   - Base DN (ex: `DC=domaine,DC=ch`)

4. **Configuration des Profils** :
   - **Organisation Groups** : Ajoutez vos groupes WSO
   - **Enrollment Profiles** : Définissez vos profils d'enrôlement
   - **Préfixes de Noms** : Configurez les préfixes de noms de machines

Cliquez sur **Enregistrer** pour valider la configuration.

### Ajouter une Machine

1. Cliquez sur **Ajouter une machine**
2. Remplissez les champs :
   - **Username** : Nom d'utilisateur AD
   - **Nom de la machine** : Sélectionnez un préfixe
   - **Numéro d'inventaire** : Asset number (utilisé pour le nom complet)
   - **Numéro de série** : Serial number du Mac
   - **Organisation Group** : Groupe de destination WSO
   - **Enrollment Profile** : Profil d'enrôlement à utiliser
   - **Email** : Utilisez "Load email" pour récupérer automatiquement depuis AD
3. Cliquez sur **Ajouter**

### Envoyer les Machines

1. Sélectionnez une ou plusieurs machines dans la liste
2. Cliquez sur **Envoyer**
3. Authentifiez-vous avec Touch ID / Face ID
4. L'application génère les fichiers JSON et les envoie vers Samba
5. Les machines envoyées avec succès sont automatiquement supprimées de la liste

### Mode Test

Pour tester sans envoyer réellement vers Samba :

```swift
// Dans ConfigManager.swift, activez le mode test :
var isTestMode: Bool = true
```

Les fichiers seront sauvegardés localement dans `~/Downloads/TestStorage/`

---

## ⚙️ Configuration

### Format des Profils (JSON)

#### Organisation Groups

```json
[
  {
    "name": "Département IT",
    "groupId": "IT-DEPT-001"
  },
  {
    "name": "Département RH",
    "groupId": "HR-DEPT-002"
  }
]
```

#### Enrollment Profiles

```json
[
  {
    "name": "Standard macOS"
  },
  {
    "name": "macOS Developer"
  }
]
```

#### Machine Name Prefixes

```json
[
  {
    "prefix": "MAC-IT"
  },
  {
    "prefix": "MAC-RH"
  }
]
```

### Configuration LDAP

L'application utilise `ldapsearch` pour interroger Active Directory :

```bash
ldapsearch -H ldap://ad.domaine.ch:3268 \
  -D "INTRANET\\username" \
  -w "password" \
  -b "DC=domaine,DC=ch" \
  "(sAMAccountName=username)" \
  cn mail
```

**Attributs récupérés** : `cn` (nom complet) et `mail` (email)

### Sécurité Keychain

Les credentials Samba sont stockés dans le Keychain macOS via **KeychainAccess** :

- **Service** : `ch.domaine.EnrollMacsWSO.samba`
- **Accounts** :
  - `sambaUsername`
  - `sambaPassword`

Le framework KeychainAccess offre une API Swift moderne et sécurisée pour gérer les credentials sensibles.

---

## 🔄 Flux de Fonctionnement

### 1. Configuration Initiale

```
Utilisateur → ConfigurationView → CoreDataService.saveConfiguration()
                                 → KeychainService.set() (via KeychainAccess)
```

### 2. Ajout d'une Machine

```
Utilisateur → AddMachineView
    ↓
    ├─→ Button "Load email" → LDAPService.fetchEmail()
    │                         → Process("/usr/bin/ldapsearch")
    │                         → Parse LDAP output
    │                         → email field updated
    ↓
    └─→ Button "Ajouter" → Validation
                         → machines.append()
                         → CoreDataService.saveMachines()
                         → JSON encoding → Core Data
```

### 3. Envoi vers Samba

```
Utilisateur → Sélection machines → Button "Envoyer"
    ↓
LAContext.evaluatePolicy() → Touch ID / Face ID
    ↓
Pour chaque machine:
    ↓
    ├─→ machine.toJSON() → Génération JSON
    │
    └─→ SambaService.saveFile(filename: "{FriendlyName}.json")
        ↓
        ├─→ Si Mode Test:
        │   └─→ FileManager → ~/Downloads/TestStorage/{FriendlyName}.json
        │
        └─→ Sinon:
            ├─→ KeychainService → get credentials (KeychainAccess)
            ├─→ SMBClient.login()
            ├─→ SMBClient.connectShare()
            ├─→ SMBClient.upload(filename.json)
            └─→ SMBClient.disconnectShare()
```

### 4. Format JSON Généré

Pour chaque machine, un fichier JSON individuel est créé avec le nom `{FriendlyName}.json` :

**Exemple : `MAC-IT-12345.json`**

```json
{
  "EndUserName": "jdoe",
  "AssetNumber": "12345",
  "LocationGroupId": "IT-DEPT-001",
  "MessageType": 1,
  "SerialNumber": "C02ABCD1234",
  "PlatformId": 1,
  "FriendlyName": "MAC-IT-12345",
  "Ownership": "Corporate",
  "MailAddress": "jdoe@domaine.ch",
  "MacEnrollmentProfile": "Standard macOS"
}
```

**Champs** :
- `EndUserName` : Nom d'utilisateur Active Directory
- `AssetNumber` : Numéro d'inventaire
- `LocationGroupId` : ID du groupe organisationnel WSO
- `MessageType` : Type de message (configuré dans les paramètres généraux)
- `SerialNumber` : Numéro de série du Mac
- `PlatformId` : ID de la plateforme (configuré dans les paramètres généraux)
- `FriendlyName` : Nom complet de la machine (`{Prefix}-{AssetNumber}`)
- `Ownership` : Type de propriété (configuré dans les paramètres généraux)
- `MailAddress` : Adresse email de l'utilisateur
- `MacEnrollmentProfile` : Profil d'enrôlement sélectionné

**Note** : Chaque machine génère son propre fichier JSON. Si vous envoyez 10 machines, 10 fichiers JSON seront créés sur le partage Samba.

---

## 🛠️ Technologies

### Frameworks Apple

- **SwiftUI** : Interface utilisateur déclarative
- **Core Data** : Persistance des données et configuration
- **LocalAuthentication** : Touch ID / Face ID
- **AppKit** : Interactions système macOS
- **Metal** : Vérification du support graphique

### Swift Packages (Frameworks Tiers)

- **[KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess)** (v4.2.2+)
  - Gestion sécurisée du Keychain macOS
  - API Swift moderne et type-safe
  - Support des items génériques et Internet passwords
  - Auteur : Kishikawa Katsumi

- **[SMBClient](https://github.com/kishikawakatsumi/SMBClient)**
  - Client Swift pour protocole SMB/CIFS
  - Communication avec partages Samba/SMB
  - Support async/await natif
  - Auteur : Kishikawa Katsumi

### Outils Système

- **ldapsearch** : Requêtes LDAP (`/usr/bin/ldapsearch`)
- **Keychain Services** : API système pour stockage sécurisé

### Swift Features

- **Async/Await** : Opérations asynchrones modernes
- **Actors** : Sécurité des données concurrentes
- **Swift Concurrency** : Gestion des tâches asynchrones
- **Codable** : Sérialisation/désérialisation JSON

---

## 📁 Structure du Projet

```
Enroll Macs WSO/
│
├── 📱 App.swift                              # Point d'entrée @main
│
├── 🎨 Views/                                  # Interface SwiftUI
│   ├── ViewsMachineListView.swift            # Liste principale
│   ├── ViewsAddMachineView.swift             # Ajout de machine
│   ├── ViewsDetailsMachineView.swift         # Édition de machine
│   ├── ViewsFormFieldsView.swift             # Formulaire réutilisable
│   └── ViewsConfigurationView.swift          # Configuration app
│
├── 📦 Models/                                 # Modèles de données
│   ├── ModelsMachine.swift                   # Modèle Machine
│   ├── ModelsOrganisationGroup.swift         # Modèle OG
│   ├── ModelsEnrollmentProfile.swift         # Modèle Profile
│   └── ModelsMachineNamePrefix.swift         # Modèle Prefix
│
├── ⚙️ Services/                               # Logique métier
│   ├── ServicesCoreDataService.swift         # Persistance Core Data
│   ├── ServicesKeychainService.swift         # Gestion Keychain (KeychainAccess)
│   ├── ServicesLDAPService.swift             # Requêtes LDAP
│   └── ServicesSambaService.swift            # Upload Samba (SMBClient)
│
├── 🛠 Utilities/                              # Utilitaires
│   ├── UtilitiesExtensions.swift             # Extensions Swift
│   ├── ConfigManager.swift                   # Configuration globale
│   └── Persistence.swift                     # Stack Core Data
│
├── 💾 Core Data/                              # Modèle Core Data
│   ├── EnrollMacsWSO.xcdatamodeld            # Modèle de données
│   ├── CoreDataAppConfig+CoreDataClass.swift
│   └── CoreDataAppConfig+CoreDataProperties.swift
│
└── 📚 Documentation/                          # Documentation projet
    ├── PROJECT_STRUCTURE.md                  # Architecture détaillée
    ├── MIGRATION_GUIDE.md                    # Guide de migration
    └── VISUAL_OVERVIEW.md                    # Vue d'ensemble visuelle
```

---

## 👨‍💻 Développement

### Ajouter une Nouvelle Fonctionnalité

1. **Créer le modèle** (si nécessaire) dans `Models/`
2. **Créer le service** dans `Services/` avec le pattern Singleton
3. **Créer la vue** dans `Views/`
4. **Mettre à jour Core Data** si persistance nécessaire
5. **Tester** en mode test puis en production

### Guidelines de Code

- **Swift Conventions** : Suivre les conventions Apple
- **Nommage** : Descriptif et cohérent (`Verbe + Nom`)
- **Documentation** : Commenter les fonctions complexes
- **MARK** : Utiliser `// MARK: -` pour organiser le code

### Exemple de Service

```swift
import Foundation

class MonNouveauService {
    static let shared = MonNouveauService()
    
    private init() {}
    
    func executerAction(param: String) -> String {
        // Logique métier
        return "Résultat"
    }
}

// Utilisation
let resultat = MonNouveauService.shared.executerAction(param: "test")
```

### Tests

L'application peut être testée avec le nouveau framework **Swift Testing** :

```swift
import Testing

@Suite("Machine Tests")
struct MachineTests {
    
    @Test("Création d'une machine")
    func createMachine() async throws {
        let machine = Machine(
            endUserName: "jdoe",
            assetNumber: "12345",
            locationGroupId: "IT-001",
            messageType: 1,
            serialNumber: "ABC123",
            platformId: 1,
            friendlyName: "MAC-IT-12345",
            ownership: "Corporate",
            Email: "jdoe@example.com",
            macEnrollmentProfile: "Standard"
        )
        
        #expect(machine.friendlyName == "MAC-IT-12345")
        #expect(machine.Email == "jdoe@example.com")
    }
    
    @Test("Génération JSON")
    func generateJSON() async throws {
        let machine = Machine(
            endUserName: "jdoe",
            assetNumber: "12345",
            locationGroupId: "IT-001",
            messageType: 1,
            serialNumber: "ABC123",
            platformId: 1,
            friendlyName: "MAC-IT-12345",
            ownership: "Corporate",
            Email: "jdoe@example.com",
            macEnrollmentProfile: "Standard"
        )
        
        let jsonData = try #require(machine.toJSON())
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        #expect(jsonString?.contains("EndUserName") == true)
        #expect(jsonString?.contains("jdoe") == true)
        #expect(jsonString?.contains("MAC-IT-12345") == true)
    }
}
```

---

## ❓ FAQ

### Comment récupérer les emails depuis LDAP ?

1. Assurez-vous que le serveur LDAP est configuré dans l'app
2. Dans le formulaire d'ajout, saisissez le username
3. Cliquez sur **Load email**
4. L'email est récupéré automatiquement depuis Active Directory

**Résolution des problèmes** :
- Vérifiez que `ldapsearch` est installé : `which ldapsearch`
- Testez la connexion LDAP manuellement
- Vérifiez les credentials dans le Keychain

### L'upload Samba échoue, que faire ?

1. **Vérifiez la configuration** :
   - Chemin Samba correct (`smb://serveur/partage`)
   - Credentials valides dans le Keychain
   - Partage accessible depuis votre Mac

2. **Testez en mode test** :
   - Activez `ConfigManager.isTestMode = true`
   - Les fichiers seront sauvegardés localement dans `~/Downloads/TestStorage/`

3. **Vérifiez les permissions** :
   - Votre compte doit avoir accès en écriture au partage
   - Testez manuellement dans Finder : `⌘K` → `smb://serveur/partage`

### Où sont créés les fichiers JSON ?

En **mode production** :
- Les fichiers sont envoyés vers le partage Samba configuré
- Un fichier par machine : `{FriendlyName}.json`
- Exemple : `MAC-IT-12345.json`, `MAC-RH-67890.json`

En **mode test** :
- Les fichiers sont sauvegardés dans `~/Downloads/TestStorage/`
- Vous pouvez les examiner avant l'envoi réel

### Comment réinitialiser la configuration ?

**Option 1 : Via l'interface**
- Cliquez sur "Editer Config" et re-saisissez toutes les valeurs

**Option 2 : Via Core Data**
```swift
CoreDataService.shared.resetConfiguration()
```

**Option 3 : Supprimer les données**
- Supprimez l'app et réinstallez
- Les données Core Data et Keychain seront effacées

### Où sont stockées les données ?

- **Configuration** : Core Data (`~/Library/Application Support/Enroll Macs WSO/`)
- **Credentials Samba** : Keychain macOS via KeychainAccess
  - Service: `ch.domaine.EnrollMacsWSO.samba`
  - Accounts: `sambaUsername`, `sambaPassword`
- **Machines en attente** : Core Data (JSON dans `AppConfig.machinesJSON`)
- **Fichiers JSON générés** : 
  - Mode production → Partage Samba
  - Mode test → `~/Downloads/TestStorage/`

---

## 📄 Licence

Ce projet est distribué sous licence **MIT**.

```
MIT License

Copyright (c) 2026 Bastian Gardel

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Remerciements

Développé avec ❤️ par **Bastian Gardel** - Mai 2026

### Technologies utilisées

**Frameworks Apple** :
- SwiftUI
- Core Data
- LocalAuthentication
- AppKit

**Swift Packages** :
- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) par Kishikawa Katsumi
- [SMBClient](https://github.com/kishikawakatsumi/SMBClient) par Kishikawa Katsumi

Un grand merci à **Kishikawa Katsumi** pour ses excellents frameworks open-source !

---

## 📞 Contact & Support

Pour toute question, bug report ou demande de fonctionnalité :

- 📧 Email : bastian.gardel@example.com
- 🐛 Issues : [GitHub Issues](https://github.com/votre-organisation/enroll-macs-wso/issues)
- 📖 Documentation : [Wiki](https://github.com/votre-organisation/enroll-macs-wso/wiki)

---

**Version** : 2.0  
**Dernière mise à jour** : 15 mai 2026  
**Statut** : ✅ Production Ready
