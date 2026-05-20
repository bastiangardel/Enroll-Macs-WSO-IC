//
//  AddMachineView.swift
//  Enroll Macs WSO
//
//  Created by Bastian Gardel on 13.05.2026.
//

import SwiftUI

struct AddMachineView: View {
    @Environment(\.dismiss) var dismiss
    var onAdd: (Machine) -> Void

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
    @State private var showConfirmation = false
    @FocusState private var focusedField: FormFieldsView.Field?

    private var friendlyName: String { 
        let prefix = machineNamePrefixes.first(where: { $0.id == selectedPrefixId })?.prefix ?? friendlyNamePrefix
        return "\(prefix)-\(assetNumber)" 
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
                        focusedField: $focusedField
                    )
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                HStack {
                    Button("Ajouter") {
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
                    addMachine()
                },
                onCancel: {
                    showConfirmation = false
                }
            )
        }
        .onAppear {
            organisationGroups = CoreDataService.shared.getOrganisationGroups()
            enrollmentProfiles = CoreDataService.shared.getEnrollmentProfiles()
            machineNamePrefixes = CoreDataService.shared.getMachineNamePrefixes()
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
    
    private func addMachine() {
        let config = CoreDataService.shared.getAppConfig()
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
            macEnrollmentProfile: macEnrollmentProfile
        )
        onAdd(newMachine)
        dismiss()
    }
    
    private func loadSciperAndShowConfirmation() {
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
