//
//  MachineNamePrefix.swift
//  Enroll Macs WSO
//
//  Created by Bastian Gardel on 13.05.2026.
//

import Foundation

struct MachineNamePrefix: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var prefix: String
}
