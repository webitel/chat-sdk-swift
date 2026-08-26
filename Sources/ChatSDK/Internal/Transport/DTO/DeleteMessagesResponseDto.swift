//
//  DeleteMessagesResponseDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 20.08.2026.
//

import Foundation


internal struct SkippedMessageDto: Decodable {
    let id: String
    let reason: String
}


internal extension SkippedMessageDto {
    func toDomain() -> SkippedMessage {
        SkippedMessage(id: id, reason: SkippedMessageReason.from(reason))
    }
}


internal struct DeleteMessagesResponseDto: Decodable {
    let deletedAt: String?
    let deletedIds: [String]?
    let skipped: [SkippedMessageDto]?

    private enum CodingKeys: String, CodingKey {
        case deletedAt = "deleted_at"
        case deletedIds = "deleted_ids"
        case skipped
    }
}


internal extension DeleteMessagesResponseDto {
    func toDomain() throws -> DeleteMessagesResult {
        let deletedAt = try deletedAt.map { value -> Date in
            guard let millis = Int64(value) else {
                throw ChatError.unknown(
                    code: ChatError.unknownCode,
                    message: "Invalid deleted_at value: \(value)",
                    underlying: nil
                )
            }
            return Date(timeIntervalSince1970: Double(millis) / 1000.0)
        }

        return DeleteMessagesResult(
            deletedAt: deletedAt,
            deletedIds: deletedIds ?? [],
            skipped: (skipped ?? []).map { $0.toDomain() }
        )
    }
}
