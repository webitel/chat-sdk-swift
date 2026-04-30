//
//  MessageDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 26.03.2026.
//

import Foundation


internal struct MessageDto: Decodable {

    let id: String
    let dialogId: String
    let createdAt: Int64
    let editedAt: Int64
    let from: ParticipantDto
    let text: String?
    let sendId: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case dialogId = "thread_id"
        case createdAt = "created_at"
        case editedAt = "edited_at"
        case from = "sender"
        case text = "body"
        case sendId = "send_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        dialogId = try container.decode(String.self, forKey: .dialogId)

        createdAt = try Self.decodeTimestamp(container, key: .createdAt)
        editedAt = (try? Self.decodeTimestamp(container, key: .editedAt))
            ?? createdAt

        from = try container.decode(ParticipantDto.self, forKey: .from)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        sendId = try container.decodeIfPresent(String.self, forKey: .sendId)
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


internal extension MessageDto {
    func toDomain(_ currentUserId: String?) -> Message {
        let from = self.from.toDomain()

        let createdDate = Date(timeIntervalSince1970: Double(createdAt) / 1000.0)
        let editedDate = Date(timeIntervalSince1970: Double(editedAt) / 1000.0)
        
        return Message(
            id: id,
            dialogId: dialogId,
            createdAt: createdDate,
            editedAt: editedDate,
            from: from,
            text: text,
            sendId: sendId,
            isOutgoing: currentUserId == from.contact.id.sub
        )
    }
}
