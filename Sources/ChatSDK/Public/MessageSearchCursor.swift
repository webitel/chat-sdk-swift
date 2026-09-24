//
//  MessageSearchCursor.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.09.2026.
//

import Foundation


/// Cursor pointing to a specific message in search results.
public struct MessageSearchCursor: Hashable, Codable {

    /// Identifier of the reference message.
    public let messageId: String

    /// Direction in which search results should be loaded.
    public let direction: SearchDirection

    public init(
        messageId: String,
        direction: SearchDirection = .older
    ) {
        self.messageId = messageId
        self.direction = direction
    }
}


/// Direction used when navigating search results.
public enum SearchDirection: String, Codable {

    /// Load results older than the cursor.
    case older

    /// Load results newer than the cursor.
    case newer
}
