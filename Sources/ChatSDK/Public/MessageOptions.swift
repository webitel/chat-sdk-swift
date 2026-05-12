//
//  MessageOptions.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 20.03.2026.
//

import Foundation


/// Options used when sending a message.
public struct MessageOptions {

    /// Text content of the message.
    public var content: SendContent

    /// Client-generated identifier used to match sent messages.
    public let sendId: String

    public init(
        content: SendContent,
        sendId: String = UUID().uuidString
    ) {
        self.content = content
        self.sendId = sendId
    }
}

