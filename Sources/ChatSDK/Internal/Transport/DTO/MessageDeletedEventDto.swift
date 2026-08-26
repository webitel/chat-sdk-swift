//
//  MessageDeletedEventDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 26.08.2026.
//

import Foundation


internal struct MessageDeletedEventDto: Decodable {
    let messageId: String
    let dialogId: String
    let deletedBy: ParticipantDto
    let deletedAt: Int64

    private enum CodingKeys: String, CodingKey {
        case messageId = "id"
        case dialogId = "thread_id"
        case deletedBy = "deleted_by"
        case deletedAt = "deleted_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        messageId = try container.decode(String.self, forKey: .messageId)
        dialogId = try container.decode(String.self, forKey: .dialogId)
        deletedBy = try container.decode(ParticipantDto.self, forKey: .deletedBy)
        deletedAt = try Self.decodeTimestamp(container, key: .deletedAt)
    }

    private static func decodeTimestamp(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) throws -> Int64 {

        if let intValue = try? container.decode(Int64.self, forKey: key) {
            return intValue
        }

        if let stringValue = try? container.decode(String.self, forKey: key),
           let intValue = Int64(stringValue) {
            return intValue
        }

        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: container,
            debugDescription: "Invalid timestamp format"
        )
    }
}


internal extension MessageDeletedEventDto {
    func toDomain() -> MessageDeletion {
        MessageDeletion(
            messageId: messageId,
            deletedBy: deletedBy.toDomain(),
            deletedAt: Date(timeIntervalSince1970: Double(deletedAt) / 1000.0)
        )
    }
}
