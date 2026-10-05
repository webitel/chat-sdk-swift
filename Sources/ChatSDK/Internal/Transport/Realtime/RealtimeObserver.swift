//
//  RealtimeObserver.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 08.04.2026.
//

import Foundation


internal protocol RealtimeObserver: AnyObject {

    /// `cursor` is the updates cursor carried by the frame, if any.
    func onMessage(_ message: MessageDto, cursor: String?)
    func onTyping(_ event: TypingEventDto)
    func onMessageReaction(_ event: MessageReactionEventDto, cursor: String?)
    func onMessageDeleted(_ event: MessageDeletedEventDto, cursor: String?)
    func onMessageEdited(_ event: MessageEditedEventDto, cursor: String?)
    func onMessageStatus(_ event: MessageStatusEventDto, cursor: String?)
    func onNewDialog(_ dialog: DialogDto, cursor: String?)
    func onConnectedEvent(cursor: String?)
    func onError(_ error: ChatError)
    func onOpen()
    func onClosed(
        code: Int,
        reason: String
    )
}
