//
//  MessageOptions.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 20.03.2026.
//

import Foundation


/// Options used when sending a message.
public struct MessageOptions: Hashable, Codable {

    /// Text content of the message.
    public let text: String?

    /// Client-generated identifier used to match sent messages.
    public let sendId: String

    public init(
        text: String?,
        sendId: String = UUID().uuidString
    ) throws {
        guard let text, !text.isEmpty else {
            throw ChatError.emptyMessage
        }

        self.text = text
        self.sendId = sendId
    }
}

