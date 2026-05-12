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

    
    /// Adds a dialog-scoped event observer.
    func addObserver(_ listener: ChatEventObserver)

    
    /// Removes a dialog-scoped event observer.
    func removeObserver(_ listener: ChatEventObserver)
}
