//
//  Dialog.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation


public protocol Dialog: Hashable {
    /// Unique identifier of the dialog.
    var id: String { get }

    /// Display name or subject of the dialog.
    var subject: String { get }

    /// Dialog type (e.g. direct, group, channel).
    var type: DialogType { get }

    /// Participants of the dialog.
    var members: [Participant] { get }

    /// Last message in the dialog, if available.
    var lastMessage: Message? { get }

    /// Sends a message.
    ///
    /// - Note: Does not require an active realtime connection.
    @discardableResult
    func sendMessage(
        options: MessageOptions,
        completion: @escaping (Result<String, ChatError>) -> Void
    ) -> any Cancellable

    
    /// Sends a message using async/await.
    ///
    /// - Returns: Created message identifier.
    func sendMessage(
        options: MessageOptions
    ) async throws -> String
    
    
    /// Loads message history.
    func getHistory(
        request: HistoryRequest,
        completion: @escaping (Result<HistorySlice, ChatError>) -> Void
    )

    
    /// Loads message history using async/await.
    func getHistory(
        request: HistoryRequest
    ) async throws -> HistorySlice
    
    
    /// Sends a user action related to a message.
    ///
    /// Typically used for interactive message actions
    /// such as keyboard button taps.
    ///
    /// - Parameter action: Action to be performed
    ///
    func sendAction(
        _ action: MessageAction,
        completion: @escaping (Result<Void, ChatError>) -> Void
    )
    
    
    /// Sends a user action using async/await.
    ///
    /// - Parameter action: Action to be performed
    ///
    /// - Throws: `ChatError` if operation fails.
    func sendAction(
        _ action: MessageAction
    ) async throws


    /// Sends a typing indicator to the dialog.
    ///
    /// Typically used to notify other participants that
    /// the user is currently composing a message.
    ///
    /// - Parameter request: Optional typing parameters (preview text, timeout).
    func sendTyping(
        request: TypingRequest,
        completion: @escaping (Result<Void, ChatError>) -> Void
    )


    /// Sends a typing indicator using async/await.
    ///
    /// - Parameter request: Optional typing parameters (preview text, timeout).
    /// - Throws: `ChatError` if operation fails.
    func sendTyping(
        request: TypingRequest
    ) async throws


    /// Sets or updates the current user's reaction on a message using a completion handler.
    ///
    /// Only one reaction per user is allowed per message; sending a new emoji
    /// replaces the previous one. Use `removeReaction` to clear it.
    ///
    /// - Parameters:
    ///   - messageId: Identifier of the message being reacted to.
    ///   - emoji: Emoji to set as the reaction.
    ///   - sendId: Optional client-generated request identifier.
    ///   - completion: Completion handler returning the resulting reaction state or error.
    func setReaction(
        messageId: String,
        emoji: String,
        sendId: String?,
        completion: @escaping (Result<ReactionResult, ChatError>) -> Void
    )


    /// Sets or updates the current user's reaction on a message using async/await.
    ///
    /// - Parameters:
    ///   - messageId: Identifier of the message being reacted to.
    ///   - emoji: Emoji to set as the reaction.
    ///   - sendId: Optional client-generated request identifier.
    /// - Returns: The resulting reaction state.
    /// - Throws: `ChatError` if the operation fails.
    func setReaction(
        messageId: String,
        emoji: String,
        sendId: String?
    ) async throws -> ReactionResult


    /// Deletes messages by identifier using a completion handler.
    ///
    /// - Parameters:
    ///   - ids: Identifiers of the messages to delete.
    ///   - completion: Completion handler returning the deletion result or error.
    func deleteMessages(
        ids: [String],
        completion: @escaping (Result<DeleteMessagesResult, ChatError>) -> Void
    )


    /// Deletes messages by identifier using async/await.
    ///
    /// - Parameter ids: Identifiers of the messages to delete.
    /// - Returns: The deletion result, including skipped identifiers.
    /// - Throws: `ChatError` if the operation fails.
    func deleteMessages(
        ids: [String]
    ) async throws -> DeleteMessagesResult


    /// Edits the text of a message using a completion handler.
    ///
    /// - Parameters:
    ///   - messageId: Identifier of the message to edit.
    ///   - text: New text of the message.
    ///   - completion: Completion handler returning the edit result or error.
    func editMessage(
        messageId: String,
        text: String,
        completion: @escaping (Result<EditMessageResult, ChatError>) -> Void
    )


    /// Edits the text of a message using async/await.
    ///
    /// - Parameters:
    ///   - messageId: Identifier of the message to edit.
    ///   - text: New text of the message.
    /// - Returns: The edit result, including the edit timestamp.
    /// - Throws: `ChatError` if the operation fails.
    func editMessage(
        messageId: String,
        text: String
    ) async throws -> EditMessageResult


    /// Adds a dialog-scoped event observer.
    func addObserver(_ listener: ChatEventObserver)


    /// Removes a dialog-scoped event observer.
    func removeObserver(_ listener: ChatEventObserver)
}


public extension Dialog {

    /// Sets or updates the current user's reaction on a message using a completion handler.
    ///
    /// - Parameters:
    ///   - messageId: Identifier of the message being reacted to.
    ///   - emoji: Emoji to set as the reaction.
    ///   - completion: Completion handler returning the resulting reaction state or error.
    func setReaction(
        messageId: String,
        emoji: String,
        completion: @escaping (Result<ReactionResult, ChatError>) -> Void
    ) {
        setReaction(messageId: messageId, emoji: emoji, sendId: nil, completion: completion)
    }


    /// Sets or updates the current user's reaction on a message using async/await.
    ///
    /// - Parameters:
    ///   - messageId: Identifier of the message being reacted to.
    ///   - emoji: Emoji to set as the reaction.
    /// - Returns: The resulting reaction state.
    /// - Throws: `ChatError` if the operation fails.
    func setReaction(
        messageId: String,
        emoji: String
    ) async throws -> ReactionResult {
        try await setReaction(messageId: messageId, emoji: emoji, sendId: nil)
    }


    /// Removes the current user's reaction from a message, if any, using a completion handler.
    ///
    /// - Parameters:
    ///   - messageId: Identifier of the message to clear the reaction from.
    ///   - completion: Completion handler returning the resulting reaction state or error.
    func removeReaction(
        messageId: String,
        completion: @escaping (Result<ReactionResult, ChatError>) -> Void
    ) {
        setReaction(messageId: messageId, emoji: "", sendId: nil, completion: completion)
    }


    /// Removes the current user's reaction from a message, if any, using async/await.
    ///
    /// - Parameter messageId: Identifier of the message to clear the reaction from.
    /// - Returns: The resulting reaction state.
    /// - Throws: `ChatError` if the operation fails.
    func removeReaction(
        messageId: String
    ) async throws -> ReactionResult {
        try await setReaction(messageId: messageId, emoji: "", sendId: nil)
    }
}
