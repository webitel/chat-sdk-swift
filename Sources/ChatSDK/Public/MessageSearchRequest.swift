//
//  MessageSearchRequest.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.09.2026.
//

import Foundation


/// Request parameters used to search messages by text query.
public struct MessageSearchRequest: Hashable, Codable {

    /// Search text, matched as a case-insensitive substring. Expected to be 1...256 characters, server-validated.
    public let query: String

    /// Optional filter by message sender. Expected to be up to 50 identifiers, server-validated.
    public let senderIds: Set<String>

    /// Optional filter by message content type. Expected to be up to 8 values, server-validated.
    public let contentTypes: Set<MessageSearchContentType>

    /// Maximum number of items to return.
    public let limit: Int

    /// Optional cursor used to continue search navigation.
    public let cursor: MessageSearchCursor?

    public init(
        query: String,
        senderIds: Set<String> = [],
        contentTypes: Set<MessageSearchContentType> = [],
        limit: Int = 20,
        cursor: MessageSearchCursor? = nil
    ) {
        self.query = query
        self.senderIds = senderIds
        self.contentTypes = contentTypes
        self.limit = min(max(limit, 1), 100)
        self.cursor = cursor
    }
}


/// Content type of a message, as used to filter search results.
/// Raw values are `Int`, matching the numeric codes of the wire protocol (unlike most other SDK enums, which map to string values).
public enum MessageSearchContentType: Int, Hashable, Codable {
    case text = 1
    case document = 2
    case image = 3
    case system = 4
    case interactive = 5
    case location = 6
    case contact = 7
}
