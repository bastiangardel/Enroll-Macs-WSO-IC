//
//  CoreDataService.swift
//  Enroll Macs WSO
//
//  Created by Bastian Gardel on 13.05.2026.
//

import Foundation
import CoreData

class CoreDataService {
    static let shared = CoreDataService()
    
    private init() {}
    
    // MARK: - App Configuration
    
    func saveConfiguration(
        platformId: Int,
        ownership: String,
        messageType: Int,
        sambaPath: String,
        ldapServer: String,
        ldapBaseDN: String,
        organisationGroupsJSON: String? = nil,
        enrollmentProfilesJSON: String? = nil,
        machineNamePrefixesJSON: String? = nil
    ) {
        let context = PersistenceController.shared.container.viewContext
        let config = AppConfig(context: context)
        config.platformId = Int32(platformId)
        config.ownership = ownership
        config.messageType = Int32(messageType)
        config.sambaPath = sambaPath
        config.ldapServer = ldapServer
        config.ldapBaseDN = ldapBaseDN
        config.organisationGroupsJSON = organisationGroupsJSON
        config.enrollmentProfiles = enrollmentProfilesJSON
        config.machineNamePrefixesJSON = machineNamePrefixesJSON

        do {
            try context.save()
        } catch {
            print("Erreur lors de la sauvegarde des données dans Core Data: \(error)")
        }
    }
    
    func getAppConfig() -> AppConfig? {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<AppConfig> = AppConfig.fetchRequest()
        return try? context.fetch(request).first
    }
    
    func clearStorage() {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = AppConfig.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("Erreur lors de la suppression des données dans Core Data: \(error)")
        }
        
        KeychainService.shared.clearAll()
    }
    
    // MARK: - Machine Persistence
    
    func saveMachines(_ machines: [Machine]) {
        guard let config = getAppConfig() else { return }
        
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(machines),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            config.machinesJSON = jsonString
            
            let context = PersistenceController.shared.container.viewContext
            do {
                try context.save()
                print("Machines sauvegardées avec succès dans Core Data")
            } catch {
                print("Erreur lors de la sauvegarde des machines: \(error)")
            }
        }
    }
    
    func loadMachines() -> [Machine] {
        guard let config = getAppConfig(),
              let json = config.machinesJSON,
              let data = json.data(using: .utf8) else {
            return []
        }
        
        let decoder = JSONDecoder()
        do {
            let machines = try decoder.decode([Machine].self, from: data)
            print("Machines chargées avec succès depuis Core Data: \(machines.count)")
            return machines
        } catch {
            print("Erreur lors du chargement des machines: \(error)")
            return []
        }
    }
    
    func clearMachines() {
        guard let config = getAppConfig() else { return }
        
        config.machinesJSON = nil
        
        let context = PersistenceController.shared.container.viewContext
        do {
            try context.save()
            print("Liste des machines effacée de Core Data")
        } catch {
            print("Erreur lors de l'effacement des machines: \(error)")
        }
    }
    
    // MARK: - Organisation Groups
    
    func getOrganisationGroups() -> [OrganisationGroup] {
        guard let config = getAppConfig(),
              let json = config.organisationGroupsJSON,
              let data = json.data(using: .utf8),
              let groups = try? JSONDecoder().decode([OrganisationGroup].self, from: data)
        else { return [] }
        return groups
    }
    
    // MARK: - Enrollment Profiles
    
    func getEnrollmentProfiles() -> [EnrollmentProfile] {
        guard let config = getAppConfig(),
              let json = config.enrollmentProfiles,
              let data = json.data(using: .utf8),
              let profiles = try? JSONDecoder().decode([EnrollmentProfile].self, from: data)
        else { return [] }
        return profiles
    }
    
    // MARK: - Machine Name Prefixes
    
    func getMachineNamePrefixes() -> [MachineNamePrefix] {
        guard let config = getAppConfig(),
              let json = config.machineNamePrefixesJSON,
              let data = json.data(using: .utf8),
              let prefixes = try? JSONDecoder().decode([MachineNamePrefix].self, from: data)
        else { return [] }
        return prefixes
    }
}
