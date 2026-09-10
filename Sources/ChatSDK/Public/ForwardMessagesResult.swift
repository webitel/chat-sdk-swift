//
//  ForwardMessagesResult.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 09.09.2026.
//

import Foundation


/// Outcome of a message forward request.
public struct ForwardMessagesResult: Hashable, Codable {

    /// Identifiers of the newly created forwarded messages.
    public let ids: [String]

    /// Messages that were not forwarded, with the reason for each (e.g. not found or not permitted).
    public let skipped: [SkippedMessage]

    /// Identifier of the destination dialog the messages were forwarded into.
    public let threadId: String
}
