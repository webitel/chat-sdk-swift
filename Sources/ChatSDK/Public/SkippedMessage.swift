//
//  SkippedMessage.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 25.08.2026.
//

import Foundation


/// A message that was not deleted, along with the server-provided reason.
public struct SkippedMessage: Hashable, Codable {

    /// Identifier of the message that was not deleted.
    public let id: String

    /// Reason the message was skipped.
    public let reason: SkippedMessageReason
}
