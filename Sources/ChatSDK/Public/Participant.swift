//
//  Participant.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 14.04.2026.
//

import Foundation


/// Represents a participant in a dialog or conversation.
///
/// A participant wraps a `Contact` with additional context,
/// such as their role within the dialog
public struct Participant: Hashable, Codable {
    
    /// Unique identifier of the participant within the dialog.
    public let id: String
    
    /// Underlying contact information associated with this participant.
    public let contact: Contact
    
    /// Role of the participant in the dialog.
    public let role: ParticipantRole
}
