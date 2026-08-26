//
//  ReactionResult.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 17.08.2026.
//

import Foundation


/// Outcome of setting or removing a reaction on a message.
public struct ReactionResult: Hashable, Codable {

    /// What happened to the reaction as a result of the request.
    public let action: ReactionAction

    /// Emoji associated with the reaction, if provided by the server.
    public let emoji: String?

    /// Time the reaction was changed, if provided by the server.
    public let reactedAt: Date?
}
