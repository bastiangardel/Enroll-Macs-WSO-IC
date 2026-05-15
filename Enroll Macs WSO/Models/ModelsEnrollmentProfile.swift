//
//  EnrollmentProfile.swift
//  Enroll Macs WSO
//
//  Created by Bastian Gardel on 13.05.2026.
//

import Foundation

struct EnrollmentProfile: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
}
