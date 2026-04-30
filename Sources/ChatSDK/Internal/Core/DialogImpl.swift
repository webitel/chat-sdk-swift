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
    
    
    static func == (lhs: DialogImpl, rhs: DialogImpl) -> Bool {
        return lhs.id == rhs.id
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

