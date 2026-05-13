//
//  Enroll_Macs_WSOApp.swift
//  Enroll Macs WSO
//
//  Created by Bastian Gardel on 13.05.2026.
//

import Foundation
import CoreData
import KeychainAccess
import SwiftUI
import SMBClient
import LocalAuthentication
import AppKit
import Cocoa

// MARK: - Outils
prefix func ! (value: Binding<Bool>) -> Binding<Bool> {
    Binding<Bool>(
        get: { !value.wrappedValue },
        set: { value.wrappedValue = !$0 }
    )
}

enum SortOrder {
    case ascending, descending
}

// MARK: - Modèles JSON
struct Machine: Identifiable, Codable {
    let id = UUID()
    var endUserName: String
    var assetNumber: String
    var locationGroupId: String
    var messageType: Int
    var serialNumber: String
    var platformId: Int
    var friendlyName: String
    var ownership: String
    var Email: String
    var macEnrollmentProfile: String
    var friendlyNamePrefix: String

    enum CodingKeys: String, CodingKey {
        case endUserName = "EndUserName"
        case assetNumber = "AssetNumber"
        case locationGroupId = "LocationGroupId"
        case messageType = "MessageType"
        case serialNumber = "SerialNumber"
        case platformId = "PlatformId"
        case friendlyName = "FriendlyName"
        case ownership = "Ownership"
        case Email = "MailAddress"
        case macEnrollmentProfile = "MacEnrollmentProfile"
        case friendlyNamePrefix = "FriendlyNamePrefix"
    }

    func toJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(self)
    }
}

// MARK: - Modèle Organisation Group
struct OrganisationGroup: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var groupId: String
}

// MARK: - Modèle Enrollment Profile
struct EnrollmentProfile: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
}

// MARK: - Keychain Keys
enum KeychainKeys: String {
    case sambaUsername = "SambaUsername"
    case sambaPassword = "SambaPassword"
}

let keychain = Keychain(service: "ch.epfl.Enroll-Macs-WSO-IC")

// MARK: - Core Data Helpers
func saveToCoreData(
    platformId: Int,
    ownership: String,
    messageType: Int,
    sambaPath: String,
    ldapServer: String,
    ldapBaseDN: String,
    organisationGroupsJSON: String? = nil,
    enrollmentProfilesJSON: String? = nil
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

    do {
        try context.save()
    } catch {
        print("Erreur lors de la sauvegarde des données dans Core Data: \(error)")
    }
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

    do {
        try keychain.removeAll()
    } catch let error {
        print("Erreur lors de la suppression des informations du Keychain: \(error)")
    }
}

func getAppConfig() -> AppConfig? {
    let context = PersistenceController.shared.container.viewContext
    let request: NSFetchRequest<AppConfig> = AppConfig.fetchRequest()
    return try? context.fetch(request).first
}

// MARK: - Organisation Groups Helpers
func getOrganisationGroups() -> [OrganisationGroup] {
    guard let config = getAppConfig(),
          let json = config.organisationGroupsJSON,
          let data = json.data(using: .utf8),
          let groups = try? JSONDecoder().decode([OrganisationGroup].self, from: data)
    else { return [] }
    return groups
}

// MARK: - Enrollment Profiles Helpers
func getEnrollmentProfiles() -> [EnrollmentProfile] {
    guard let config = getAppConfig(),
          let json = config.enrollmentProfiles,
          let data = json.data(using: .utf8),
          let profiles = try? JSONDecoder().decode([EnrollmentProfile].self, from: data)
    else { return [] }
    return profiles
}

// MARK: - LDAP Helper
enum LDAPResult {
    case found(String)
    case noMail
    case notFound
    case error
}

func fetchEmailFromLDAP(username: String, completion: @escaping (LDAPResult) -> Void) {
    guard let config = getAppConfig(),
          let ldapServer = config.ldapServer, !ldapServer.isEmpty,
          let ldapBaseDN = config.ldapBaseDN, !ldapBaseDN.isEmpty,
          !username.isEmpty else {
        completion(.error)
        return
    }

    guard let bindPassword = keychain[KeychainKeys.sambaPassword.rawValue],
          let bindUser = keychain[KeychainKeys.sambaUsername.rawValue],
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
            "cn", "mail"
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

            let email = output
                .components(separatedBy: "\n")
                .first(where: { $0.lowercased().hasPrefix("mail:") })
                .map { String($0.dropFirst(5)).trimmingCharacters(in: .whitespaces) }

            if let email = email, !email.isEmpty {
                DispatchQueue.main.async { completion(.found(email)) }
            } else {
                DispatchQueue.main.async { completion(.noMail) }
            }
        } catch {
            DispatchQueue.main.async { completion(.error) }
        }
    }
}

