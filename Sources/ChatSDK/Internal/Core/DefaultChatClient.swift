//
//  DefaultChatClient.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation


internal class DefaultChatClient: ChatClient {
    func upload(request: UploadRequest, observer: any UploadObserver) -> any Cancellable {
        fileTransferClient.upload(request: request, observer: observer)
    }
    
    
    private let apiProvider: ChatAPI
    private let authManager: AuthService
    private let dialogFactory: DialogFactory
    private let context: ClientContext
    private let realtimeTransport: RealtimeTransport
    private let fileTransferClient: HttpFileTransferClient
    private let hub: RealtimeHub
    
    private var realtimeEnabled: Bool = false
    private var isBackoffActive: Bool = false
    private var backoffWorkItem: DispatchWorkItem?
    private var retryAttempt = 0
    
    private let logger = SDKLogger.make("chat.core.client")
    private let queue = DispatchQueue(label: "chat.core.client")
    private let queueTimer = DispatchQueue.global(qos: .utility)
    
    var connectionState: ConnectionState {
        if isBackoffActive {return .connecting}
        return realtimeTransport.connectionState
    }
    
    var currentUserId: String? {
        authManager.currentContact?.id
    }
    
    init(
        context: ClientContext,
        apiProvider: ChatAPI,
        authManager: AuthService,
        dialogFactory: DialogFactory,
        hub: RealtimeHub,
        realtimeTransport: RealtimeTransport,
        fileTransferClient: HttpFileTransferClient
    ) {
        self.apiProvider = apiProvider
        self.authManager = authManager
        self.dialogFactory = dialogFactory
        self.context = context
        self.hub = hub
        self.realtimeTransport = realtimeTransport
        self.fileTransferClient = fileTransferClient
        self.realtimeTransport.setObserver(self)
    }
    
    
    @discardableResult
    func sendMessage(
        to target: MessageTarget,
        options: MessageOptions,
        completion: @escaping (
            Result<String, ChatError>
        ) -> Void
    ) -> Cancellable {
        let task = Task {

            do {
                let result = try await sendMessage(
                    to: target,
                    options: options
                )

                completion(.success(result))
            } catch {
                completion(
                    .failure(error.asChatError)
                )
            }
        }

        return TaskCancellable(task)
    }
    
    
    func sendMessage(
        to target: MessageTarget,
        options: MessageOptions
    ) async throws -> String {

        try await performWithAuthRetry {

            try await self.apiProvider.sendMessage(
                to: target,
                options: options
            )
        }
    }
    
    
    func getHistory(
        dialogId: String,
        request: HistoryRequest,
        completion: @escaping (Result<HistorySlice, ChatError>) -> Void
    ) {
        Task {
            do {
                let result = try await getHistory(dialogId: dialogId, request: request)
                
                completion(.success(result))
            } catch {
                completion(
                    .failure(error.asChatError)
                )
            }
        }
    }
    
    
    func getHistory(
        dialogId: String,
        request: HistoryRequest
    ) async throws -> HistorySlice {
        try await performWithAuthRetry {

            let result = try await self.apiProvider.getHistory(dialogId: dialogId, request: request)

            return HistorySlice(
                items: (result.items?.map { $0.toDomain(self.currentUserId) } ?? []).reversed(),
                newerCursor: result.newerPaging.map { HistoryCursor(messageId: $0.id, direction: .newer) },
                olderCursor: result.olderPaging.map { HistoryCursor(messageId: $0.id, direction: .older) }
            )
        }
    }
    
    
    func getDialogs(
        request: DialogRequest,
        completion: @escaping (
            Result<Page<any Dialog>, ChatError>
        ) -> Void
    ) {
        Task {
            do {
                let result = try await getDialogs(
                    request: request
                )
                
                completion(.success(result))
            } catch {
                completion(
                    .failure(error.asChatError)
                )
            }
        }
    }
    
    
    func getDialogs(
        request: DialogRequest
    ) async throws -> Page<any Dialog> {

        try await performWithAuthRetry {

            let result = try await self.apiProvider.getDialogs(request)

            return Page(
                page: result.page,
                items: result.items.map {
                    self.dialogFactory.getOrCreate(
                        client: self,
                        dto: $0
                    )
                },
                hasNext: result.hasNext
            )
        }
    }
    
    
    func getContacts(request: ContactRequest, completion: @escaping (Result<Page<Contact>, ChatError>) -> Void) {
        Task {
            do {
                let result = try await self.getContacts(
                    request: request
                )
                
                completion(.success(result))
            } catch {
                completion(
                    .failure(error.asChatError)
                )
            }
        }
    }
    
    
    func getContacts(request: ContactRequest) async throws -> Page<Contact> {
        try await performWithAuthRetry {

            let result = try await self.apiProvider.getContacts(request)

            return Page(
                page: result.page,
                items: result.items.map {
                    $0.toDomain()
                },
                hasNext: result.hasNext
            )
        }
    }
    
    
    func connect() {
        queue.async { [weak self] in
            guard let self else { return }
            
            self.logger.debug("called connect()")
            
            if self.realtimeEnabled {
                self.logger.debug("connect: realtime is enabled. State \(self.connectionState)")
                return
            }
            
            self.realtimeEnabled = true
            self.retryAttempt = 0
            
            self.hub.updateState(.connecting)
            self.realtimeTransport.connect()
        }
    }
    
    
    func disconnect() {
        queue.async { [weak self] in
            guard let self else { return }
            
            realtimeEnabled = false
            isBackoffActive = false
            backoffWorkItem?.cancel()
            backoffWorkItem = nil
            retryAttempt = 0
            realtimeTransport.disconnect()
        }
    }
    
    
    func endSession(completion: @escaping (Result<Void, ChatError>) -> Void) {
        Task {
            do {
                try await self.endSession()
                
                completion(.success(Void()))
            } catch {
                completion(
                    .failure(error.asChatError)
                )
            }
        }
    }
    
    
    func endSession() async throws {
        disconnect()
        try await self.authManager.endSession()
    }
    
    
    func registerDevice(
        pushToken: String,
        pushTokenType: PushTokenType,
        completion: @escaping (Result<Void, ChatError>
    ) -> Void) {
        Task {
            do {
                try await self.registerDevice(
                    pushToken: pushToken,
                    pushTokenType: pushTokenType
                )
                
                completion(.success(Void()))
            } catch {
                completion(
                    .failure(error.asChatError)
                )
            }
        }
    }
    
    
    func registerDevice(
        pushToken: String,
        pushTokenType: PushTokenType
    ) async throws {
        try await performWithAuthRetry {

            try await self.apiProvider.registerDevice(
                pushToken: pushToken,
                pushTokenType: pushTokenType
            )
        }
    }
    
    
    func sendAction(_ action: MessageAction, completion: @escaping (Result<Void, ChatError>) -> Void) {
        Task {
            do {
                try await self.sendAction(action)
                
                completion(.success(Void()))
            } catch {
                completion(
                    .failure(error.asChatError)
                )
            }
        }
    }
    
    
    func sendAction(_ action: MessageAction) async throws {
        try await performWithAuthRetry {

            try await self.apiProvider.sendAction(action: action)
        }
    }
    
    
    func download(request: DownloadRequest, observer: any DownloadObserver) -> any Cancellable {
        fileTransferClient.download(request, observer)
    }
    
    
    func addEventObserver(_ observer: any ChatEventObserver) {
        hub.addGlobalObserver(observer)
    }
    
    
    func removeEventObserver(_ observer: any ChatEventObserver) {
        hub.removeGlobalObserver(observer)
    }
    
    
    func addDialogObserver(dialogId: String, observer: ChatEventObserver) {
        hub.addDialogObserver(dialogId: dialogId, observer: observer)
    }
    
    
    func removeDialogObserver(dialogId: String, observer: any ChatEventObserver) {
        hub.removeDialogObserver(dialogId: dialogId, observer: observer)
    }
    
    
    func addConnectionObserver(_ observer: any ConnectionObserver) {
        hub.addConnectionObserver(observer)
    }
    
    
    func removeConnectionObserver(_ observer: any ConnectionObserver) {
        hub.removeConnectionObserver(observer)
    }
    
    
    @discardableResult
    private func performWithAuthRetry<T>(
        _ operation: @escaping () async throws -> T
    ) async throws -> T {
        do {
            return try await operation()

        } catch let error as ChatError {
            if case .unauthorized = error {
                try await authManager.refresh()
                return try await operation()
            }
            throw error
        } catch {
            throw error.asChatError
        }
    }
}


