//
//  MachineNameSuffix.swift
//  Enroll Macs WSO
//
//  Created by Bastian Gardel on 20.05.2026.
//

import Foundation

struct MachineNameSuffix: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var suffix: String
}
