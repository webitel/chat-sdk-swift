//
//  MessageTarget.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 20.03.2026.
//

import Foundation


public enum MessageTarget: Equatable {

    /// Target an existing dialog by its unique identifier.
    case dialog(id: String)

    /// Target a contact directly (a dialog may be created automatically).
    case contact(contactId: ContactID)
}
