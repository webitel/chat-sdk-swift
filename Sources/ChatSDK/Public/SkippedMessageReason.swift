//
//  SkippedMessageReason.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 25.08.2026.
//

import Foundation


/// Reason a message was not deleted.
public enum SkippedMessageReason: String, Hashable, Codable, CaseIterable {

    /// Reason was not specified by the server.
    case unspecified = "REASON_UNSPECIFIED"

    /// The message no longer exists.
    case notFound = "REASON_NOT_FOUND"

    /// The current user is not the author of the message.
    case notAuthor = "REASON_NOT_AUTHOR"

    /// The message was already deleted.
    case alreadyDeleted = "REASON_ALREADY_DELETED"

    /// The chat the message belongs to is closed.
    case chatClosed = "REASON_CHAT_CLOSED"

    /// The current user is not allowed to delete the message.
    case notAllowed = "REASON_NOT_ALLOWED"

    /// Unknown or unsupported reason.
    case unknown

    /// Creates SkippedMessageReason from raw API value, falling back to `.unknown` for unrecognized values.
    public static func from(_ value: String) -> SkippedMessageReason {
        Self.allCases.first { $0.rawValue == value } ?? .unknown
    }
}