// MARK: - Samba Storage Helper
func saveFileToSamba(filename: String, content: Data, completion: @escaping (Bool, String) -> Void) {
    if ConfigManager.shared.isTestMode {
        let localPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads/TestStorage")
        let fileURL = localPath.appendingPathComponent(filename)

        do {
            try FileManager.default.createDirectory(at: localPath, withIntermediateDirectories: true, attributes: nil)
            try content.write(to: fileURL)
            completion(true, "Fichier enregistré localement dans \(fileURL.path)")
        } catch {
            completion(false, "Erreur lors de l'enregistrement local : \(error.localizedDescription)")
        }
    } else {
        guard let config = getAppConfig(),
              let sambaUsername = keychain[KeychainKeys.sambaUsername.rawValue],
              let sambaPassword = keychain[KeychainKeys.sambaPassword.rawValue],
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

// MARK: - Vue principale
struct MachineListView: View {
    @AppStorage("isConfigured") private var isConfigured: Bool = false
    @State private var machines: [Machine] = []

    @State private var statusMessage: String = ""
    @State private var showAddMachineView = false
    @State private var showDetailsMachine = false
    @State private var selectedMachines: Set<UUID> = []
    @State private var isEditing: Bool = false
    @State private var isAuthenticated = false
    @State private var isProcessing: Bool = false
    @State private var progress: Double = 0.0

    @State private var sortOrder: SortOrder = .ascending
    @State private var sortKey: String = "friendlyName"

    @State private var isTestMode: Bool = ConfigManager.shared.isTestMode

    var body: some View {
        Text("")
            .navigationTitle(ConfigManager.shared.isTestMode ? "TEST - Affectation des machines dans WSO" : "Affectation des machines dans WSO")
            .onAppear {
                isTestMode = ConfigManager.shared.isTestMode
                print(isTestMode)
            }
        VStack {
            if isProcessing {
                VStack {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .controlSize(.large)
                        .padding()
                    Text("Progression : \(Int(progress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
            }

            Spacer()
                .frame(height: 20)

            // Titre des colonnes
            HStack {
                Spacer()
                    .frame(width: 20)
                HStack(spacing: 4) {
                    Text("Friendly Name")
                        .font(.headline)
                    if sortKey == "friendlyName" {
                        Image(systemName: sortOrder == .ascending ? "arrow.down" : "arrow.up")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture { sortMachines(by: "friendlyName") }

                HStack(spacing: 4) {
                    Text("End User Name")
                        .font(.headline)
                    if sortKey == "endUserName" {
                        Image(systemName: sortOrder == .ascending ? "arrow.down" : "arrow.up")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture { sortMachines(by: "endUserName") }

                HStack(spacing: 4) {
                    Text("Asset Number")
                        .font(.headline)
                    if sortKey == "assetNumber" {
                        Image(systemName: sortOrder == .ascending ? "arrow.down" : "arrow.up")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture { sortMachines(by: "assetNumber") }

                HStack(spacing: 4) {
                    Text("Location Group ID")
                        .font(.headline)
                    if sortKey == "locationGroupId" {
                        Image(systemName: sortOrder == .ascending ? "arrow.down" : "arrow.up")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture { sortMachines(by: "locationGroupId") }

                HStack(spacing: 4) {
                    Text("Serial Number")
                        .font(.headline)
                    if sortKey == "serialNumber" {
                        Image(systemName: sortOrder == .ascending ? "arrow.down" : "arrow.up")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture { sortMachines(by: "serialNumber") }
            }
            .padding(.bottom, 5)

            // Liste des machines
            List {
                ForEach(machines) { machine in
                    HStack {
                        Spacer()
                            .frame(width: 20)
                        Text(machine.friendlyName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(machine.endUserName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(machine.assetNumber)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(String(machine.locationGroupId))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(machine.serialNumber)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 5)
                    .background(selectedMachines.contains(machine.id) ? Color.blue.opacity(0.2) : Color.clear)
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        TapGesture(count: 2).onEnded {
                            if selectedMachines.isEmpty {
                                selectedMachines.insert(machine.id)
                            } else if selectedMachines.contains(machine.id) {
                                selectedMachines.filter { $0 != machine.id }.forEach { selectedMachines.remove($0) }
                            } else {
                                selectedMachines.insert(machine.id)
                                selectedMachines.filter { $0 != machine.id }.forEach { selectedMachines.remove($0) }
                            }
                            showDetailsMachine = true
                        }
                    )
                    .onTapGesture {
                        if selectedMachines.contains(machine.id) {
                            selectedMachines.remove(machine.id)
                        } else {
                            selectedMachines.insert(machine.id)
                        }
                    }
                }
                .onDelete(perform: deleteMachines)
                .onAppear {
                    sortMachines(by: sortKey)
                }
            }
            .listStyle(DefaultListStyle())

            Text(statusMessage)
                .foregroundColor(.red)
                .padding()

            // Boutons d'action
            HStack {
                Button("Ajouter une machine") {
                    showAddMachineView = true
                }
                .disabled(isProcessing)

                Button("Editer Machine") {
                    showDetailsMachine = true
                }
                .disabled(selectedMachines.count != 1 || isProcessing)

                Button("Supprimer sélectionnées") {
                    deleteSelectedMachines()
                }
                .disabled(selectedMachines.isEmpty)
                .disabled(isProcessing)

                Button("Supprimer tout") {
                    deleteAllMachines()
                }
                .foregroundColor(.red)
                .disabled(machines.isEmpty)
                .disabled(isProcessing)

                Button("Envoyer") {
                    authenticateUserAndSendMachines()
                }
                .disabled(machines.isEmpty)
                .disabled(isProcessing)

                Button("Editer Config") {
                    isConfigured = false
                }
                .disabled(isProcessing)
                .sheet(isPresented: !$isConfigured) {
                    ConfigurationView(isConfigured: $isConfigured)
                        .frame(minWidth: 900, minHeight: 400)
                }

                Button("Close App") {
                    NSApp.terminate(nil)
                }
                .disabled(isProcessing)
            }
            .padding()
        }
        .sheet(isPresented: $showAddMachineView) {
            AddMachineView { newMachine in
                machines.append(newMachine)
                showStatusMessage("Machine ajoutée avec succès !")
                sortMachines(by: sortKey)
            }
            .frame(minWidth: 800, minHeight: 450)
        }
        .sheet(isPresented: $showDetailsMachine, onDismiss: {
            selectedMachines.removeAll()
        }) {
            if let selectedId = selectedMachines.first,
               let index = machines.firstIndex(where: { $0.id == selectedId }) {
                DetailsMachineView(machine: machines[index]) { updatedMachine in
                    machines[index] = updatedMachine
                    showStatusMessage("Machine mise à jour avec succès !")
                    sortMachines(by: sortKey)
                }
                .frame(minWidth: 800, minHeight: 450)
            }
        }
    }

    func sortMachines(by key: String) {
        if sortKey == key {
            sortOrder = (sortOrder == .ascending) ? .descending : .ascending
        } else {
            sortKey = key
            sortOrder = .ascending
        }

        switch sortKey {
        case "friendlyName":
            machines.sort { sortOrder == .ascending ?
                $0.friendlyName.localizedCaseInsensitiveCompare($1.friendlyName) == .orderedAscending :
                $0.friendlyName.localizedCaseInsensitiveCompare($1.friendlyName) == .orderedDescending }
        case "endUserName":
            machines.sort { sortOrder == .ascending ?
                $0.endUserName.localizedCaseInsensitiveCompare($1.endUserName) == .orderedAscending :
                $0.endUserName.localizedCaseInsensitiveCompare($1.endUserName) == .orderedDescending }
        case "assetNumber":
            machines.sort { sortOrder == .ascending ?
                $0.assetNumber.localizedCaseInsensitiveCompare($1.assetNumber) == .orderedAscending :
                $0.assetNumber.localizedCaseInsensitiveCompare($1.assetNumber) == .orderedDescending }
        case "locationGroupId":
            machines.sort { sortOrder == .ascending ?
                $0.locationGroupId < $1.locationGroupId :
                $0.locationGroupId > $1.locationGroupId }
        case "serialNumber":
            machines.sort { sortOrder == .ascending ?
                $0.serialNumber.localizedCaseInsensitiveCompare($1.serialNumber) == .orderedAscending :
                $0.serialNumber.localizedCaseInsensitiveCompare($1.serialNumber) == .orderedDescending }
        default:
            break
        }
    }

    func showStatusMessage(_ message: String, duration: TimeInterval = 3.0) {
        statusMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if statusMessage == message {
                statusMessage = ""
            }
        }
    }

    func authenticateUserAndSendMachines() {
        let context = LAContext()
        var error: NSError?

        isProcessing = true

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "que vous vous authentifiez pour envoyer les machines") { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        isAuthenticated = true
                        sendMachinesToSamba()
                    } else {
                        showStatusMessage(authenticationError?.localizedDescription ?? "Échec de l'authentification.")
                        isProcessing = false
                    }
                }
            }
        } else {
            showStatusMessage("La biométrie n'est pas disponible sur cet appareil.")
        }
    }

    func sendMachinesToSamba() {
        guard !machines.isEmpty else {
            showStatusMessage("Aucune machine à envoyer.")
            return
        }

        selectedMachines.removeAll()

        isProcessing = true
        progress = 0.0
        let totalMachines = machines.count
        var successfullySent = 0
        var remainingMachines: [Machine] = []

        for (index, machine) in machines.enumerated() {
            if let jsonData = machine.toJSON() {
                let filename = "scx-\(machine.assetNumber).json"
                saveFileToSamba(filename: filename, content: jsonData) { success, message in
                    DispatchQueue.main.async {
                        if success {
                            successfullySent += 1
                        } else {
                            remainingMachines.append(machine)
                        }

                        progress = Double(index + 1) / Double(totalMachines)

                        if index == totalMachines - 1 {
                            isProcessing = false
                            machines = remainingMachines
                            showStatusMessage("\(successfullySent) fichier(s) enregistré(s) sur \(totalMachines).\n \(message)")
                        }
                    }
                }
            } else {
                remainingMachines.append(machine)
            }
        }
    }

    func deleteMachines(at offsets: IndexSet) {
        for index in offsets {
            let machine = machines[index]
            if selectedMachines.contains(machine.id) {
                selectedMachines.remove(machine.id)
            }
        }
        machines.remove(atOffsets: offsets)
    }

    func deleteSelectedMachines() {
        machines.removeAll { machine in
            selectedMachines.contains(machine.id)
        }
        selectedMachines.removeAll()
        showStatusMessage("Machines sélectionnées supprimées.")
    }

    func deleteAllMachines() {
        machines.removeAll()
        selectedMachines.removeAll()
        showStatusMessage("Toutes les machines ont été supprimées.")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ theApplication: NSApplication) -> Bool {
        return true
    }
}

// MARK: - Details machine Sheet

struct DetailsMachineView: View {
    var machine: Machine
    var onSave: (Machine) -> Void

    @Environment(\.dismiss) var dismiss

    @State private var endUserName = ""
    @State private var assetNumber = ""
    @State private var serialNumber = ""
    @State private var locationGroupId = ""
    @State private var email = ""
    @State private var macEnrollmentProfile = ""
    @State private var friendlyNamePrefix = ""
    @State private var isLoadingEmail = false
    @State private var ldapMessage: String = ""

    @State private var organisationGroups: [OrganisationGroup] = []
    @State private var selectedOGId: UUID? = nil
    
    @State private var enrollmentProfiles: [EnrollmentProfile] = []
    @State private var selectedProfileId: UUID? = nil

    private var friendlyName: String { "\(friendlyNamePrefix)-\(assetNumber)" }

    init(machine: Machine, onSave: @escaping (Machine) -> Void) {
        self.machine = machine
        self.onSave = onSave
        _endUserName = State(initialValue: machine.endUserName)
        _assetNumber = State(initialValue: machine.assetNumber)
        _serialNumber = State(initialValue: machine.serialNumber)
        _locationGroupId = State(initialValue: machine.locationGroupId)
        _email = State(initialValue: machine.Email)
        _macEnrollmentProfile = State(initialValue: machine.macEnrollmentProfile)
        _friendlyNamePrefix = State(initialValue: machine.friendlyNamePrefix)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(spacing: 10) {
                requiredField(label: "Username", text: $endUserName)
                requiredField(label: "Préfixe Friendly Name", text: $friendlyNamePrefix)
                requiredField(label: "Numéro d'inventaire", text: $assetNumber)
                requiredField(label: "Numéro de série", text: $serialNumber)

                // Menu Organisation Group
                HStack {
                    Text("Organisation Group")
                        .frame(width: 180, alignment: .leading)
                        .foregroundColor(.primary)
                    Text("*")
                        .foregroundColor(.red)
                    if organisationGroups.isEmpty {
                        Text("Aucun groupe configuré")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Menu {
                            Button("Sélectionner un groupe…") {
                                selectedOGId = nil
                                locationGroupId = ""
                            }
                            Divider()
                            ForEach(organisationGroups) { og in
                                Button("\(og.name)  (\(og.groupId))") {
                                    selectedOGId = og.id
                                    locationGroupId = og.groupId
                                }
                            }
                        } label: {
                            HStack {
                                if let selectedId = selectedOGId,
                                   let selected = organisationGroups.first(where: { $0.id == selectedId }) {
                                    Text("\(selected.name)  (\(selected.groupId))")
                                } else {
                                    Text("Sélectionner un groupe…")
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Spacer()
                }
                
                // Menu Enrollment Profile
                HStack {
                    Text("Enrollment Profile")
                        .frame(width: 180, alignment: .leading)
                        .foregroundColor(.primary)
                    Text("*")
                        .foregroundColor(.red)
                    if enrollmentProfiles.isEmpty {
                        Text("Aucun profil configuré")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Menu {
                            Button("Sélectionner un profil…") {
                                selectedProfileId = nil
                                macEnrollmentProfile = ""
                            }
                            Divider()
                            ForEach(enrollmentProfiles) { profile in
                                Button(profile.name) {
                                    selectedProfileId = profile.id
                                    macEnrollmentProfile = profile.name
                                }
                            }
                        } label: {
                            HStack {
                                if let selectedId = selectedProfileId,
                                   let selected = enrollmentProfiles.first(where: { $0.id == selectedId }) {
                                    Text(selected.name)
                                } else {
                                    Text("Sélectionner un profil…")
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Spacer()
                }

                // Email
                HStack {
                    Text("Email")
                        .frame(width: 180, alignment: .leading)
                        .foregroundColor(.primary)
                    Text("*")
                        .foregroundColor(.red)
                    TextField("Entrez l'email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {
                        isLoadingEmail = true
                        ldapMessage = ""
                        fetchEmailFromLDAP(username: endUserName) { result in
                            isLoadingEmail = false
                            switch result {
                            case .found(let mail):
                                email = mail
                                ldapMessage = ""
                            case .noMail:
                                email = ""
                                ldapMessage = "Pas d'email disponible, merci d'en définir un."
                            case .notFound:
                                email = ""
                                ldapMessage = "Le compte n'existe pas dans l'AD."
                            case .error:
                                email = ""
                                ldapMessage = "Erreur lors de la recherche LDAP."
                            }
                        }
                    }) {
                        if isLoadingEmail {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Load email")
                        }
                    }
                    .disabled(endUserName.isEmpty || isLoadingEmail)
                    .frame(width: 90)
                }
                if !ldapMessage.isEmpty {
                    Text(ldapMessage)
                        .foregroundColor(.orange)
                        .font(.body)
                        .padding(.leading, 184)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                Button("Enregistrer") {
                    let updated = Machine(
                        endUserName: endUserName,
                        assetNumber: assetNumber,
                        locationGroupId: locationGroupId,
                        messageType: machine.messageType,
                        serialNumber: serialNumber,
                        platformId: machine.platformId,
                        friendlyName: friendlyName,
                        ownership: machine.ownership,
                        Email: email,
                        macEnrollmentProfile: macEnrollmentProfile,
                        friendlyNamePrefix: friendlyNamePrefix
                    )
                    onSave(updated)
                    dismiss()
                }
                .disabled(
                    endUserName.isEmpty ||
                    friendlyNamePrefix.isEmpty ||
                    locationGroupId.isEmpty ||
                    assetNumber.isEmpty ||
                    serialNumber.isEmpty ||
                    email.isEmpty ||
                    macEnrollmentProfile.isEmpty
                )
                .buttonStyle(.borderedProminent)

                Button("Annuler") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .padding(.top)
        .onAppear {
            organisationGroups = getOrganisationGroups()
            enrollmentProfiles = getEnrollmentProfiles()
            
            // Pré-sélectionner l'OG correspondant au locationGroupId courant
            if let matching = organisationGroups.first(where: { $0.groupId == machine.locationGroupId }) {
                selectedOGId = matching.id
            }
            
            // Pré-sélectionner le profil correspondant
            if let matching = enrollmentProfiles.first(where: { $0.name == machine.macEnrollmentProfile }) {
                selectedProfileId = matching.id
            }
        }
    }

    @ViewBuilder
    private func requiredField(label: String, text: Binding<String>) -> some View {
        HStack {
            Text("\(label) ")
                .frame(width: 180, alignment: .leading)
                .foregroundColor(.primary)
            Text("*")
                .foregroundColor(.red)
            TextField("Entrez le \(label.lowercased())", text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct InfoSectionView: View {
    var title: String
    var content: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.bottom, 5)

            ForEach(content, id: \.0) { label, value in
                HStack {
                    Text("\(label) :")
                        .bold()
                        .frame(width: 150, alignment: .leading)
                    Text(value)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

// MARK: - Vue pour ajouter une machine
struct AddMachineView: View {
    @Environment(\.dismiss) var dismiss
    var onAdd: (Machine) -> Void

    @State private var endUserName = ""
    @State private var assetNumber = ""
    @State private var serialNumber = ""
    @State private var locationGroupId = ""
    @State private var email = ""
    @State private var macEnrollmentProfile = ""
    @State private var friendlyNamePrefix = ""
    @State private var isLoadingEmail = false
    @State private var ldapMessage: String = ""

    @State private var organisationGroups: [OrganisationGroup] = []
    @State private var selectedOGId: UUID? = nil
    
    @State private var enrollmentProfiles: [EnrollmentProfile] = []
    @State private var selectedProfileId: UUID? = nil

    private var friendlyName: String { "\(friendlyNamePrefix)-\(assetNumber)" }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(spacing: 10) {
                requiredField(label: "Username", text: $endUserName)
                requiredField(label: "Préfixe du nom de la machine", text: $friendlyNamePrefix)
                requiredField(label: "Numéro d'inventaire", text: $assetNumber)
                requiredField(label: "Numéro de série", text: $serialNumber)

                // Menu Organisation Group
                HStack {
                    Text("Organisation Group")
                        .frame(width: 180, alignment: .leading)
                        .foregroundColor(.primary)
                    Text("*")
                        .foregroundColor(.red)
                    if organisationGroups.isEmpty {
                        Text("Aucun groupe configuré")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Menu {
                            Button("Sélectionner l'OG de destination") {
                                selectedOGId = nil
                                locationGroupId = ""
                            }
                            Divider()
                            ForEach(organisationGroups) { og in
                                Button("\(og.name)  (\(og.groupId))") {
                                    selectedOGId = og.id
                                    locationGroupId = og.groupId
                                }
                            }
                        } label: {
                            HStack {
                                if let selectedId = selectedOGId,
                                   let selected = organisationGroups.first(where: { $0.id == selectedId }) {
                                    Text("\(selected.name)  (\(selected.groupId))")
                                } else {
                                    Text("Sélectionner l'OG de destination")
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Spacer()
                }
                
                // Menu Enrollment Profile
                HStack {
                    Text("Enrollment Profile")
                        .frame(width: 180, alignment: .leading)
                        .foregroundColor(.primary)
                    Text("*")
                        .foregroundColor(.red)
                    if enrollmentProfiles.isEmpty {
                        Text("Aucun profil configuré")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Menu {
                            Button("Sélectionner un profil d'enrollement") {
                                selectedProfileId = nil
                                macEnrollmentProfile = ""
                            }
                            Divider()
                            ForEach(enrollmentProfiles) { profile in
                                Button(profile.name) {
                                    selectedProfileId = profile.id
                                    macEnrollmentProfile = profile.name
                                }
                            }
                        } label: {
                            HStack {
                                if let selectedId = selectedProfileId,
                                   let selected = enrollmentProfiles.first(where: { $0.id == selectedId }) {
                                    Text(selected.name)
                                } else {
                                    Text("Sélectionner un profil d'enrollement")
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Spacer()
                }

                // Email
                HStack {
                    Text("Email")
                        .frame(width: 180, alignment: .leading)
                        .foregroundColor(.primary)
                    Text("*")
                        .foregroundColor(.red)
                    TextField("Entrez l'email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {
                        isLoadingEmail = true
                        ldapMessage = ""
                        fetchEmailFromLDAP(username: endUserName) { result in
                            isLoadingEmail = false
                            switch result {
                            case .found(let mail):
                                email = mail
                                ldapMessage = ""
                            case .noMail:
                                email = ""
                                ldapMessage = "Pas d'email disponible, merci d'en définir un."
                            case .notFound:
                                email = ""
                                ldapMessage = "Le compte n'existe pas dans l'AD."
                            case .error:
                                email = ""
                                ldapMessage = "Erreur lors de la recherche LDAP."
                            }
                        }
                    }) {
                        if isLoadingEmail {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Load email")
                        }
                    }
                    .disabled(endUserName.isEmpty || isLoadingEmail)
                    .frame(width: 90)
                }
                if !ldapMessage.isEmpty {
                    Text(ldapMessage)
                        .foregroundColor(.orange)
                        .font(.body)
                        .padding(.leading, 184)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                Button("Ajouter") {
                    let config = getAppConfig()
                    let newMachine = Machine(
                        endUserName: endUserName,
                        assetNumber: assetNumber,
                        locationGroupId: locationGroupId,
                        messageType: Int(config?.messageType ?? 0),
                        serialNumber: serialNumber,
                        platformId: Int(config?.platformId ?? 0),
                        friendlyName: friendlyName,
                        ownership: config?.ownership ?? "",
                        Email: email,
                        macEnrollmentProfile: macEnrollmentProfile,
                        friendlyNamePrefix: friendlyNamePrefix
                    )
                    onAdd(newMachine)
                    dismiss()
                }
                .disabled(
                    endUserName.isEmpty ||
                    friendlyNamePrefix.isEmpty ||
                    locationGroupId.isEmpty ||
                    assetNumber.isEmpty ||
                    serialNumber.isEmpty ||
                    email.isEmpty ||
                    macEnrollmentProfile.isEmpty
                )
                .buttonStyle(.borderedProminent)

                Button("Annuler") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .padding(.top)
        .onAppear {
            organisationGroups = getOrganisationGroups()
            enrollmentProfiles = getEnrollmentProfiles()
        }
    }

    @ViewBuilder
    private func requiredField(label: String, text: Binding<String>) -> some View {
        HStack {
            Text("\(label) ")
                .frame(width: 180, alignment: .leading)
                .foregroundColor(.primary)
            Text("*")
                .foregroundColor(.red)
            TextField("Entrez le \(label.lowercased())", text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

/// Vue pour une sélection multiple
struct MultipleSelectionView: View {
    let title: String
    let options: [String]
    @Binding var selections: [String]

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline)
            ForEach(options, id: \.self) { option in
                Toggle(option, isOn: Binding(
                    get: { selections.contains(option) },
                    set: { newValue in
                        if newValue {
                            selections.append(option)
                        } else {
                            selections.removeAll { $0 == option }
                        }
                    }
                ))
            }
        }
        .padding()
        .border(Color.gray, width: 1)
    }
}

// MARK: - Configuration Vue
struct ConfigurationView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isConfigured: Bool
    @State private var showAlert = false
    @State private var pID = ""
    @State private var OShip = ""
    @State private var MT = ""
    @State private var sPath = ""
    @State private var sUsername = ""
    @State private var sPassword = ""
    @State private var ldapServer = ""
    @State private var ldapBaseDN = ""

    // Organisation Groups
    @State private var organisationGroups: [OrganisationGroup] = []
    @State private var newOGName: String = ""
    @State private var newOGGroupId: String = ""
    
    // Enrollment Profiles
    @State private var enrollmentProfiles: [EnrollmentProfile] = []
    @State private var newProfileName: String = ""

    private var canSave: Bool {
        !pID.isEmpty && !OShip.isEmpty && !MT.isEmpty && !sPath.isEmpty && !organisationGroups.isEmpty && !enrollmentProfiles.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // --- Paramètres généraux ---
                Group {
                    HStack {
                        Text("Platform ID:")
                            .frame(width: 200, alignment: .leading)
                        TextField("Entrez le Platform ID", text: $pID)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    HStack {
                        Text("Ownership:")
                            .frame(width: 200, alignment: .leading)
                        TextField("Entrez l'Ownership", text: $OShip)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    HStack {
                        Text("Message Type:")
                            .frame(width: 200, alignment: .leading)
                        TextField("Entrez le Message Type", text: $MT)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    HStack {
                        Text("Chemin Samba:")
                            .frame(width: 200, alignment: .leading)
                        TextField("Entrez le chemin Samba", text: $sPath)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    HStack {
                        Text("Nom d'utilisateur Samba:")
                            .frame(width: 200, alignment: .leading)
                        TextField("Entrez le nom d'utilisateur Samba", text: $sUsername)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    HStack {
                        Text("Mot de passe Samba:")
                            .frame(width: 200, alignment: .leading)
                        SecureField("Entrez le mot de passe Samba", text: $sPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    HStack {
                        Text("Serveur LDAP:")
                            .frame(width: 200, alignment: .leading)
                        TextField("Ex: ldap://epfl.ch:3268", text: $ldapServer)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    HStack {
                        Text("Base DN LDAP:")
                            .frame(width: 200, alignment: .leading)
                        TextField("Ex: dc=epfl,dc=ch", text: $ldapBaseDN)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }

                Divider()

                // --- Groupes d'organisation ---
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Groupes d'organisation")
                            .font(.headline)
                        Text("*")
                            .foregroundColor(.red)
                    }

                    if organisationGroups.isEmpty {
                        Text("Au moins un groupe d'organisation est requis.")
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    // En-tête du tableau
                    if !organisationGroups.isEmpty {
                        HStack {
                            Text("Nom")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("ID")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(width: 120, alignment: .leading)
                            Spacer().frame(width: 32)
                        }
                        .padding(.horizontal, 8)

                        Divider()

                        ForEach(organisationGroups) { og in
                            HStack {
                                Text(og.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(og.groupId)
                                    .frame(width: 120, alignment: .leading)
                                    .foregroundColor(.secondary)
                                Button(action: {
                                    organisationGroups.removeAll { $0.id == og.id }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                                .frame(width: 32)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(6)
                        }
                    }

                    // Ligne d'ajout
                    HStack(spacing: 8) {
                        TextField("Nom du groupe", text: $newOGName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("ID (ex: 628)", text: $newOGGroupId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                        Button("Ajouter") {
                            let og = OrganisationGroup(
                                name: newOGName.trimmingCharacters(in: .whitespaces),
                                groupId: newOGGroupId.trimmingCharacters(in: .whitespaces)
                            )
                            organisationGroups.append(og)
                            newOGName = ""
                            newOGGroupId = ""
                        }
                        .disabled(newOGName.trimmingCharacters(in: .whitespaces).isEmpty ||
                                  newOGGroupId.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Divider()
                
                // --- Profils d'enrollment ---
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Profils d'enrollment")
                            .font(.headline)
                        Text("*")
                            .foregroundColor(.red)
                    }

                    if enrollmentProfiles.isEmpty {
                        Text("Au moins un profil d'enrollment est requis.")
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    // En-tête du tableau
                    if !enrollmentProfiles.isEmpty {
                        HStack {
                            Text("Nom du profil")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer().frame(width: 32)
                        }
                        .padding(.horizontal, 8)

                        Divider()

                        ForEach(enrollmentProfiles) { profile in
                            HStack {
                                Text(profile.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button(action: {
                                    enrollmentProfiles.removeAll { $0.id == profile.id }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                                .frame(width: 32)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(6)
                        }
                    }

                    // Ligne d'ajout
                    HStack(spacing: 8) {
                        TextField("Nom du profil", text: $newProfileName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Ajouter") {
                            let profile = EnrollmentProfile(
                                name: newProfileName.trimmingCharacters(in: .whitespaces)
                            )
                            enrollmentProfiles.append(profile)
                            newProfileName = ""
                        }
                        .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Divider()

                // --- Boutons ---
                HStack {
                    Button("Enregistrer") {
                        saveConfiguration()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)

                    Button("Clear Configuration") {
                        clearField()
                    }
                    .foregroundColor(.red)
                    .buttonStyle(.bordered)

                    Button("Close App") {
                        if canSave {
                            saveConfiguration()
                            exit(0)
                        } else {
                            isConfigured = false
                            showAlert = true
                        }
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Confirmer la fermeture"),
                            message: Text("La config est vide ou incomplète (au moins un groupe d'organisation et un profil d'enrollment requis), elle ne sera donc pas enregistrée.\nVoulez-vous vraiment quitter l'application ?"),
                            primaryButton: .destructive(Text("Quitter")) {
                                exit(0)
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
            .padding()
        }
        .onAppear(perform: loadConfiguration)
    }

    func loadConfiguration() {
        if let config = getAppConfig() {
            pID = String(config.platformId)
            OShip = config.ownership ?? ""
            MT = String(config.messageType)
            sPath = config.sambaPath ?? ""
            ldapServer = config.ldapServer ?? ""
            ldapBaseDN = config.ldapBaseDN ?? ""

            // Charger les OGs avant de vider le storage
            if let json = config.organisationGroupsJSON,
               let data = json.data(using: .utf8),
               let groups = try? JSONDecoder().decode([OrganisationGroup].self, from: data) {
                organisationGroups = groups
            }
            
            // Charger les profils d'enrollment
            if let json = config.enrollmentProfiles,
               let data = json.data(using: .utf8),
               let profiles = try? JSONDecoder().decode([EnrollmentProfile].self, from: data) {
                enrollmentProfiles = profiles
            }
        }
        sUsername = keychain[KeychainKeys.sambaUsername.rawValue] ?? ""
        sPassword = keychain[KeychainKeys.sambaPassword.rawValue] ?? ""

        clearStorage()
    }

    func saveConfiguration() {
        let ogJSON: String?
        if let data = try? JSONEncoder().encode(organisationGroups) {
            ogJSON = String(data: data, encoding: .utf8)
        } else {
            ogJSON = nil
        }
        
        let profilesJSON: String?
        if let data = try? JSONEncoder().encode(enrollmentProfiles) {
            profilesJSON = String(data: data, encoding: .utf8)
        } else {
            profilesJSON = nil
        }

        saveToCoreData(
            platformId: Int(pID) ?? 0,
            ownership: OShip,
            messageType: Int(MT) ?? 0,
            sambaPath: sPath,
            ldapServer: ldapServer,
            ldapBaseDN: ldapBaseDN,
            organisationGroupsJSON: ogJSON,
            enrollmentProfilesJSON: profilesJSON
        )
        keychain[KeychainKeys.sambaUsername.rawValue] = sUsername
        keychain[KeychainKeys.sambaPassword.rawValue] = sPassword

        isConfigured = true
    }

    func clearField() {
        pID = ""
        OShip = ""
        MT = ""
        sPath = ""
        sUsername = ""
        sPassword = ""
        ldapServer = ""
        ldapBaseDN = ""
        organisationGroups = []
        newOGName = ""
        newOGGroupId = ""
        enrollmentProfiles = []
        newProfileName = ""
    }
}

// MARK: - Main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let _ = NSApplication.shared.windows.map { $0.tabbingMode = .disallowed }

        guard MTLCreateSystemDefaultDevice() != nil else {
            fatalError("Metal is not supported on this device")
        }
    }
}

@main
struct Enroll_Macs_WSOApp: App {
    @AppStorage("isConfigured") private var isConfigured: Bool = false

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MachineListView()
                .frame(minWidth: 900, minHeight: 400)
        }
        .commandsRemoved()
        .commands {
            AppMenu()
            FileMenu()
            EditMenu()
        }
    }
}

// MARK: - Menus
struct AppMenu: Commands {
    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("À propos de l'application") {
                NSApplication.shared.orderFrontStandardAboutPanel(nil)
            }
        }

        CommandGroup(replacing: .appTermination) {
            Button("Quitter") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

struct FileMenu: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            // Supprime le groupe "Nouveau"
        }

        CommandGroup(after: .newItem) {
            Button("Fermer la fenêtre") {
                if let keyWindow = NSApplication.shared.keyWindow {
                    keyWindow.performClose(nil)
                }
            }
            .keyboardShortcut("w")
        }
    }
}

struct EditMenu: Commands {
    var body: some Commands {
        CommandGroup(replacing: .pasteboard) {
            Button("Couper") {
                NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("x")

            Button("Copier") {
                NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("c")

            Button("Coller") {
                NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("v")
        }
    }
}
