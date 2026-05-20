//
//  FormFieldsView.swift
//  Enroll Macs WSO
//
//  Created by Bastian Gardel on 13.05.2026.
//

import SwiftUI
import AppKit

struct FormFieldsView: View {
    @Binding var endUserName: String
    @Binding var assetNumber: String
    @Binding var serialNumber: String
    @Binding var locationGroupId: String
    @Binding var email: String
    @Binding var sciper: String
    @Binding var macEnrollmentProfile: String
    @Binding var friendlyNamePrefix: String
    @Binding var isLoadingEmail: Bool
    @Binding var ldapMessage: String
    @Binding var organisationGroups: [OrganisationGroup]
    @Binding var selectedOGId: UUID?
    @Binding var enrollmentProfiles: [EnrollmentProfile]
    @Binding var selectedProfileId: UUID?
    @Binding var machineNamePrefixes: [MachineNamePrefix]
    @Binding var selectedPrefixId: UUID?
    @Binding var machineNameSuffixes: [MachineNameSuffix]
    @Binding var selectedSuffixId: UUID?
    @FocusState.Binding var focusedField: Field?
    var onLoadEmail: (() -> Void)?
    
    @State private var lastLoadedUsername: String = ""
    
    enum Field: Hashable {
        case username
        case assetNumber
        case serialNumber
        case email
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Username ")
                    .frame(width: 180, alignment: .leading)
                    .foregroundColor(.primary)
                Text("*")
                    .foregroundColor(.red)
                TextField("Entrez le username", text: $endUserName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .username)
                    .onSubmit {
                        // Charger l'email automatiquement quand on appuie sur Enter
                        if !endUserName.isEmpty && !isLoadingEmail {
                            loadEmailFromLDAP()
                        }
                    }
            }
            .onChange(of: focusedField) { oldValue, newValue in
                // Quand le champ username perd le focus
                if oldValue == .username && newValue != .username {
                    // Charger l'email seulement si le username a changé et n'est pas vide
                    if !endUserName.isEmpty && endUserName != lastLoadedUsername && !isLoadingEmail {
                        loadEmailFromLDAP()
                    }
                }
            }
            .onChange(of: endUserName) { oldValue, newValue in
                // Réinitialiser le message LDAP quand on modifie le username
                if oldValue != newValue {
                    ldapMessage = ""
                }
            }
            
            // Menu Préfixe de nom de machine
            HStack {
                Text("Nom de la machine")
                    .frame(width: 180, alignment: .leading)
                    .foregroundColor(.primary)
                Text("*")
                    .foregroundColor(.red)
                if machineNamePrefixes.isEmpty {
                    Text("Aucun préfixe configuré")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    menuPicker(
                        options: machineNamePrefixes,
                        selectedId: $selectedPrefixId,
                        placeholder: "Sélectionner un préfixe…",
                        displayText: { prefix in
                            let suffix = machineNameSuffixes.first(where: { $0.id == selectedSuffixId })?.suffix ?? ""
                            if assetNumber.isEmpty {
                                return prefix.prefix
                            } else if suffix.isEmpty {
                                return "\(prefix.prefix)-\(assetNumber)"
                            } else {
                                return "\(prefix.prefix)-\(assetNumber)-\(suffix)"
                            }
                        },
                        onSelect: { prefix in
                            selectedPrefixId = prefix.id
                            friendlyNamePrefix = prefix.prefix
                        }
                    )
                }
                Spacer()
            }
            
            requiredField(label: "Numéro d'inventaire", text: $assetNumber, field: .assetNumber)
            
