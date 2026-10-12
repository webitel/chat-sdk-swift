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
    /// Receipt horizon, present for `read` / `delivered` statuses.
    let upToSeq: Int64?
    /// Failed message, present for the `failed` status.
    let messageId: String?
    /// Delivery error, present for the `failed` status.
    let error: DeliveryErrorDto?
    let occurredAt: Int64?
    /// Current user's unread count, present only when the event is about the current user.
    let unreadCount: Int?

    private enum CodingKeys: String, CodingKey {
        case status, member, error
        case dialogId = "thread_id"
        case upToSeq = "up_to_seq"
        case messageId = "message_id"
        case occurredAt = "occurred_at"
        case unreadCount = "unread_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dialogId = try container.decode(String.self, forKey: .dialogId)
        status = try container.decode(String.self, forKey: .status)
        member = try container.decode(ParticipantDto.self, forKey: .member)
        upToSeq = decodeFlexibleInt64(container, key: .upToSeq)
        messageId = try? container.decodeIfPresent(String.self, forKey: .messageId)
        error = try? container.decodeIfPresent(DeliveryErrorDto.self, forKey: .error)
        occurredAt = decodeFlexibleInt64(container, key: .occurredAt)
        unreadCount = decodeUnreadCount(container, key: .unreadCount)
    }
}


internal extension MessageStatusEventDto {
    /// Receipt kind for the status, nil for statuses not handled as receipts.
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

    /// Delivery failure for the `failed` status, nil otherwise or when the payload is incomplete.
    var deliveryException: DeliveryException? {
        guard
            status.lowercased() == "failed",
            let messageId,
            let error
        else {
            return nil
        }

        return DeliveryException(
            messageId: messageId,
            member: member.toDomain(),
            error: error.toDomain()
        )
    }
}
