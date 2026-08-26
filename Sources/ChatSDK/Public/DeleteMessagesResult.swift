//
//  DeleteMessagesResult.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 20.08.2026.
//

import Foundation


/// Outcome of a message deletion request.
public struct DeleteMessagesResult: Hashable, Codable {

    /// Time the deletion was performed. `nil` if no messages were deleted.
    public let deletedAt: Date?

    /// Identifiers of the messages that were deleted.
    public let deletedIds: [String]

    /// Messages that were not deleted, with the reason for each (e.g. not found or not permitted).
    public let skipped: [SkippedMessage]
}
