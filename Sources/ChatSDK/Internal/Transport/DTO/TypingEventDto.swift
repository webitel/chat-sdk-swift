//
//  TypingEventDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 13.08.2026.
//

import Foundation


internal struct TypingEventDto: Decodable {
    let dialogId: String
    let member: ParticipantDto
    let previewText: String?
    let timeoutMs: Int?

    private enum CodingKeys: String, CodingKey {
        case dialogId = "thread_id"
        case member = "from"
        case previewText = "preview_text"
        case timeoutMs = "timeout_ms"
    }
}
