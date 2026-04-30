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

    /// Last edit timestamp
    public let editedAt: Date

    /// Sender of the message
    public let from: Participant

    /// Text content of the message
    ///
    /// May be nil when message contains only attachments
    public let text: String?

    /// Client-generated request ID
    public let sendId: String?

    /// Indicates whether message is outgoing
    public let isOutgoing: Bool

    /// Attachments metadata
    public let attachments: [MessageAttachment]

    public init(
        id: String,
        dialogId: String,
        createdAt: Date,
        editedAt: Date,
        from: Participant,
        text: String?,
        sendId: String? = nil,
        isOutgoing: Bool,
        attachments: [MessageAttachment] = []
    ) {
        self.id = id
        self.dialogId = dialogId
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.from = from
        self.text = text
        self.sendId = sendId
        self.isOutgoing = isOutgoing
        self.attachments = attachments
    }
}


public extension Message {
    /// Indicates whether the message was edited after creation.
    var isEdited: Bool {
        editedAt > createdAt
    }
}
