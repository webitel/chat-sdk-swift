//
//  MessageSearchSlice.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 24.09.2026.
//

import Foundation


/// Represents a portion of message search results with cursors for pagination.
public struct MessageSearchSlice: Hashable, Codable {

    /// Messages matching the search request.
    public let items: [Message]

    /// Cursor used to load newer search results.
    public let newerCursor: MessageSearchCursor?

    /// Cursor used to load older search results.
    public let olderCursor: MessageSearchCursor?

    public init(
        items: [Message],
        newerCursor: MessageSearchCursor?,
        olderCursor: MessageSearchCursor?
    ) {
        self.items = items
        self.newerCursor = newerCursor
        self.olderCursor = olderCursor
    }
}


public extension MessageSearchSlice {

    var isEmpty: Bool {
        items.isEmpty
    }
}
