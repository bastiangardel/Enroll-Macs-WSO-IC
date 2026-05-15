//
//  ConfigurationView.swift
//  Enroll Macs WSO
//
//  Created by Bastian Gardel on 13.05.2026.
//

import SwiftUI

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
    @State private var organisationGroups: [OrganisationGroup] = []
    @State private var newOGName: String = ""
    @State private var newOGGroupId: String = ""
    @State private var enrollmentProfiles: [EnrollmentProfile] = []
    @State private var newProfileName: String = ""
    @State private var machineNamePrefixes: [MachineNamePrefix] = []
    @State private var newPrefixName: String = ""

    private var canSave: Bool {
        !pID.isEmpty && !OShip.isEmpty && !MT.isEmpty && !sPath.isEmpty && 
        !organisationGroups.isEmpty && !enrollmentProfiles.isEmpty && !machineNamePrefixes.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    generalSettingsSection
                    Divider()
                    organisationGroupsSection
                    Divider()
                    enrollmentProfilesSection
                    Divider()
                    machineNamePrefixesSection
                }
                .padding()
            }
            
            Divider()
            actionButtons
        }
        .onAppear(perform: loadConfiguration)
    }
    
    // MARK: - Sections
    
    private var generalSettingsSection: some View {
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
    }
    
    private var organisationGroupsSection: some View {
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

            if !organisationGroups.isEmpty {
                tableHeader(columns: [("Nom", nil), ("ID", 120)])
                Divider()
                ForEach(organisationGroups) { og in
                    itemRow(
                        primaryText: og.name,
                        secondaryText: og.groupId,
                        secondaryWidth: 120,
                        onDelete: { organisationGroups.removeAll { $0.id == og.id } }
                    )
                }
            }

            HStack(spacing: 8) {
                TextField("Nom du groupe", text: $newOGName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("ID (ex: 628)", text: $newOGGroupId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 120)
                Button("Ajouter") {
                    addOrganisationGroup()
                }
                .disabled(newOGName.trimmingCharacters(in: .whitespaces).isEmpty ||
                          newOGGroupId.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
    
    private var enrollmentProfilesSection: some View {
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

            if !enrollmentProfiles.isEmpty {
                tableHeader(columns: [("Nom du profil", nil)])
                Divider()
                ForEach(enrollmentProfiles) { profile in
                    itemRow(
                        primaryText: profile.name,
                        onDelete: { enrollmentProfiles.removeAll { $0.id == profile.id } }
                    )
                }
            }

            HStack(spacing: 8) {
                TextField("Nom du profil", text: $newProfileName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Ajouter") {
                    addEnrollmentProfile()
                }
                .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
    
    private var machineNamePrefixesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Préfixes de noms de machines")
                    .font(.headline)
                Text("*")
                    .foregroundColor(.red)
            }

            if machineNamePrefixes.isEmpty {
                Text("Au moins un préfixe est requis.")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            if !machineNamePrefixes.isEmpty {
                tableHeader(columns: [("Préfixe", nil)])
                Divider()
                ForEach(machineNamePrefixes) { prefix in
                    itemRow(
                        primaryText: prefix.prefix,
                        onDelete: { machineNamePrefixes.removeAll { $0.id == prefix.id } }
                    )
                }
            }

            HStack(spacing: 8) {
                TextField("Préfixe (ex: MAC-EPFL)", text: $newPrefixName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Ajouter") {
                    addMachineNamePrefix()
                }
                .disabled(newPrefixName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Enregistrer") {
                    saveConfiguration()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSave)

                Button("Clear Configuration") {
                    clearFields()
                }
                .foregroundColor(.red)
                .buttonStyle(.bordered)

                Button("Close App") {
                    handleCloseApp()
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Confirmer la fermeture"),
                        message: Text("La config est vide ou incomplète (au moins un groupe d'organisation, un profil d'enrollment et un préfixe requis), elle ne sera donc pas enregistrée.\nVoulez-vous vraiment quitter l'application ?"),
                        primaryButton: .destructive(Text("Quitter")) {
                            exit(0)
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func tableHeader(columns: [(String, CGFloat?)]) -> some View {
        HStack {
            ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                Text(column.0)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: column.1 == nil ? .infinity : nil, alignment: .leading)
                    .frame(width: column.1)
            }
            Spacer().frame(width: 32)
        }
        .padding(.horizontal, 8)
    }
    
    @ViewBuilder
    private func itemRow(primaryText: String, secondaryText: String? = nil, secondaryWidth: CGFloat? = nil, onDelete: @escaping () -> Void) -> some View {
        HStack {
            Text(primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let secondaryText = secondaryText {
                Text(secondaryText)
                    .frame(width: secondaryWidth, alignment: .leading)
                    .foregroundColor(.secondary)
            }
            Button(action: onDelete) {
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
    
    // MARK: - Actions
    
    func loadConfiguration() {
        if let config = CoreDataService.shared.getAppConfig() {
            pID = String(config.platformId)
            OShip = config.ownership ?? ""
            MT = String(config.messageType)
            sPath = config.sambaPath ?? ""
            ldapServer = config.ldapServer ?? ""
            ldapBaseDN = config.ldapBaseDN ?? ""

            if let json = config.organisationGroupsJSON,
               let data = json.data(using: .utf8),
               let groups = try? JSONDecoder().decode([OrganisationGroup].self, from: data) {
                organisationGroups = groups
            }
            
            if let json = config.enrollmentProfiles,
               let data = json.data(using: .utf8),
               let profiles = try? JSONDecoder().decode([EnrollmentProfile].self, from: data) {
                enrollmentProfiles = profiles
            }
            
            if let json = config.machineNamePrefixesJSON,
               let data = json.data(using: .utf8),
               let prefixes = try? JSONDecoder().decode([MachineNamePrefix].self, from: data) {
                machineNamePrefixes = prefixes
            }
        }
        
        sUsername = KeychainService.shared.get(key: .sambaUsername) ?? ""
        sPassword = KeychainService.shared.get(key: .sambaPassword) ?? ""

        CoreDataService.shared.clearStorage()
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
        
        let prefixesJSON: String?
        if let data = try? JSONEncoder().encode(machineNamePrefixes) {
            prefixesJSON = String(data: data, encoding: .utf8)
        } else {
            prefixesJSON = nil
        }

        CoreDataService.shared.saveConfiguration(
            platformId: Int(pID) ?? 0,
            ownership: OShip,
            messageType: Int(MT) ?? 0,
            sambaPath: sPath,
            ldapServer: ldapServer,
            ldapBaseDN: ldapBaseDN,
            organisationGroupsJSON: ogJSON,
            enrollmentProfilesJSON: profilesJSON,
            machineNamePrefixesJSON: prefixesJSON
        )
        
        KeychainService.shared.save(key: .sambaUsername, value: sUsername)
        KeychainService.shared.save(key: .sambaPassword, value: sPassword)

        isConfigured = true
    }

    func clearFields() {
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
        machineNamePrefixes = []
        newPrefixName = ""
    }
    
    func handleCloseApp() {
        if canSave {
            saveConfiguration()
            exit(0)
        } else {
            isConfigured = false
            showAlert = true
        }
    }
    
    func addOrganisationGroup() {
        let og = OrganisationGroup(
            name: newOGName.trimmingCharacters(in: .whitespaces),
            groupId: newOGGroupId.trimmingCharacters(in: .whitespaces)
        )
        organisationGroups.append(og)
        newOGName = ""
        newOGGroupId = ""
    }
    
    func addEnrollmentProfile() {
        let profile = EnrollmentProfile(
            name: newProfileName.trimmingCharacters(in: .whitespaces)
        )
        enrollmentProfiles.append(profile)
        newProfileName = ""
    }
    
    func addMachineNamePrefix() {
        let prefix = MachineNamePrefix(
            prefix: newPrefixName.trimmingCharacters(in: .whitespaces)
        )
        machineNamePrefixes.append(prefix)
        newPrefixName = ""
    }
}
