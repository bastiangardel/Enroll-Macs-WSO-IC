//
//  KeychainService.swift
//  Enroll Macs WSO
//
//  Created by Bastian Gardel on 13.05.2026.
//

import Foundation
import KeychainAccess

enum KeychainKeys: String {
    case sambaUsername = "SambaUsername"
    case sambaPassword = "SambaPassword"
}

class KeychainService {
    static let shared = KeychainService()
    
    private let keychain = Keychain(service: "ch.epfl.Enroll-Macs-WSO-IC")
    
    private init() {}
    
    func save(key: KeychainKeys, value: String) {
        keychain[key.rawValue] = value
    }
    
    func get(key: KeychainKeys) -> String? {
        return keychain[key.rawValue]
    }
    
    func delete(key: KeychainKeys) {
        do {
            try keychain.remove(key.rawValue)
        } catch let error {
            print("Erreur lors de la suppression de \(key.rawValue): \(error)")
        }
    }
    
    func clearAll() {
        do {
            try keychain.removeAll()
        } catch let error {
            print("Erreur lors de la suppression des informations du Keychain: \(error)")
        }
    }
}