final class TaskCancellable: Cancellable {
    private let task: Task<Void, Never>

    init(_ task: Task<Void, Never>) {
        self.task = task
    }

    func cancel() {
        task.cancel()
    }
}


extension DefaultChatClient: RealtimeObserver {
    func onMessage(_ message: MessageDto) {
        let dialog = self.dialogFactory.get(message.dialogId)
        let messageDomain = message.toDomain(self.authManager.currentContact?.id)
        
        dialog?.applyMessage(messageDomain)
        
        self.hub.dispatch(
            ChatEvent.message(
                MessageEvent.received(dialogId: message.dialogId, message: messageDomain)
            )
        )
    }
    
    
    func onNewDialog(_ dialog: DialogDto) {
        let newDialog = self.dialogFactory.getOrCreate(client: self, dto: dialog)
        
        self.hub.dispatch(
            ChatEvent.dialog(
                DialogEvent.created(dialogId: newDialog.id, dialog: newDialog)
            )
        )
    }
    
    
    func onError(_ error: ChatError) {
        if !self.canRetry(self.retryAttempt) {
            self.failRealtime(error)
            return
        }
        
        if case ChatError.unauthorized = error {
            self.refreshAuthAndReconnect()
            return
        }
        
        self.tryConnect()
    }
    
    
    func onOpen() {
        self.retryAttempt = 0
        self.hub.updateState(.connected)
    }
    
    
    func onClosed(code: Int, reason: String) {
        if !self.realtimeEnabled {
            self.hub.updateState(.disconnected)
            return
        }
        
        if !self.canRetry(self.retryAttempt) {
            self.closeRealtime(code: code, reason: reason)
            return
        }
        
        if code == 401 || code == 1008 {
            self.refreshAuthAndReconnect()
            return
        }
        
        self.tryConnect()
    }
    
    
    private func closeRealtime(code: Int, reason: String) {
        logger.debug("onClosed: close realtime")
        
        realtimeEnabled = false
        
        hub.updateState(
            .failed(ChatError.from(statusCode: code, message: reason))
        )
    }
    
    
    private func refreshAuthAndReconnect() {
        Task {
            do {
                try await authManager.refresh()
                if !self.realtimeEnabled { return }
                
                self.tryConnect()
            } catch {
                failRealtime(error.asChatError)
            }
        }
    }
    
    
    private func failRealtime(_ error: ChatError) {
        realtimeEnabled = false
        logger.error("Realtime connection failed. \(error)")
        hub.updateState(.failed(error))
    }
    
    
    private func calculateBackoff(attempt: Int) -> TimeInterval {
        let base = Double(context.networkConfig.realtime.retryBaseDelay)
        let delay = base * pow(2.0, Double(attempt))
        
        return min(
            delay,
            context.networkConfig.realtime.maxRetryDelay
        )
    }
    
    
    private func canRetry(_ attempt: Int) -> Bool {
        return realtimeEnabled &&
               attempt < context.networkConfig.realtime.maxRetries
    }


    private func tryConnect() {
        guard !isBackoffActive else {
            logger.debug("connect: backoff is active")
            return
        }

        retryAttempt += 1

        logger.debug("connect: retry open connection. Attempt \(retryAttempt)")

        hub.updateState(
            .reconnecting(
                attempt: retryAttempt,
                maxAttempts: context.networkConfig.realtime.maxRetries
            )
        )

        let delay = calculateBackoff(attempt: retryAttempt)
        logger.debug("connect: calculated backoff delay \(delay)")

        backoffWorkItem?.cancel()

        isBackoffActive = true

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            self.logger.debug("backoffTask started")

            defer {
                self.isBackoffActive = false
            }

            guard self.realtimeEnabled else {
                self.logger.debug("realtimeEnabled is false, skipping")
                return
            }

            self.realtimeTransport.connect()
        }

        backoffWorkItem = workItem

        queueTimer.asyncAfter(
            deadline: .now() + delay,
            execute: workItem
        )
    }
}
