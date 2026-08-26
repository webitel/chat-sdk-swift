//
//  ReactionResponseDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 17.08.2026.
//

import Foundation


internal struct ReactionResponseDto: Decodable {
    let action: ReactionAction
    let emoji: String?
    let reactedAt: String?

    private enum CodingKeys: String, CodingKey {
        case action
        case emoji
        case reactedAt = "reacted_at"
    }
}


internal extension ReactionResponseDto {
    func toDomain() throws -> ReactionResult {
        let reactedAt = try reactedAt.map { value -> Date in
            guard let millis = Int64(value) else {
                throw ChatError.unknown(
                    code: ChatError.unknownCode,
                    message: "Invalid reacted_at value: \(value)",
                    underlying: nil
                )
            }

            return Date(timeIntervalSince1970: Double(millis) / 1000.0)
        }

        return ReactionResult(
            action: action,
            emoji: emoji,
            reactedAt: reactedAt
        )
    }
}
