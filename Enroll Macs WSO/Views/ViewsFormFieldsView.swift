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
    
    var body: some View {
        VStack(spacing: 10) {
            requiredField(label: "Username", text: $endUserName)
            
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
                            if assetNumber.isEmpty {
                                return prefix.prefix
                            } else {
                                return "\(prefix.prefix)-\(assetNumber)"
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
                    menuPicker(
                        options: organisationGroups,
                        selectedId: $selectedOGId,
                        placeholder: "Sélectionner l'OG de destination",
                        displayText: { og in "\(og.name)  (\(og.groupId))" },
                        onSelect: { og in
                            selectedOGId = og.id
                            locationGroupId = og.groupId
                        }
                    )
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
                    menuPicker(
                        options: enrollmentProfiles,
                        selectedId: $selectedProfileId,
                        placeholder: "Sélectionner un profil d'enrollement",
                        displayText: { profile in profile.name },
                        onSelect: { profile in
                            selectedProfileId = profile.id
                            macEnrollmentProfile = profile.name
                        }
                    )
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
        LDAPService.shared.fetchEmail(username: endUserName) { result in
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
    }
}
