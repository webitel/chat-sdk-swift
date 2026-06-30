//
//  ChatKeyboardReaction.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 30.06.2026.
//

import Foundation


public struct ChatKeyboardReaction: Hashable, Codable {

    /// Identifier of the selected button.
    public let buttonCode: String

    /// Callback data associated with the button.
    public let callbackData: String

    /// Time when the button was pressed.
    public let reactedAt: Date

    /// User who pressed the button.
    public let reactedBy: Participant
}
