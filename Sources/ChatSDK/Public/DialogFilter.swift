//
//  DialogFilter.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 20.04.2026.
//

import Foundation


public struct DialogFilter: Hashable, Codable {

    /// Full-text search query (up to 256 characters).
    public let query: String?

    /// Filter by specific dialog IDs.
    public let ids: [String]?

    /// Filter by dialog types (e.g. direct, group, channel).
    /// `.unknown` is ignored and not sent to the server.
    /// If no valid types are provided, the filter is not applied.
    public let types: [DialogType]?

    public init(
        query: String? = nil,
        ids: [String]? = nil,
        types: [DialogType]? = nil
    ) {
        self.query = query
        self.ids = ids
        self.types = types
    }
}
