//
//  DialogImpl.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 26.03.2026.
//

import Foundation


internal final class DialogImpl: Dialog {
    private let client: DefaultChatClient
    private var state: DialogState
    
    var id: String { state.id }
    var type: DialogType { state.type }
    var members: [Participant] { state.members }
    var subject: String { state.subject }
    var lastMessage: Message? { state.lastMessage }
    
    init(
        state: DialogState,
        client: DefaultChatClient,
    ) {

        self.state = state
        self.client = client
    }
    
    
    func sendMessage(options: MessageOptions, completion: @escaping (Result<String, ChatError>) -> Void) -> any Cancellable {
        client.sendMessage(to: .dialog(id: id), options: options, completion: completion)
    }
    
    
    func sendMessage(
        options: MessageOptions
    ) async throws -> String {
        try await client.sendMessage(to: .dialog(id: id), options: options)
    }
    
    
    func getHistory(request: HistoryRequest, completion: @escaping (Result<HistorySlice, ChatError>) -> Void) {
        client.getHistory(dialogId: id, request: request, completion: completion)
    }
    
    
    func getHistory(request: HistoryRequest) async throws -> HistorySlice {
        try await client.getHistory(dialogId: id, request: request)
    }
    
    
    func sendAction(_ action: MessageAction, completion: @escaping (Result<Void, ChatError>) -> Void) {
        client.sendAction(action, completion: completion)
    }
    
    
    func sendAction(_ action: MessageAction) async throws {
        try await client.sendAction(action)
    }


    func sendTyping(request: TypingRequest, completion: @escaping (Result<Void, ChatError>) -> Void) {
        client.sendTyping(dialogId: id, request: request, completion: completion)
    }


    func sendTyping(request: TypingRequest) async throws {
        try await client.sendTyping(dialogId: id, request: request)
    }


    func setReaction(
        messageId: String,
        emoji: String,
        sendId: String?,
        completion: @escaping (Result<ReactionResult, ChatError>) -> Void
    ) {
        client.setReaction(messageId: messageId, emoji: emoji, sendId: sendId, completion: completion)
    }


    func setReaction(
        messageId: String,
        emoji: String,
        sendId: String?
    ) async throws -> ReactionResult {
        try await client.setReaction(messageId: messageId, emoji: emoji, sendId: sendId)
    }


    func deleteMessages(
        ids: [String],
        completion: @escaping (Result<DeleteMessagesResult, ChatError>) -> Void
    ) {
        client.deleteMessages(ids: ids, completion: completion)
    }


    func deleteMessages(ids: [String]) async throws -> DeleteMessagesResult {
        try await client.deleteMessages(ids: ids)
    }


    func editMessage(
        messageId: String,
        text: String,
        completion: @escaping (Result<EditMessageResult, ChatError>) -> Void
    ) {
        client.editMessage(messageId: messageId, text: text, completion: completion)
    }


    func editMessage(messageId: String, text: String) async throws -> EditMessageResult {
        try await client.editMessage(messageId: messageId, text: text)
    }


    func addObserver(_ observer: any ChatEventObserver) {
        client.addDialogObserver(dialogId: id, observer: observer)
    }
    
    
    func removeObserver(_ observer: any ChatEventObserver) {
        client.removeDialogObserver(dialogId: id, observer: observer)
    }


    func update(_ dto: DialogDto) {
        state.subject = dto.subject
 
        state.members =
        dto.members?.map { $0.toDomain() } ?? []

        state.lastMessage =
            dto.lastMessage?
            .toDomain(client.currentUserId)
    }
    
    
    func applyMessage(_ message: Message) {
        state.lastMessage = message
    }


    func applyReactions(messageId: String, reactions: [MessageReaction]) {
        guard state.lastMessage?.id == messageId else { return }
        state.lastMessage?.reactions = reactions
    }


    func applyDeletion(messageId: String) {
        guard state.lastMessage?.id == messageId else { return }
        state.lastMessage = nil
    }


    @discardableResult
    func applyEdit(_ message: Message) -> Message {
        guard state.lastMessage?.id == message.id else { return message }

        var merged = message
        if merged.reactions.isEmpty {
            merged.reactions = state.lastMessage?.reactions ?? []
        }

        state.lastMessage = merged
        return merged
    }


    static func == (lhs: DialogImpl, rhs: DialogImpl) -> Bool {
        return lhs.id == rhs.id
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

