//
//  ForwardMessagesResponseDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 09.09.2026.
//

import Foundation


internal struct ForwardMessagesResponseDto: Decodable {
    let ids: [String]?
    let skipped: [SkippedMessageDto]?
    let threadId: String

    private enum CodingKeys: String, CodingKey {
        case ids
        case skipped
        case threadId = "thread_id"
    }
}


internal extension ForwardMessagesResponseDto {
    func toDomain() -> ForwardMessagesResult {
        ForwardMessagesResult(
            ids: ids ?? [],
            skipped: (skipped ?? []).map { $0.toDomain() },
            threadId: threadId
        )
    }
}
