//
//  Message.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation


public struct Message: Hashable, Codable {

    /// Unique message identifier
    public let id: String

    /// Dialog identifier
    public let dialogId: String

    /// Message creation timestamp
    public let createdAt: Date

    /// Last edit timestamp, nil if the message was never edited
    public let editedAt: Date?

    /// Sender of the message
    public let from: Participant

    /// Message content.
    public let content: MessageContent

    /// Client-generated request ID
    public let sendId: String?

    /// Indicates whether message is outgoing
    public let isOutgoing: Bool
    
    /// Current set of reactions on this message.
    public var reactions: [MessageReaction]

    public init(
        id: String,
        dialogId: String,
        createdAt: Date,
        editedAt: Date?,
        from: Participant,
        content: MessageContent,
        sendId: String? = nil,
        isOutgoing: Bool,
        reactions: [MessageReaction]
    ) {
        self.id = id
        self.dialogId = dialogId
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.from = from
        self.content = content
        self.sendId = sendId
        self.isOutgoing = isOutgoing
        self.reactions = reactions
    }
}


public extension Message {
    /// Indicates whether the message was edited after creation.
    var isEdited: Bool {
        editedAt != nil
    }
}
