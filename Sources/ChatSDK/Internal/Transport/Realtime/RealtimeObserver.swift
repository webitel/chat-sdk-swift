//
//  RealtimeObserver.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 08.04.2026.
//

import Foundation


internal protocol RealtimeObserver: AnyObject {

    func onMessage(_ message: MessageDto)
    func onTyping(_ event: TypingEventDto)
    func onMessageReaction(_ event: MessageReactionEventDto)
    func onMessageDeleted(_ event: MessageDeletedEventDto)
    func onMessageEdited(_ event: MessageEditedEventDto)
    func onNewDialog(_ dialog: DialogDto)
    func onError(_ error: ChatError)
    func onOpen()
    func onClosed(
        code: Int,
        reason: String
    )
}
