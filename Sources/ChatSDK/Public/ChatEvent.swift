//
//  ChatEvent.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation


/// Chat-related events emitted by the SDK.
public enum ChatEvent {

    case message(MessageEvent)
    case dialog(DialogEvent)
    case state(StateEvent)

    /// Dialog identifier associated with the event.
    public var dialogId: String {

        switch self {
        case .message(let event):
            return event.dialogId

        case .dialog(let event):
            return event.dialogId

        case .state(let event):
            return event.dialogId
        }
    }
}


// MARK: - Message Events
public enum MessageEvent {

    case received(
        dialogId: String,
        message: Message
    )

    case edited(
        dialogId: String,
        messageId: String,
        newText: String
    )

    case deleted(
        dialogId: String,
        messageId: String
    )

    var dialogId: String {
        switch self {
        case .received(let id, _),
             .edited(let id, _, _),
             .deleted(let id, _):
            return id
        }
    }
}


// MARK: - Dialog Events
public enum DialogEvent {

    case created(
        dialogId: String,
        dialog: any Dialog
    )

    var dialogId: String {
        switch self {
        case .created(let id, _):
            return id
        }
    }
}


// MARK: - State Events
public enum StateEvent {

    case typing(
        dialogId: String,
        userId: String
    )

    case read(
        dialogId: String,
        messageId: String,
        userId: String
    )

    var dialogId: String {
        switch self {
        case .typing(let id, _),
             .read(let id, _, _):
            return id
        }
    }
}
