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
