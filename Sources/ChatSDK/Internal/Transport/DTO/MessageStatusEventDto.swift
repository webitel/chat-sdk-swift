//
//  MessageStatusEventDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 01.10.2026.
//

import Foundation


internal struct MessageStatusEventDto: Decodable {
    let dialogId: String
    let status: String
    let member: ParticipantDto
    let upToSeq: Int64
    let occurredAt: Int64?
    /// Current user's unread count, present only when the event is about the current user.
    let unreadCount: Int?

    private enum CodingKeys: String, CodingKey {
        case status, member
        case dialogId = "thread_id"
        case upToSeq = "up_to_seq"
        case occurredAt = "occurred_at"
        case unreadCount = "unread_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dialogId = try container.decode(String.self, forKey: .dialogId)
        status = try container.decode(String.self, forKey: .status)
        member = try container.decode(ParticipantDto.self, forKey: .member)

        guard let upToSeq = decodeFlexibleInt64(container, key: .upToSeq) else {
            throw DecodingError.dataCorruptedError(
                forKey: .upToSeq,
                in: container,
                debugDescription: "Invalid sequence format"
            )
        }

        self.upToSeq = upToSeq
        occurredAt = decodeFlexibleInt64(container, key: .occurredAt)
        unreadCount = decodeUnreadCount(container, key: .unreadCount)
    }
}


internal extension MessageStatusEventDto {
    /// Receipt kind for the status, nil for statuses not handled by this SDK version.
    var receiptKind: ReceiptKind? {
        switch status.lowercased() {
        case "read":
            return .read
        case "delivered":
            return .delivered
        default:
            return nil
        }
    }
}
