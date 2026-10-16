//
//  MessageDeletion.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 26.08.2026.
//

import Foundation


/// Who deleted a message and when.
public struct MessageDeletion: Hashable, Codable {

    /// Participant who deleted the message.
    public let deletedBy: Participant

    /// Deletion timestamp.
    public let deletedAt: Date

    public init(deletedBy: Participant, deletedAt: Date) {
        self.deletedBy = deletedBy
        self.deletedAt = deletedAt
    }
}
