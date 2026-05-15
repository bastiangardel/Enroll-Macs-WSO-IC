# Sauvegarde des machines dans Core Data

## Changements effectués

### 1. Nouveaux fichiers créés
- `AppConfig+CoreDataClass.swift` : Classe Core Data pour AppConfig
- `AppConfig+CoreDataProperties.swift` : Propriétés de l'entité AppConfig, incluant le nouveau champ `machinesJSON`

### 2. Nouvelles fonctions ajoutées

#### `saveMachinesToCoreData(_ machines: [Machine])`
Sauvegarde la liste des machines dans Core Data sous forme JSON.
- Appelée automatiquement lors de l'ajout d'une machine
- Appelée automatiquement lors de la modification d'une machine
- Appelée automatiquement lors de la suppression d'une ou plusieurs machines
- Appelée après l'envoi des fichiers pour sauvegarder les machines restantes (en cas d'échec partiel)

#### `loadMachinesFromCoreData() -> [Machine]`
Charge la liste des machines depuis Core Data.
- Appelée automatiquement au démarrage de l'application dans `onAppear`

#### `clearMachinesFromCoreData()`
Efface la liste des machines de Core Data.
- Appelée lorsque toutes les machines sont supprimées
- Appelée lorsque tous les fichiers ont été envoyés avec succès

### 3. Modifications dans MachineListView

#### Dans `onAppear`
```swift
// Charger les machines sauvegardées
if machines.isEmpty {
    machines = loadMachinesFromCoreData()
    if !machines.isEmpty {
        sortMachines(by: sortKey)
        showStatusMessage("\(machines.count) machine(s) chargée(s) depuis la dernière session")
    }
}
```

#### Dans `sendMachinesToSamba()`
- Sauvegarde automatique des machines restantes après envoi
- Effacement automatique si toutes les machines ont été envoyées avec succès

#### Dans `deleteSelectedMachines()`
- Sauvegarde automatique après suppression

#### Dans `deleteAllMachines()`
- Effacement complet de Core Data

#### Dans le menu contextuel
- Sauvegarde automatique après suppression d'une machine via clic droit

## Configuration Core Data requise

Dans le fichier `.xcdatamodeld`, vous devez ajouter un attribut à l'entité `AppConfig` :
- **Nom** : `machinesJSON`
- **Type** : String (Optional)
- **Description** : Stocke la liste des machines sous forme JSON

## Fonctionnement

1. **Au démarrage** : L'application charge automatiquement les machines sauvegardées
2. **Pendant l'utilisation** : Chaque modification (ajout, édition, suppression) est automatiquement sauvegardée
3. **Après l'envoi** : 
   - Si toutes les machines sont envoyées avec succès → la liste est effacée de Core Data
   - Si certaines machines n'ont pas pu être envoyées → elles restent sauvegardées
4. **À la fermeture** : Les machines non envoyées sont conservées pour la prochaine session

## Avantages

✅ Aucune perte de données en cas de fermeture accidentelle de l'application
✅ Possibilité de travailler en plusieurs sessions
✅ Sauvegarde automatique transparente pour l'utilisateur
✅ Les machines envoyées avec succès sont automatiquement retirées de la liste
