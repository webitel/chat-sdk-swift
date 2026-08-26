//
//  EditMessageResult.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 20.08.2026.
//

import Foundation


/// Outcome of editing a message.
public struct EditMessageResult: Hashable, Codable {

    /// Identifier of the edited message.
    public let id: String

    /// Time the edit was applied.
    public let editedAt: Date
}
