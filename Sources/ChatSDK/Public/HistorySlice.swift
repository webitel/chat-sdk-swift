//
//  HistorySlice.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation


/// Represents a portion of message history with cursors for pagination.
public struct HistorySlice: Hashable, Codable {

    /// Messages returned in this slice of history.
    public let items: [Message]

    /// Cursor used to load messages newer than this slice.
    public let newerCursor: HistoryCursor?

    /// Cursor used to load messages older than this slice.
    public let olderCursor: HistoryCursor?

    public init(
        items: [Message],
        newerCursor: HistoryCursor?,
        olderCursor: HistoryCursor?
    ) {
        self.items = items
        self.newerCursor = newerCursor
        self.olderCursor = olderCursor
    }
}


public extension HistorySlice {

    var isEmpty: Bool {
        items.isEmpty
    }
}
