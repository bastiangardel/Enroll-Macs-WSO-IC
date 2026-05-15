//
//  SambaService.swift
//  Enroll Macs WSO
//
//  Created by Bastian Gardel on 13.05.2026.
//

import Foundation
import SMBClient

class SambaService {
    static let shared = SambaService()
    
    private init() {}
    
    func saveFile(filename: String, content: Data, completion: @escaping (Bool, String) -> Void) {
        if ConfigManager.shared.isTestMode {
            saveFileLocally(filename: filename, content: content, completion: completion)
        } else {
            saveFileToSamba(filename: filename, content: content, completion: completion)
        }
    }
    
    private func saveFileLocally(filename: String, content: Data, completion: @escaping (Bool, String) -> Void) {
        let localPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads/TestStorage")
        let fileURL = localPath.appendingPathComponent(filename)

        do {
            try FileManager.default.createDirectory(at: localPath, withIntermediateDirectories: true, attributes: nil)
            try content.write(to: fileURL)
            completion(true, "Fichier enregistré localement dans \(fileURL.path)")
        } catch {
            completion(false, "Erreur lors de l'enregistrement local : \(error.localizedDescription)")
        }
    }
    
    private func saveFileToSamba(filename: String, content: Data, completion: @escaping (Bool, String) -> Void) {
        guard let config = CoreDataService.shared.getAppConfig(),
              let sambaUsername = KeychainService.shared.get(key: .sambaUsername),
              let sambaPassword = KeychainService.shared.get(key: .sambaPassword),
              let sambaPath = config.sambaPath else {
            completion(false, "Configuration manquante")
            return
        }

        guard let url = URL(string: sambaPath), let host = url.host else {
            completion(false, "Chemin SMB invalide")
            return
        }

        let client = SMBClient(host: host)

        Task {
            do {
                try await client.login(username: sambaUsername, password: sambaPassword)

                let shareName = url.pathComponents.count > 1 ? url.pathComponents[1] : ""
                guard !shareName.isEmpty else {
                    completion(false, "Nom de partage manquant dans l'URL SMB")
                    return
                }

                try await client.connectShare(shareName)

                let remoteFilePath = url.path.dropFirst(shareName.count + 1)
                try await client.upload(content: content, path: remoteFilePath.appending("/\(filename)"))
                try await client.disconnectShare()

                completion(true, "Fichier enregistré avec succès sur \(sambaPath)")

            } catch {
                completion(false, "Erreur lors de l'envoi du fichier : \(error.localizedDescription)")
            }
        }
    }
}
