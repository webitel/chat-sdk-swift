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

    /// Full quoted message this message replies to, when returned by the server.
    public let reply: MessageReply?

    /// Original source if this message was forwarded, nil otherwise.
    public let forwardOrigin: ForwardOrigin?

    /// Position of the message within its dialog, nil if not provided by the server.
    ///
    /// Compare with `ParticipantState.readUpToSequence` and
    /// `ReceiptEvent` sequences to resolve delivery/read state.
    public let sequence: Int64?

    /// Members this message failed to be delivered to, empty if no failures are known.
    ///
    /// Updated in place on `ReceiptEvent.deliveryFailed`.
    public var deliveryExceptions: [DeliveryException]

    /// Who deleted the message and when, nil if the message is not deleted.
    ///
    /// Deleted messages stay in the history. Updated in place on `MessageEvent.deleted`.
    public var deletion: MessageDeletion?

    public init(
        id: String,
        dialogId: String,
        createdAt: Date,
        editedAt: Date?,
        from: Participant,
        content: MessageContent,
        sendId: String? = nil,
        isOutgoing: Bool,
        reactions: [MessageReaction],
        reply: MessageReply? = nil,
        forwardOrigin: ForwardOrigin? = nil,
        sequence: Int64? = nil,
        deliveryExceptions: [DeliveryException] = [],
        deletion: MessageDeletion? = nil
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
        self.reply = reply
        self.forwardOrigin = forwardOrigin
        self.sequence = sequence
        self.deliveryExceptions = deliveryExceptions
        self.deletion = deletion
    }
}


public extension Message {
    /// Indicates whether the message was edited after creation.
    ///
    /// Always false for deleted messages, since deletion also bumps `editedAt`.
    var isEdited: Bool {
        guard !isDeleted, let editedAt else { return false }
        return editedAt > createdAt
    }

    /// Indicates whether the message was deleted.
    var isDeleted: Bool {
        deletion != nil
    }
}
