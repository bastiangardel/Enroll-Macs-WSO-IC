# Guide de Migration - Liaison Profils d'Enrollment et Groupes d'Organisation

## 📋 Résumé des Changements

Cette mise à jour modifie la façon dont les profils d'enrollment et les groupes d'organisation interagissent dans l'application. **Chaque profil d'enrollment est maintenant lié à un groupe d'organisation spécifique.**

## 🎯 Nouvelle Logique

### Avant
- Les utilisateurs sélectionnaient **séparément** :
  1. Un profil d'enrollment
  2. Un groupe d'organisation

### Après
- Les utilisateurs sélectionnent **uniquement** :
  1. Un profil d'enrollment (qui contient déjà son groupe d'organisation)
- Le groupe d'organisation est **automatiquement défini** en fonction du profil choisi

## 🔧 Modifications Techniques

### 1. Modèle `EnrollmentProfile`
```swift
struct EnrollmentProfile: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var organisationGroup: OrganisationGroup  // ✨ NOUVEAU
}
```

### 2. Modèle `OrganisationGroup`
```swift
struct OrganisationGroup: Identifiable, Codable, Equatable, Hashable {  // Ajout de Hashable
    var id: UUID = UUID()
    var name: String
    var groupId: String
}
```

### 3. Vue de Configuration
- **Ajout de groupe lors de la création de profil** : Un picker permet de sélectionner le groupe d'organisation associé
- **Protection contre la suppression** : Impossible de supprimer un groupe d'organisation utilisé par un profil
- **Affichage enrichi** : La liste des profils affiche maintenant le groupe associé

### 4. Formulaire d'Ajout/Modification de Machine
- **Ordre inversé** : Le profil d'enrollment se sélectionne en premier
- **Sélection automatique** : Le groupe d'organisation est automatiquement défini
- **Champ en lecture seule** : Le groupe d'organisation ne peut plus être modifié manuellement

## 🔄 Migration Automatique

L'application inclut un système de migration automatique pour gérer les anciennes configurations :

### Fonctionnement
1. **Détection** : L'application détecte si les profils existants n'ont pas de groupe d'organisation
2. **Migration** : Les profils sont automatiquement migrés avec le **premier groupe d'organisation disponible**
3. **Notification** : Un message d'avertissement orange s'affiche dans la vue de configuration
4. **Sauvegarde** : La migration est automatiquement sauvegardée

### Message de Migration
```
⚠️ Migration effectuée
Vos profils d'enrollment ont été automatiquement migrés. 
Vérifiez que le groupe d'organisation associé est correct pour chaque profil.
```

## ✅ Actions Recommandées

### Pour les Utilisateurs Existants
1. **Ouvrir la configuration** (Settings)
2. **Vérifier chaque profil d'enrollment** :
   - Le groupe d'organisation associé est-il correct ?
   - Si non, supprimer le profil et le recréer avec le bon groupe
3. **Sauvegarder** la configuration

### Pour les Nouveaux Utilisateurs
- Rien de spécial ! Créez vos profils normalement en sélectionnant le groupe approprié

## 🛡️ Gestion des Erreurs

### Erreur : "Impossible de charger les profils"
**Cause** : Anciens profils sans groupe d'organisation ET aucun groupe d'organisation configuré  
**Solution** : 
1. Créer au moins un groupe d'organisation
2. Recharger la configuration

### Erreur : "Groupe d'organisation introuvable"
**Cause** : Le groupe lié à un profil a été supprimé manuellement dans la base de données  
**Solution** :
1. Utiliser "Clear Configuration"
2. Reconfigurer l'application

## 📝 Notes pour les Développeurs

### Compatibilité Descendante
La migration est gérée dans deux endroits :
- `ConfigurationView.loadConfiguration()` : Pour la vue de configuration
- `CoreDataService.getEnrollmentProfiles()` : Pour toutes les autres vues

### Structure Legacy
```swift
struct LegacyEnrollmentProfile: Codable {
    var id: UUID
    var name: String
}
```

Cette structure temporaire permet de décoder les anciens profils avant de les convertir.

### Logs de Migration
Les migrations sont loguées dans la console :
```
⚠️ Migration effectuée : 3 profils migrés avec le groupe 'EPFL-IT'
✅ Profils migrés sauvegardés automatiquement
```

## 🎨 Améliorations UX

1. **Clarté** : L'interface indique clairement quelle est la hiérarchie (profil → groupe)
2. **Sécurité** : Impossible de créer des incohérences (profil sans groupe, ou supprimer un groupe utilisé)
3. **Rapidité** : Plus besoin de sélectionner séparément le groupe, c'est automatique
4. **Visibilité** : Le nom du groupe est affiché directement dans le picker de profil

## 🚀 Avantages

- ✅ **Moins d'erreurs** : Impossible de sélectionner un mauvais groupe pour un profil
- ✅ **Plus rapide** : Un seul choix au lieu de deux
- ✅ **Plus clair** : La relation profil-groupe est explicite
- ✅ **Migration douce** : Les anciennes données sont automatiquement migrées

## 📞 Support

En cas de problème, vérifiez :
1. Les logs dans la console Xcode
2. Le message d'avertissement de migration dans la vue de configuration
3. La présence d'au moins un groupe d'organisation configuré

---

*Dernière mise à jour : 20 mai 2026*
