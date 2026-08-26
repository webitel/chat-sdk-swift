//
//  TypingRequest.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 13.08.2026.
//

import Foundation


/// Parameters used when sending a typing indicator.
public struct TypingRequest: Hashable, Codable {

    /// Preview of the text currently being composed.
    public let previewText: String?

    /// How long the typing indicator should remain active, in milliseconds.
    public let timeoutMs: Int?

    public init(
        previewText: String? = nil,
        timeoutMs: Int? = nil
    ) {
        self.previewText = previewText
        self.timeoutMs = timeoutMs
    }
}
