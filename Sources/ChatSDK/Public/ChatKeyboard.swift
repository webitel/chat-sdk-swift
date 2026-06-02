//
//  ChatKeyboard.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 06.05.2026.
//

import Foundation


/// Represents an interactive message keyboard.
public enum ChatKeyboard: Hashable, Codable {

    /// Grid-style keyboard (inline buttons in rows)
    case buttons(Buttons)

    /// List-style keyboard with sections
    case listMenu(ListMenu)


    public struct Buttons: Hashable, Codable {
        public let rows: [ChatKeyboardRow]
    }

    public struct ListMenu: Hashable, Codable {
        public let title: String
        public let sections: [ChatKeyboardSection]
    }
}


/// Represents a section inside a list-style keyboard.
public struct ChatKeyboardSection: Hashable, Codable {

    /// Section title shown to the user
    public let title: String

    /// Buttons belonging to this section
    public let buttons: [ChatKeyboardButton]
}


/// Represents a horizontal row of buttons.
public struct ChatKeyboardRow: Hashable, Codable {
    
    /// Buttons displayed in a single row
    public let buttons: [ChatKeyboardButton]
}


/// Represents a single interactive button in the keyboard.
public struct ChatKeyboardButton: Hashable, Codable {

    /// Unique identifier of the button
    public let id: String

    /// Text displayed on the button
    public let label: String

    /// Action triggered on click
    public let action: ChatButtonAction
    
    /// Optional UI metadata provided by the backend.
    ///
    /// Can contain custom rendering hints such as:
    /// - colors
    /// - visibility flags
    public let metadata: [String: MetadataValue]?
}


/// Defines behavior of a keyboard button.
public enum ChatButtonAction: Hashable, Codable {

    /// Opens external URL
    case openURL(String)

    /// Sends callback to backend
    case callback(String)

    /// Requests device data (e.g. location, contact)
    case requestData(String)
}


public extension ChatKeyboardButton {

    var isUrl: Bool {
        if case .openURL = action { return true }
        return false
    }

    var isCallback: Bool {
        if case .callback = action { return true }
        return false
    }

    var isRequest: Bool {
        if case .requestData = action { return true }
        return false
    }
}
