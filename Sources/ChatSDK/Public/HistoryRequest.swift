//
//  HistoryRequest.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation


/// Request parameters used to load a portion of dialog history.
public struct HistoryRequest: Hashable, Codable {

    /// Maximum number of items to return.
    public let limit: Int

    /// Optional cursor used to continue history navigation.
    public let cursor: HistoryCursor?

    public init(
        limit: Int = 50,
        cursor: HistoryCursor? = nil
    ) {
        self.limit = max(1, limit)
        self.cursor = cursor
    }
}


/// Cursor pointing to a specific message in history.
public struct HistoryCursor: Hashable, Codable {

    /// Identifier of the reference message.
    public let messageId: String

    /// Direction in which history should be loaded.
    public let direction: MoveDirection

    public init(
        messageId: String,
        direction: MoveDirection = .older
    ) {
        self.messageId = messageId
        self.direction = direction
    }
}


/// Direction used when navigating message history.
public enum MoveDirection: String, Codable {

    /// Load messages older than the cursor.
    case older

    /// Load messages newer than the cursor.
    case newer
}