            // Menu Suffixe de nom de machine (optionnel)
            HStack {
                Text("Suffixe (optionnel)")
                    .frame(width: 180, alignment: .leading)
                    .foregroundColor(.primary)
                Text(" ")
                    .foregroundColor(.clear)
                    .frame(width: 8)
                if machineNameSuffixes.isEmpty {
                    Text("Aucun suffixe configuré")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Menu {
                        Button("Aucun suffixe") {
                            selectedSuffixId = nil
                        }
                        Divider()
                        ForEach(machineNameSuffixes) { suffix in
                            Button(suffix.suffix) {
                                selectedSuffixId = suffix.id
                            }
                        }
                    } label: {
                        HStack {
                            if let id = selectedSuffixId,
                               let selected = machineNameSuffixes.first(where: { $0.id == id }) {
                                Text(selected.suffix)
                            } else {
                                Text("Aucun suffixe")
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
            
            requiredField(label: "Numéro de série", text: $serialNumber, field: .serialNumber)

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
                    menuPicker(
                        options: enrollmentProfiles,
                        selectedId: $selectedProfileId,
                        placeholder: "Sélectionner un profil d'enrollement",
                        displayText: { profile in "\(profile.name) (OG: \(profile.organisationGroup.name))" },
                        onSelect: { profile in
                            selectedProfileId = profile.id
                            macEnrollmentProfile = profile.name
                            // Sélectionner automatiquement le groupe d'organisation associé
                            selectedOGId = profile.organisationGroup.id
                            locationGroupId = profile.organisationGroup.groupId
                        }
                    )
                }
                Spacer()
            }
            
            // Menu Organisation Group (maintenant en lecture seule, défini par le profil)
            HStack {
                Text("Organisation Group")
                    .frame(width: 180, alignment: .leading)
                    .foregroundColor(.secondary)
                Text("*")
                    .foregroundColor(.red)
                if organisationGroups.isEmpty {
                    Text("Aucun groupe configuré")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let selectedProfile = enrollmentProfiles.first(where: { $0.id == selectedProfileId }) {
                    HStack {
                        Text("\(selectedProfile.organisationGroup.name)  (\(selectedProfile.organisationGroup.groupId))")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                } else {
                    Text("Sélectionnez d'abord un profil")
                        .foregroundColor(.secondary)
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
                    .focused($focusedField, equals: .email)
                Button(action: loadEmailFromLDAP) {
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
    }
    
    @ViewBuilder
    private func requiredField(label: String, text: Binding<String>, field: Field) -> some View {
        HStack {
            Text("\(label) ")
                .frame(width: 180, alignment: .leading)
                .foregroundColor(.primary)
            Text("*")
                .foregroundColor(.red)
            TextField("Entrez le \(label.lowercased())", text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($focusedField, equals: field)
        }
    }
    
    @ViewBuilder
    private func menuPicker<T: Identifiable>(
        options: [T],
        selectedId: Binding<UUID?>,
        placeholder: String,
        displayText: @escaping (T) -> String,
        onSelect: @escaping (T) -> Void
    ) -> some View {
        Menu {
            Button(placeholder) {
                selectedId.wrappedValue = nil
            }
            Divider()
            ForEach(options) { option in
                Button(displayText(option)) {
                    onSelect(option)
                }
            }
        } label: {
            HStack {
                if let id = selectedId.wrappedValue,
                   let selected = options.first(where: { $0.id as? UUID == id }) {
                    Text(displayText(selected))
                } else {
                    Text(placeholder)
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
    
    private func loadEmailFromLDAP() {
        isLoadingEmail = true
        ldapMessage = ""
        lastLoadedUsername = endUserName
        
        LDAPService.shared.fetchEmail(username: endUserName) { result in
            isLoadingEmail = false
            switch result {
            case .found(let mail):
                email = mail
                ldapMessage = ""
            case .noAttribute:
                email = ""
                ldapMessage = "Pas d'email disponible, merci d'en définir un."
            case .notFound:
                email = ""
                ldapMessage = "Le compte n'existe pas dans l'AD."
            case .error:
                email = ""
                ldapMessage = "Erreur lors de la recherche LDAP."
            }
            // Notifier le parent si un callback est fourni
            onLoadEmail?()
        }
    }
    
    // Méthode pour vérifier si l'email doit être rechargé
    func shouldReloadEmail() -> Bool {
        return !endUserName.isEmpty && endUserName != lastLoadedUsername
    }
}
