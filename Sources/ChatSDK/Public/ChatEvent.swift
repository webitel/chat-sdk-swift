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
    case activity(ActivityEvent)
    case receipt(ReceiptEvent)

    public var dialogId: String {
        switch self {
        case .message(let event):
            return event.dialogId

        case .dialog(let event):
            return event.dialogId

        case .activity(let event):
            return event.dialogId

        case .receipt(let event):
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
        message: Message
    )

    case deleted(
        dialogId: String,
        deletion: MessageDeletion
    )
    
    case reactionsChanged(
        dialogId: String,
        messageId: String,
        reactions: [MessageReaction]
    )

    var dialogId: String {
        switch self {
        case .received(let id, _),
             .edited(let id, _),
             .deleted(let id, _),
             .reactionsChanged(let id, _, _):
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

    /// Emitted after the SDK recovers changes missed while
    /// the realtime connection was temporarily unavailable.
    case synchronized(
        dialogId: String,
        changes: DialogSyncChanges
    )

    var dialogId: String {
        switch self {
        case .created(let id, _),
             .synchronized(let id, _):
            return id
        }
    }
}


public enum ReceiptEvent {

    case delivered(
        dialogId: String,
        member: Participant,
        upToSequence: Int64
    )

    /// `unreadCount` is the current user's unread count after the receipt;
    /// present only when `member` is the current user, `nil` otherwise.
    case read(
        dialogId: String,
        member: Participant,
        upToSequence: Int64,
        unreadCount: Int?
    )

    case deliveryFailed(
        dialogId: String,
        exception: DeliveryException
    )

    var dialogId: String {
        switch self {
        case .delivered(let id, _, _),
             .read(let id, _, _, _),
             .deliveryFailed(let id, _):
            return id
        }
    }
}


public enum ActivityEvent {

    case typing(
        dialogId: String,
        member: Participant,
        previewText: String?,
        timeoutMs: Int?
    )

//    case recordingAudio(
//        dialogId: String,
//        member: Participant,
//        timeoutMs: Int?
//    )
//
//    case recordingVideo(
//        dialogId: String,
//        member: Participant,
//        timeoutMs: Int?
//    )

    var dialogId: String {
        switch self {
            case .typing(let id, _, _, _):
//             .recordingAudio(let id, _, _),
//             .recordingVideo(let id, _, _):
            return id
        }
    }
}
