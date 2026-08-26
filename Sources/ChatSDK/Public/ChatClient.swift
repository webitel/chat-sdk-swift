//
//  ChatClient.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 20.03.2026.
//

import Foundation


/// Main entry point for interacting with the Chat SDK.
///
/// `ChatClient` provides APIs for:
/// - sending messages
/// - fetching dialogs and contacts
/// - managing connection lifecycle
/// - observing events and connection state
/// - registering push notification tokens
///
/// The client supports both callback-based and async/await APIs.
public protocol ChatClient {

    /// Current connection state of the client.
    ///
    /// Reflects realtime connection status (e.g., connecting, connected, disconnected).
    var connectionState: ConnectionState { get }

    /// Sends a message asynchronously using a completion handler.
    ///
    /// This method does NOT require an active realtime connection.
    /// If the client is not connected, the SDK will perform a one-off HTTP request.
    ///
    /// - Parameters:
    ///   - target: Destination of the message (dialog or contact).
    ///   - options: Message configuration (text, metadata, etc.).
    ///   - completion: Completion handler returning message ID or error.
    ///
    /// - Returns: A `Cancellable` task that can be used to cancel the request.
    @discardableResult
    func sendMessage(
        to target: MessageTarget,
        options: MessageOptions,
        completion: @escaping (Result<String, ChatError>) -> Void
    ) -> Cancellable
    

    /// Sends a message asynchronously using async/await.
    ///
    /// This method does NOT require an active realtime connection.
    ///
    /// - Parameters:
    ///   - target: Destination of the message (dialog or contact).
    ///   - options: Message configuration.
    ///
    /// - Returns: ID of the sent message.
    /// - Throws: `ChatError` if sending fails.
    @discardableResult
    func sendMessage(
        to target: MessageTarget,
        options: MessageOptions
    ) async throws -> String

    
    /// Fetches dialogs using a completion handler.
    ///
    /// - Parameters:
    ///   - request: Pagination and filtering options.
    ///   - completion: Completion handler returning a page of dialogs or error.
    func getDialogs(
        request: DialogRequest,
        completion: @escaping (Result<Page<any Dialog>, ChatError>) -> Void
    )

    
    /// Fetches dialogs using async/await.
    ///
    /// - Parameter request: Pagination and filtering options.
    /// - Returns: A page of dialogs.
    /// - Throws: `ChatError` if request fails.
    func getDialogs(
        request: DialogRequest
    ) async throws -> Page<any Dialog>

    
    /// Fetches contacts using a completion handler.
    ///
    /// - Parameters:
    ///   - request: Pagination and filtering options.
    ///   - completion: Completion handler returning a page of contacts or error.
    func getContacts(
        request: ContactRequest,
        completion: @escaping (Result<Page<Contact>, ChatError>) -> Void
    )
    

    /// Fetches contacts using async/await.
    ///
    /// - Parameter request: Pagination and filtering options.
    /// - Returns: A page of contacts.
    /// - Throws: `ChatError` if request fails.
    func getContacts(
        request: ContactRequest
    ) async throws -> Page<Contact>
    
    
    /// Returns a direct dialog for the specified contact.
    ///
    /// If no direct dialog exists, a new one is created.
    ///
    /// - Parameters:
    ///   - contactId: The unique identifier of the contact.
    ///   - completion: Completion handler returning the dialog or error.
    func getOrCreateDialog(
        contactId: ContactID,
        completion: @escaping (Result<any Dialog, ChatError>) -> Void
    )
    
    
    /// Returns a direct dialog for the specified contact.
    ///
    /// If no direct dialog exists, a new one is created.
    ///
    /// - Parameter contactId: The unique identifier of the contact.
    /// - Returns: A direct dialog associated with the contact.
    /// - Throws: `ChatError` if the request fails.
    func getOrCreateDialog(
        contactId: ContactID
    ) async throws -> any Dialog

    
    /// Opens realtime connection (e.g., WebSocket).
    ///
    /// After connecting, the client starts receiving realtime events.
    func connect()

    
    /// Closes realtime connection.
    ///
    /// The client will stop receiving realtime updates.
    func disconnect()

    
    /// Ends the current session using a completion handler.
    ///
    /// This typically invalidates authentication and disconnects the client.
    ///
    /// - Parameter completion: Completion handler indicating success or failure.
    func endSession(
        completion: @escaping (Result<Void, ChatError>) -> Void
    )

    
    /// Ends the current session using async/await.
    ///
    /// - Throws: `ChatError` if operation fails.
    func endSession() async throws

    
    /// Registers a device for receiving push notifications.
    ///
    /// This method associates a push token with the current user/session.
    /// Supported token types:
    /// - `.fcm` for Firebase Cloud Messaging
    /// - `.apns` for Apple Push Notification Service
    ///
    /// - Parameters:
    ///   - pushToken: Device push notification token.
    ///   - pushTokenType: Type of push token.
    ///   - completion: Completion handler indicating success or failure.
    func registerDevice(
        pushToken: String,
        pushTokenType: PushTokenType,
        completion: @escaping (Result<Void, ChatError>) -> Void
    )
    

    /// Registers a device for receiving push notifications using async/await.
    ///
    /// - Parameters:
    ///   - pushToken: Device push notification token.
    ///   - pushTokenType: Type of push token.
    ///
    /// - Throws: `ChatError` if registration fails.
    func registerDevice(
        pushToken: String,
        pushTokenType: PushTokenType
    ) async throws
    
    
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


    /// Starts an asynchronous file upload operation.
    ///
    /// Upload progress and completion events are delivered
    /// through the provided `UploadObserver`.
    ///
    /// The returned `Cancellable` can be used to cancel
    /// the upload at any time.
    ///
    /// If the upload was interrupted previously,
    /// `UploadRequest.resumeId` can be used to continue it.
    ///
    /// - Parameters:
    ///   - request: Upload request parameters.
    ///   - observer: Receives upload events.
    /// - Returns: A cancellable upload task.
    @discardableResult
    func upload(
        request: UploadRequest,
        observer: UploadObserver
    ) -> Cancellable
    
    
    /// Starts an asynchronous file download operation.
    ///
    /// Downloaded file data is delivered incrementally
    /// through `DownloadObserver.onChunk`.
    ///
    /// The returned `Cancellable` can be used to cancel
    /// the download at any time.
    ///
    /// Downloads may optionally resume from a specific byte offset
    /// using `DownloadRequest.offset`.
    ///
    /// - Parameters:
    ///   - request: Download parameters.
    ///   - observer: Receives download events.
    /// - Returns: A cancellable download task.
    @discardableResult
    func download(
        request: DownloadRequest,
        observer: DownloadObserver
    ) -> Cancellable

    
    /// Adds an observer for chat events (messages, dialogs, typing, etc.).
    ///
    /// - Parameter observer: Object conforming to `ChatEventObserver`.
    func addEventObserver(_ observer: ChatEventObserver)

    
    /// Removes a previously added chat event observer.
    ///
    /// - Parameter observer: Observer to remove.
    func removeEventObserver(_ observer: ChatEventObserver)

    
    /// Adds an observer for connection state changes.
    ///
    /// - Parameter observer: Object conforming to `ConnectionObserver`.
    func addConnectionObserver(_ observer: ConnectionObserver)

    
    /// Removes a previously added connection observer.
    ///
    /// - Parameter observer: Observer to remove.
    func removeConnectionObserver(_ observer: ConnectionObserver)
}


public extension ChatClient {

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
