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

    private enum CodingKeys: String, CodingKey {
        case status, member
        case dialogId = "thread_id"
        case upToSeq = "up_to_seq"
        case occurredAt = "occurred_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dialogId = try container.decode(String.self, forKey: .dialogId)
        status = try container.decode(String.self, forKey: .status)
        member = try container.decode(ParticipantDto.self, forKey: .member)

        guard let upToSeq = Self.decodeInt64(container, key: .upToSeq) else {
            throw DecodingError.dataCorruptedError(
                forKey: .upToSeq,
                in: container,
                debugDescription: "Invalid sequence format"
            )
        }

        self.upToSeq = upToSeq
        occurredAt = Self.decodeInt64(container, key: .occurredAt)
    }

    private static func decodeInt64(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> Int64? {

        if let intValue = try? container.decode(Int64.self, forKey: key) {
            return intValue
        }

        if let stringValue = try? container.decode(String.self, forKey: key) {
            return Int64(stringValue)
        }

        return nil
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
