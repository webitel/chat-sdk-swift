//
//  ChatAPI.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation

internal protocol ChatAPI: AnyObject {

    @discardableResult
    func sendMessage(
        to target: MessageTarget,
        options: MessageOptions
    ) async throws -> String

    func getDialogs(
        _ request: DialogRequest
    ) async throws -> Page<DialogDto>

    func getContacts(
        _ request: ContactRequest
    ) async throws -> Page<ContactDto>

    func getHistory(
        dialogId: String,
        request: HistoryRequest
    ) async throws -> HistoryResponseDto

    func searchMessages(
        dialogId: String?,
        request: MessageSearchRequest
    ) async throws -> MessageSearchResponseDto

    func registerDevice(
        pushToken: String,
        pushTokenType: PushTokenType
    ) async throws
    
    func sendAction(
        action: MessageAction
    ) async throws
    
    func getOrCreateDialog(
        contactId: ContactID
    ) async throws -> DialogDto

    func sendTyping(
        dialogId: String,
        request: TypingRequest
    ) async throws

    func setReaction(
        messageId: String,
        emoji: String,
        sendId: String?
    ) async throws -> ReactionResponseDto

    func deleteMessages(
        ids: [String]
    ) async throws -> DeleteMessagesResponseDto

    func forwardMessages(
        ids: [String],
        to target: MessageTarget,
        sendId: String
    ) async throws -> ForwardMessagesResponseDto

    func editMessage(
        messageId: String,
        text: String
    ) async throws -> EditMessageResponseDto
}
