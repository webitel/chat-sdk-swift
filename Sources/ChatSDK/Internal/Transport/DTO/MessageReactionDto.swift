//
//  MessageReactionDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 18.08.2026.
//

import Foundation


internal struct MessageReactionDto: Decodable {
    let emoji: String
    let count: Int
    let reactedByMe: Bool
    let reactorIds: [String]
    let lastReactedAt: String?

    private enum CodingKeys: String, CodingKey {
        case emoji
        case count
        case reactedByMe = "reacted_by_me"
        case reactorIds = "reactor_ids"
        case lastReactedAt = "last_reacted_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        emoji = try container.decode(String.self, forKey: .emoji)
        count = try container.decode(Int.self, forKey: .count)

        reactedByMe = (try? container.decodeIfPresent(Bool.self, forKey: .reactedByMe)) ?? false
        reactorIds = (try? container.decodeIfPresent([String].self, forKey: .reactorIds)) ?? []
        lastReactedAt = try? container.decodeIfPresent(String.self, forKey: .lastReactedAt)
    }
}


internal extension MessageReactionDto {
    func toDomain() throws -> MessageReaction {
        let lastReactedAt = try lastReactedAt.map { value -> Date in
            guard let millis = Int64(value) else {
                throw ChatError.unknown(
                    code: ChatError.unknownCode,
                    message: "Invalid last_reacted_at value: \(value)",
                    underlying: nil
                )
            }

            return Date(timeIntervalSince1970: Double(millis) / 1000.0)
        }

        return MessageReaction(
            emoji: emoji,
            count: count,
            reactedByMe: reactedByMe,
            reactorIds: reactorIds,
            lastReactedAt: lastReactedAt
        )
    }
}
