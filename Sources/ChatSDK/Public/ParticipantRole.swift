//
//  ParticipantRole.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 20.04.2026.
//

import Foundation


public enum ParticipantRole: String, Codable, CaseIterable {

    /// The highest role in the chat.
    case owner = "ROLE_OWNER"

    /// Administrator role.
    case admin = "ROLE_ADMIN"

    /// Supervisor role.
    case supervisor = "ROLE_SUPERVISOR"

    /// Regular participant of the chat.
    case member = "ROLE_MEMBER"
    
    /// Unspecified role
    case unspecified = "ROLE_UNSPECIFIED"
}


extension ParticipantRole {

    init(rawValueOrDefault value: String) {
        self = ParticipantRole(rawValue: value) ?? .unspecified
    }
}
