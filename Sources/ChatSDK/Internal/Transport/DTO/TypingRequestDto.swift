//
//  TypingRequestDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 13.08.2026.
//

import Foundation


internal struct TypingRequestDto: Encodable {
    let preview_text: String?
    let timeout_ms: Int?

    init(_ request: TypingRequest) {
        self.preview_text = request.previewText
        self.timeout_ms = request.timeoutMs
    }
}
