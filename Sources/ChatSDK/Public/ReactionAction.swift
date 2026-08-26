//
//  ReactionAction.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 17.08.2026.
//

import Foundation


/// Result of a reaction request, describing what happened to the reaction.
public enum ReactionAction: String, Hashable, Codable {

    /// The reaction was set (added or replaced a previous one).
    case set = "REACTION_ACTION_SET"

    /// The reaction was removed.
    case removed = "REACTION_ACTION_REMOVED"

    /// The request had no effect (the same reaction was already present).
    case unchanged = "REACTION_ACTION_UNCHANGED"
}
