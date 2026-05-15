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

    private var friendlyName: String { 
        let prefix = machineNamePrefixes.first(where: { $0.id == selectedPrefixId })?.prefix ?? friendlyNamePrefix
        return "\(prefix)-\(assetNumber)" 
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
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 10) {
                FormFieldsView(
                    endUserName: $endUserName,
                    assetNumber: $assetNumber,
                    serialNumber: $serialNumber,
                    locationGroupId: $locationGroupId,
                    email: $email,
                    macEnrollmentProfile: $macEnrollmentProfile,
                    friendlyNamePrefix: $friendlyNamePrefix,
                    isLoadingEmail: $isLoadingEmail,
                    ldapMessage: $ldapMessage,
                    organisationGroups: $organisationGroups,
                    selectedOGId: $selectedOGId,
                    enrollmentProfiles: $enrollmentProfiles,
                    selectedProfileId: $selectedProfileId,
                    machineNamePrefixes: $machineNamePrefixes,
                    selectedPrefixId: $selectedPrefixId
                )
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            HStack {
                Button("Enregistrer") {
                    saveMachine()
                }
                .disabled(!isFormValid)
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
        
        // Pré-sélectionner l'OG correspondant
        if let matching = organisationGroups.first(where: { $0.groupId == machine.locationGroupId }) {
            selectedOGId = matching.id
        }
        
        // Pré-sélectionner le profil correspondant
        if let matching = enrollmentProfiles.first(where: { $0.name == machine.macEnrollmentProfile }) {
            selectedProfileId = matching.id
        }
        
        // Pré-sélectionner le préfixe correspondant
        let components = machine.friendlyName.components(separatedBy: "-")
        if let firstComponent = components.first,
           let matching = machineNamePrefixes.first(where: { $0.prefix == firstComponent }) {
            selectedPrefixId = matching.id
            friendlyNamePrefix = matching.prefix
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
}
