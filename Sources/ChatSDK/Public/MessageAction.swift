//
//  MessageAction.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 10.05.2026.
//

import Foundation


/// Represents a user action related to a message.
///
/// Actions are typically triggered by interactive UI elements
/// such as buttons or quick replies.
public enum MessageAction {

    /// Action triggered by tapping a keyboard button.
    case buttonClick(ButtonClick)


    public struct ButtonClick {

        /// Identifier of the related message.
        public let messageId: String

        /// Identifier of the clicked button.
        public let buttonId: String

        /// Payload associated with the button.
        public let data: String

        public init(
            messageId: String,
            buttonId: String,
            data: String
        ) {
            self.messageId = messageId
            self.buttonId = buttonId
            self.data = data
        }
    }
}


public extension MessageAction {

    /// Creates a button click action.
    static func buttonClick(
        messageId: String,
        buttonId: String,
        data: String
    ) -> MessageAction {
        .buttonClick(
            .init(
                messageId: messageId,
                buttonId: buttonId,
                data: data
            )
        )
    }
}
