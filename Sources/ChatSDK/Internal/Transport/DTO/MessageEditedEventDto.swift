//
//  MessageEditedEventDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 26.08.2026.
//

import Foundation


internal struct MessageEditedEventDto: Decodable {
    let messageId: String
    let dialogId: String
    let editedBy: ParticipantDto
    let body: String
    let createdAt: Int64
    let editedAt: Int64
    let reactions: [MessageReactionDto]
    let replyTo: MessageReplyDto?

    private enum CodingKeys: String, CodingKey {
        case messageId = "id"
        case dialogId = "thread_id"
        case editedBy = "edited_by"
        case body
        case createdAt = "created_at"
        case editedAt = "edited_at"
        case reactions
        case replyTo = "reply_to"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        messageId = try container.decode(String.self, forKey: .messageId)
        dialogId = try container.decode(String.self, forKey: .dialogId)
        editedBy = try container.decode(ParticipantDto.self, forKey: .editedBy)
        body = try container.decode(String.self, forKey: .body)
        createdAt = try Self.decodeTimestamp(container, key: .createdAt)
        editedAt = try Self.decodeTimestamp(container, key: .editedAt)

        reactions = (try? container.decodeIfPresent(
            [MessageReactionDto].self,
            forKey: .reactions
        )) ?? []

        replyTo = try? container.decodeIfPresent(
            MessageReplyDto.self,
            forKey: .replyTo
        )
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


internal extension MessageEditedEventDto {
    func toDomain(_ currentUserId: String?) -> Message {
        let from = editedBy.toDomain()

        return Message(
            id: messageId,
            dialogId: dialogId,
            createdAt: Date(timeIntervalSince1970: Double(createdAt) / 1000.0),
            editedAt: Date(timeIntervalSince1970: Double(editedAt) / 1000.0),
            from: from,
            content: .text(body),
            sendId: nil,
            isOutgoing: currentUserId == from.contact.id.sub,
            reactions: (try? reactions.map { try $0.toDomain() }) ?? [],
            reply: replyTo?.toDomain()
        )
    }
}
