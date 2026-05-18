//
//  ConfirmationDialogView.swift
//  Enroll Macs WSO
//
//  Created by Bastian Gardel on 18.05.2026.
//

import SwiftUI

enum SciperStatus {
    case found(String)
    case notFoundInAD
    case noAttribute
    case ldapError
    
    var displayText: String {
        switch self {
        case .found(let sciper):
            return sciper
        case .notFoundInAD:
            return "Non trouvé dans l'AD"
        case .noAttribute:
            return "Pas de SCIPER configuré"
        case .ldapError:
            return "Erreur de récupération"
        }
    }
    
    var color: Color {
        switch self {
        case .found:
            return .secondary
        case .notFoundInAD:
            return .orange
        case .noAttribute:
            return .orange
        case .ldapError:
            return .red
        }
    }
    
    var icon: String? {
        switch self {
        case .found:
            return "checkmark.circle.fill"
        case .notFoundInAD:
            return "exclamationmark.triangle.fill"
        case .noAttribute:
            return "minus.circle.fill"
        case .ldapError:
            return "xmark.circle.fill"
        }
    }
}

struct ConfirmationDialogView: View {
    let username: String
    let sciperStatus: SciperStatus
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Confirmation")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Username:")
                        .fontWeight(.medium)
                        .frame(width: 100, alignment: .leading)
                    Text(username)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("SCIPER:")
                        .fontWeight(.medium)
                        .frame(width: 100, alignment: .leading)
                    HStack(spacing: 6) {
                        if let icon = sciperStatus.icon {
                            Image(systemName: icon)
                                .font(.caption)
                                .foregroundColor(sciperStatus.color)
                        }
                        Text(sciperStatus.displayText)
                            .foregroundColor(sciperStatus.color)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            HStack(spacing: 12) {
                Button("Annuler") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                
                Button("Valider") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 380)
    }
}
