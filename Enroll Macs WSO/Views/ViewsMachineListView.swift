//
//  MachineListView.swift
//  Enroll Macs WSO
//
//  Created by Bastian Gardel on 13.05.2026.
//

import SwiftUI
import LocalAuthentication

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
                
                if machines.isEmpty {
                    machines = CoreDataService.shared.loadMachines()
                    if !machines.isEmpty {
                        sortMachines(by: sortKey)
                        showStatusMessage("\(machines.count) machine(s) chargée(s) depuis la dernière session")
                    }
                }
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

            machineTableView
            
            Text(statusMessage)
                .foregroundColor(.red)
                .padding(.horizontal)
                .padding(.vertical, 4)

            actionButtons
        }
        .sheet(isPresented: $showAddMachineView) {
            AddMachineView { newMachine in
                machines.append(newMachine)
                CoreDataService.shared.saveMachines(machines)
                showStatusMessage("Machine ajoutée avec succès !")
                sortMachines(by: sortKey)
            }
            .frame(minWidth: 750, idealHeight: 380, maxHeight: 450)
        }
        .sheet(isPresented: $showDetailsMachine, onDismiss: {
            selectedMachines.removeAll()
        }) {
            if let selectedId = selectedMachines.first,
               let index = machines.firstIndex(where: { $0.id == selectedId }) {
                DetailsMachineView(machine: machines[index]) { updatedMachine in
                    machines[index] = updatedMachine
                    CoreDataService.shared.saveMachines(machines)
                    showStatusMessage("Machine mise à jour avec succès !")
                    sortMachines(by: sortKey)
                }
                .frame(minWidth: 750, idealHeight: 380, maxHeight: 450)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var machineTableView: some View {
        VStack(spacing: 0) {
            tableHeader
            Divider().background(Color.gray.opacity(0.5))
            tableRows
        }
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(6)
        .padding(.horizontal, 8)
    }
    
    private var tableHeader: some View {
        HStack(spacing: 0) {
            headerColumn(title: "Nom de la machine", width: 180, key: "friendlyName")
            Divider().frame(width: 1, height: 24).background(Color.white.opacity(0.3))
            headerColumn(title: "Username", width: 140, key: "endUserName")
            Divider().frame(width: 1, height: 24).background(Color.white.opacity(0.3))
            headerColumn(title: "Asset Number", width: 120, key: "assetNumber")
            Divider().frame(width: 1, height: 24).background(Color.white.opacity(0.3))
            headerColumn(title: "Organisation Group ID", width: 160, key: "locationGroupId")
            Divider().frame(width: 1, height: 24).background(Color.white.opacity(0.3))
            headerColumn(title: "Serial Number", width: 140, key: "serialNumber")
            Divider().frame(width: 1, height: 24).background(Color.white.opacity(0.3))
            headerColumn(title: "Enrollment Profile", width: 150, key: "macEnrollmentProfile")
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.25), Color.gray.opacity(0.15)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
    }
    
    private func headerColumn(title: String, width: CGFloat, key: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if sortKey == key {
                Image(systemName: sortOrder == .ascending ? "arrow.down" : "arrow.up")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(width: width, alignment: .center)
        .onTapGesture { sortMachines(by: key) }
    }
    
    private var tableRows: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(machines.enumerated()), id: \.element.id) { index, machine in
                    machineRow(machine: machine, index: index)
                    if index < machines.count - 1 {
                        Divider().background(Color.gray.opacity(0.2))
                    }
                }
            }
        }
        .onAppear {
            sortMachines(by: sortKey)
        }
    }
    
    private func machineRow(machine: Machine, index: Int) -> some View {
        HStack(spacing: 0) {
            Text(machine.friendlyName).font(.body).lineLimit(1).truncationMode(.tail).frame(width: 180, alignment: .center)
            Divider().frame(width: 1).background(Color.gray.opacity(0.3))
            Text(machine.endUserName).font(.body).lineLimit(1).truncationMode(.tail).frame(width: 140, alignment: .center)
            Divider().frame(width: 1).background(Color.gray.opacity(0.3))
            Text(machine.assetNumber).font(.body).lineLimit(1).truncationMode(.tail).frame(width: 120, alignment: .center)
            Divider().frame(width: 1).background(Color.gray.opacity(0.3))
            Text(String(machine.locationGroupId)).font(.body).lineLimit(1).truncationMode(.tail).frame(width: 160, alignment: .center)
            Divider().frame(width: 1).background(Color.gray.opacity(0.3))
            Text(machine.serialNumber).font(.body).lineLimit(1).truncationMode(.tail).frame(width: 140, alignment: .center)
            Divider().frame(width: 1).background(Color.gray.opacity(0.3))
            Text(machine.macEnrollmentProfile).font(.body).lineLimit(1).truncationMode(.tail).frame(width: 150, alignment: .center)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            selectedMachines.contains(machine.id)
                ? Color.blue.opacity(0.25)
                : (index % 2 == 0 ? Color(NSColor.textBackgroundColor) : Color.gray.opacity(0.05))
        )
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                handleDoubleTap(machine: machine)
            }
        )
        .onTapGesture {
            toggleSelection(machine: machine)
        }
        .contextMenu {
            Button("Éditer") {
                selectedMachines.removeAll()
                selectedMachines.insert(machine.id)
                showDetailsMachine = true
            }
            Button("Supprimer", role: .destructive) {
                machines.removeAll { $0.id == machine.id }
                CoreDataService.shared.saveMachines(machines)
            }
        }
    }
    
    private var actionButtons: some View {
        HStack {
            Button("Ajouter une machine") { showAddMachineView = true }
                .disabled(isProcessing)

            Button("Editer Machine") { showDetailsMachine = true }
                .disabled(selectedMachines.count != 1 || isProcessing)

            Button("Supprimer sélectionnées") { deleteSelectedMachines() }
                .disabled(selectedMachines.isEmpty || isProcessing)

            Button("Supprimer tout") { deleteAllMachines() }
                .foregroundColor(.red)
                .disabled(machines.isEmpty || isProcessing)

            Button("Envoyer") { authenticateUserAndSendMachines() }
                .disabled(machines.isEmpty || isProcessing)

            Button("Editer Config") { isConfigured = false }
                .disabled(isProcessing)
                .sheet(isPresented: !$isConfigured) {
                    ConfigurationView(isConfigured: $isConfigured)
                        .frame(minWidth: 900, minHeight: 400)
                }

            Button("Close App") { NSApp.terminate(nil) }
                .disabled(isProcessing)
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    
    func handleDoubleTap(machine: Machine) {
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
    
    func toggleSelection(machine: Machine) {
        if selectedMachines.contains(machine.id) {
            selectedMachines.remove(machine.id)
        } else {
            selectedMachines.insert(machine.id)
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
        case "macEnrollmentProfile":
            machines.sort { sortOrder == .ascending ?
                $0.macEnrollmentProfile.localizedCaseInsensitiveCompare($1.macEnrollmentProfile) == .orderedAscending :
                $0.macEnrollmentProfile.localizedCaseInsensitiveCompare($1.macEnrollmentProfile) == .orderedDescending }
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
                let filename = "\(machine.friendlyName).json"
                SambaService.shared.saveFile(filename: filename, content: jsonData) { success, message in
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
                            CoreDataService.shared.saveMachines(machines)
                            
                            if machines.isEmpty {
                                CoreDataService.shared.clearMachines()
                            }
                            
                            showStatusMessage("\(successfullySent) fichier(s) enregistré(s) sur \(totalMachines).\n \(message)")
                        }
                    }
                }
            } else {
                remainingMachines.append(machine)
            }
        }
    }

    func deleteSelectedMachines() {
        machines.removeAll { machine in
            selectedMachines.contains(machine.id)
        }
        selectedMachines.removeAll()
        CoreDataService.shared.saveMachines(machines)
        showStatusMessage("Machines sélectionnées supprimées.")
    }

    func deleteAllMachines() {
        machines.removeAll()
        selectedMachines.removeAll()
        CoreDataService.shared.clearMachines()
        showStatusMessage("Toutes les machines ont été supprimées.")
    }
}
