//
//  KeychainService.swift
//  Enroll Macs WSO
//
//  Created by Bastian Gardel on 13.05.2026.
//

import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let serviceName = "ch.epfl.Enroll-Macs-WSO-IC"
    private let sambaCredentialsKey = "SambaCredentials"
    
    private init() {}
    
    // MARK: - Samba Credentials (Compte + Mot de passe combinés)
    
    /// Sauvegarde les identifiants Samba dans une seule entrée du trousseau
    /// - Parameters:
    ///   - username: Le nom d'utilisateur Samba (stocké dans kSecAttrAccount)
    ///   - password: Le mot de passe Samba (stocké dans kSecValueData)
    func saveSambaCredentials(username: String, password: String) {
        // Supprime l'ancienne entrée si elle existe
        deleteSambaCredentials()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: username,
            kSecAttrLabel as String: sambaCredentialsKey,
            kSecValueData as String: password.data(using: .utf8)!,
            kSecAttrComment as String: "Identifiants Samba"
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Erreur lors de la sauvegarde des identifiants Samba: \(status)")
        }
    }
    
    /// Récupère le nom d'utilisateur Samba
    func getSambaUsername() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrLabel as String: sambaCredentialsKey,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let attributes = item as? [String: Any],
              let account = attributes[kSecAttrAccount as String] as? String else {
            return nil
        }
        
        return account
    }
    
    /// Récupère le mot de passe Samba
    func getSambaPassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrLabel as String: sambaCredentialsKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let passwordData = item as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            return nil
        }
        
        return password
    }
    
    /// Supprime les identifiants Samba
    func deleteSambaCredentials() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrLabel as String: sambaCredentialsKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Erreur lors de la suppression des identifiants Samba: \(status)")
        }
    }
    
    /// Supprime toutes les entrées du trousseau pour ce service
    func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Erreur lors de la suppression des informations du Keychain: \(status)")
        }
    }
    
    // MARK: - Debug
    
    /// Fonction de débogage pour afficher les informations de l'entrée Samba dans le trousseau
    func debugSambaCredentials() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrLabel as String: sambaCredentialsKey,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            if let attributes = item as? [String: Any] {
                print("✅ Entrée trouvée dans le trousseau:")
                print("   Service: \(attributes[kSecAttrService as String] ?? "N/A")")
                print("   Label: \(attributes[kSecAttrLabel as String] ?? "N/A")")
                print("   Compte (username): \(attributes[kSecAttrAccount as String] ?? "N/A")")
                print("   Commentaire: \(attributes[kSecAttrComment as String] ?? "N/A")")
                
                if let passwordData = attributes[kSecValueData as String] as? Data,
                   let password = String(data: passwordData, encoding: .utf8) {
                    print("   Mot de passe: ********** (présent, \(password.count) caractères)")
                }
            }
        } else if status == errSecItemNotFound {
            print("❌ Aucune entrée 'SambaCredentials' trouvée dans le trousseau")
        } else {
            print("⚠️ Erreur lors de la recherche: \(status)")
        }
    }
}
