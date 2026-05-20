//
//  DetailsMachineView.swift
//  Enroll Macs WSO
//
//  Created by Bastian Gardel on 13.05.2026.
//

import SwiftUI

struct DetailsMachineView: View {
    var machine: Machine
    var onSave: (Machine) -> Void

    @Environment(\.dismiss) var dismiss

    @State private var endUserName = ""
    @State private var assetNumber = ""
    @State private var serialNumber = ""
    @State private var locationGroupId = ""
    @State private var email = ""
    @State private var sciper = ""
    @State private var sciperStatus: SciperStatus = .noAttribute
    @State private var macEnrollmentProfile = ""
    @State private var friendlyNamePrefix = ""
    @State private var isLoadingEmail = false
    @State private var ldapMessage: String = ""
    @State private var organisationGroups: [OrganisationGroup] = []
    @State private var selectedOGId: UUID? = nil
    @State private var enrollmentProfiles: [EnrollmentProfile] = []
    @State private var selectedProfileId: UUID? = nil
    @State private var machineNamePrefixes: [MachineNamePrefix] = []
    @State private var selectedPrefixId: UUID? = nil
    @State private var machineNameSuffixes: [MachineNameSuffix] = []
    @State private var selectedSuffixId: UUID? = nil
    @State private var showConfirmation = false
    @State private var shouldLoadEmailBeforeSave = false
    @FocusState private var focusedField: FormFieldsView.Field?

    private var friendlyName: String { 
        let prefix = machineNamePrefixes.first(where: { $0.id == selectedPrefixId })?.prefix ?? friendlyNamePrefix
        let suffix = machineNameSuffixes.first(where: { $0.id == selectedSuffixId })?.suffix ?? ""
        
        if suffix.isEmpty {
            return "\(prefix)-\(assetNumber)"
        } else {
            return "\(prefix)-\(assetNumber)\(suffix)"
        }
    }

    init(machine: Machine, onSave: @escaping (Machine) -> Void) {
        self.machine = machine
        self.onSave = onSave
        _endUserName = State(initialValue: machine.endUserName)
        _assetNumber = State(initialValue: machine.assetNumber)
        _serialNumber = State(initialValue: machine.serialNumber)
        _locationGroupId = State(initialValue: machine.locationGroupId)
        _email = State(initialValue: machine.Email)
        _macEnrollmentProfile = State(initialValue: machine.macEnrollmentProfile)
    }

    var body: some View {
        ZStack {
            // Zone cliquable en arrière-plan pour enlever le focus
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = nil
                }
            
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 10) {
                    FormFieldsView(
                        endUserName: $endUserName,
                        assetNumber: $assetNumber,
                        serialNumber: $serialNumber,
                        locationGroupId: $locationGroupId,
                        email: $email,
                        sciper: $sciper,
                        macEnrollmentProfile: $macEnrollmentProfile,
                        friendlyNamePrefix: $friendlyNamePrefix,
                        isLoadingEmail: $isLoadingEmail,
                        ldapMessage: $ldapMessage,
                        organisationGroups: $organisationGroups,
                        selectedOGId: $selectedOGId,
                        enrollmentProfiles: $enrollmentProfiles,
                        selectedProfileId: $selectedProfileId,
                        machineNamePrefixes: $machineNamePrefixes,
                        selectedPrefixId: $selectedPrefixId,
                        machineNameSuffixes: $machineNameSuffixes,
                        selectedSuffixId: $selectedSuffixId,
                        focusedField: $focusedField,
                        onLoadEmail: {
                            // L'email a été chargé, on peut marquer qu'on n'a plus besoin de le charger
                            shouldLoadEmailBeforeSave = false
                        }
                    )
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                HStack {
                    Button("Enregistrer") {
                        loadSciperAndShowConfirmation()
                    }
                    .disabled(!isFormValid || isLoadingEmail)
                    .buttonStyle(.borderedProminent)

                    Button("Annuler") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showConfirmation) {
            ConfirmationDialogView(
                username: endUserName, email: email,
                sciperStatus: sciperStatus,
                onConfirm: {
                    showConfirmation = false
                    saveMachine()
                },
                onCancel: {
                    showConfirmation = false
                }
            )
        }
        .onAppear {
            loadData()
        }
    }
    
    private var isFormValid: Bool {
        !endUserName.isEmpty &&
        !friendlyNamePrefix.isEmpty &&
        !locationGroupId.isEmpty &&
        !assetNumber.isEmpty &&
        !serialNumber.isEmpty &&
        !email.isEmpty &&
        !macEnrollmentProfile.isEmpty
    }
    
    private func loadData() {
        organisationGroups = CoreDataService.shared.getOrganisationGroups()
        enrollmentProfiles = CoreDataService.shared.getEnrollmentProfiles()
        machineNamePrefixes = CoreDataService.shared.getMachineNamePrefixes()
        machineNameSuffixes = CoreDataService.shared.getMachineNameSuffixes()
        
        // Pré-sélectionner le profil correspondant
        if let matching = enrollmentProfiles.first(where: { $0.name == machine.macEnrollmentProfile }) {
            selectedProfileId = matching.id
            // Sélectionner automatiquement le groupe d'organisation associé au profil
            selectedOGId = matching.organisationGroup.id
            locationGroupId = matching.organisationGroup.groupId
        } else {
            // Fallback : pré-sélectionner l'OG directement si le profil n'est pas trouvé
            if let matching = organisationGroups.first(where: { $0.groupId == machine.locationGroupId }) {
                selectedOGId = matching.id
            }
        }
        
        // Pré-sélectionner le préfixe et le suffixe correspondants
        let components = machine.friendlyName.components(separatedBy: "-")
        if let firstComponent = components.first,
           let matching = machineNamePrefixes.first(where: { $0.prefix == firstComponent }) {
            selectedPrefixId = matching.id
            friendlyNamePrefix = matching.prefix
        }
        
        // Si le nom contient au moins 2 composants (préfixe-numéro[suffixe]), essayer d'extraire le suffixe
        // Le suffixe est maintenant collé au numéro d'inventaire
        if components.count >= 2,
           let assetAndSuffix = components.dropFirst().first {
            // Essayer de trouver un suffixe qui correspond à la fin du composant
            for suffix in machineNameSuffixes {
                if assetAndSuffix.hasSuffix(suffix.suffix) {
                    selectedSuffixId = suffix.id
                    break
                }
            }
        }
    }
    
    private func saveMachine() {
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
            macEnrollmentProfile: macEnrollmentProfile
        )
        onSave(updated)
        dismiss()
    }
    
    private func loadSciperAndShowConfirmation() {
        // D'abord, charger l'email si le username a été modifié
        if endUserName != machine.endUserName {
            isLoadingEmail = true
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
                // Maintenant charger le sciper
                loadSciper()
            }
        } else {
            // Username n'a pas changé, charger directement le sciper
            loadSciper()
        }
    }
    
    private func loadSciper() {
        isLoadingEmail = true
        LDAPService.shared.fetchSciper(username: endUserName) { result in
            isLoadingEmail = false
            switch result {
            case .found(let sciperValue):
                sciper = sciperValue
                sciperStatus = .found(sciperValue)
            case .noAttribute:
                sciper = ""
                sciperStatus = .noAttribute
            case .notFound:
                sciper = ""
                sciperStatus = .notFoundInAD
            case .error:
                sciper = ""
                sciperStatus = .ldapError
            }
            showConfirmation = true
        }
    }
}
