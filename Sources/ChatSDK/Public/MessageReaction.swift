//
//  MessageReaction.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 17.08.2026.
//

import Foundation


public struct MessageReaction: Hashable, Codable {

    /// The reacted-with emoji.
    public let emoji: String

    /// Number of users who reacted with this emoji.
    public let count: Int

    /// Whether the current user is among the reactors.
    public let reactedByMe: Bool

    /// Identifiers of users who reacted with this emoji.
    public let reactorIds: [String]

    /// Time of the most recent reaction with this emoji, if known.
    public let lastReactedAt: Date?
}
