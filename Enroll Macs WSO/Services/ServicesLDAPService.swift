//
//  LDAPService.swift
//  Enroll Macs WSO
//
//  Created by Bastian Gardel on 13.05.2026.
//

import Foundation

enum LDAPResult {
    case found(String)
    case notFound
    case noAttribute
    case error
}

enum LDAPAttribute: String {
    case email = "mail"
    case sciper = "company"
    
    var ldapFieldName: String {
        return self.rawValue
    }
}

class LDAPService {
    static let shared = LDAPService()
    
    private init() {}
    
    func fetchEmail(username: String, completion: @escaping (LDAPResult) -> Void) {
        fetchLDAPAttribute(.email, for: username, completion: completion)
    }
    
    func fetchSciper(username: String, completion: @escaping (LDAPResult) -> Void) {
        fetchLDAPAttribute(.sciper, for: username, completion: completion)
    }
    
    private func fetchLDAPAttribute(_ attribute: LDAPAttribute, for username: String, completion: @escaping (LDAPResult) -> Void) {
        guard let config = CoreDataService.shared.getAppConfig(),
              let ldapServer = config.ldapServer, !ldapServer.isEmpty,
              let ldapBaseDN = config.ldapBaseDN, !ldapBaseDN.isEmpty,
              !username.isEmpty else {
            completion(.error)
            return
        }

        guard let bindPassword = KeychainService.shared.getSambaPassword(),
              let bindUser = KeychainService.shared.getSambaUsername(),
              !bindPassword.isEmpty, !bindUser.isEmpty else {
            completion(.error)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ldapsearch")
            process.arguments = [
                "-H", ldapServer,
                "-D", "INTRANET\\\(bindUser)",
                "-w", bindPassword,
                "-b", ldapBaseDN,
                "(sAMAccountName=\(username))",
                "cn", attribute.ldapFieldName
            ]

            let pipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = pipe
            process.standardError = errorPipe

            do {
                try process.run()
                process.waitUntilExit()

                let exitCode = process.terminationStatus
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

                let isConnectionOrBindError =
                    exitCode != 0 &&
                    (
                        errorOutput.lowercased().contains("invalid credentials") ||
                        errorOutput.lowercased().contains("ldap_bind") ||
                        errorOutput.lowercased().contains("can't contact ldap server") ||
                        errorOutput.lowercased().contains("connection refused") ||
                        errorOutput.lowercased().contains("timed out") ||
                        errorOutput.lowercased().contains("network is unreachable") ||
                        output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )

                if isConnectionOrBindError {
                    DispatchQueue.main.async { completion(.error) }
                    return
                }

                let hasEntry = output
                    .components(separatedBy: "\n")
                    .contains { $0.lowercased().hasPrefix("dn:") }

                if !hasEntry {
                    DispatchQueue.main.async { completion(.notFound) }
                    return
                }

                let fieldName = attribute.ldapFieldName.lowercased()
                let value = output
                    .components(separatedBy: "\n")
                    .first(where: { $0.lowercased().hasPrefix("\(fieldName):") })
                    .map { String($0.dropFirst(fieldName.count + 1)).trimmingCharacters(in: .whitespaces) }

                if let value = value, !value.isEmpty {
                    DispatchQueue.main.async { completion(.found(value)) }
                } else {
                    DispatchQueue.main.async { completion(.noAttribute) }
                }
            } catch {
                DispatchQueue.main.async { completion(.error) }
            }
        }
    }
}
