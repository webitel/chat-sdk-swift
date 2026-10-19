//
//  WssRealtimeTransport.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 07.04.2026.
//

import Foundation


internal final class WssRealtimeTransport: NSObject, RealtimeTransport, URLSessionWebSocketDelegate {
    
    private let sslDelegate: URLSessionDelegate
    private let headerProvider: HeaderProvider
    private let context: ClientContext
    private var socket: URLSessionWebSocketTask?
    
    private weak var observer: RealtimeObserver?
    // guarded by syncConnectQueue
    private var _connectionState: ConnectionState = .disconnected

    var connectionState: ConnectionState {
        syncConnectQueue.sync { _connectionState }
    }

    private let wssPath = "/im/ws"
    
    private let logger = SDKLogger.make("chat.realtime")
    private let syncConnectQueue = DispatchQueue(label: "chat.realtime")
        
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = false
        config.timeoutIntervalForRequest = context.networkConfig.api.callTimeout

        return URLSession(
            configuration: config,
            delegate: self,
            delegateQueue: nil
        )
    }()
    
    private lazy var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        return encoder
    }()
    
    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
    
    init(
        context: ClientContext,
        headerProvider: HeaderProvider
    ) {
        self.context = context
        self.headerProvider = headerProvider
        
        sslDelegate = SSLPinningDelegate(
            context: self.context
        )
    }
    
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        sslDelegate.urlSession?(session,
                                   didReceive: challenge,
                                   completionHandler: completionHandler)
    }
    
    
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        let reasonText = reason.flatMap {
            String(data: $0, encoding: .utf8)
        }
        logger.debug("closed socket with code \(closeCode.rawValue), \(String(describing: reasonText))")

        let isCurrent: Bool = syncConnectQueue.sync {
            guard webSocketTask === socket else { return false }
            socket = nil
            _connectionState = stateForClose(code: closeCode.rawValue, reason: reasonText)
            return true
        }
        guard isCurrent else {
            logger.debug("ignore close from stale socket")
            return
        }
        observer?.onClosed(code: closeCode.rawValue, reason: reasonText ?? "No reason")
    }


    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        let isCurrent: Bool = syncConnectQueue.sync {
            guard webSocketTask === socket else { return false }
            _connectionState = .connected
            return true
        }
        guard isCurrent else {
            logger.debug("ignore open from stale socket")
            return
        }
        logger.debug("WebSocket connected")
        observer?.onOpen()
    }
    
    
    func setObserver(_ observer: RealtimeObserver) {
        self.observer = observer
    }
    
    
    func connect() {
        tryOpenStream()
    }
    
    
    func disconnect() {
        // client already updates its own state; a late onClosed would race with connect()
        closeStream(reason: "Client close connect", notify: false)
    }
    
    
    func onAuthUpdated(_ token: String) {
        let connectedSocket: URLSessionWebSocketTask? = syncConnectQueue.sync {
            _connectionState == .connected ? socket : nil
        }
        if let connectedSocket {
            logger.debug("send new auth in stream; \(token.maskedToken)")

            let payload: [String: Any] = [
                "x-webitel-access": token,
                "x-webitel-client": context.clientToken
            ]

            if let data = try? JSONSerialization.data(withJSONObject: payload),
               let jsonString = String(data: data, encoding: .utf8) {
                connectedSocket.send(.string(jsonString), completionHandler: { error in
                    if let error = error {
                        self.logger.error("error send auth: \(error)")
                    }
                })
            }
        }
    }
    
    
    private func sendAck(eventId: String, task: URLSessionWebSocketTask) {
        logger.debug("Send ACK for eventId=\(eventId)")

        let payload: [String: Any] = [
            "type": "ack",
            "event_id": eventId
        ]

        if let data = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: data, encoding: .utf8) {
            task.send(.string(jsonString)) { error in
                if let error {
                    self.logger.error("Error send ACK: \(error)")
                }
            }
        }
    }
    
    
    private func tryOpenStream() {
        var openedSocket: URLSessionWebSocketTask?
        var buildError: ChatError?
        syncConnectQueue.sync {
            guard !_connectionState.isAlive
            else {
                logger.warning(
                    "stream already active - \(_connectionState)"
                )
                
                return
            }
            
            _connectionState = .connecting
            
            let request: URLRequest
            
            do {
                request = try buildWebSocketRequest()
            } catch {
                _connectionState = .failed(error.asChatError)
                buildError = error.asChatError
                return
            }

            logger.debug("WSS: \(wssPath)")
            let task = session.webSocketTask(with: request)
            socket = task

            task.resume()
            openedSocket = task
        }
        // outside of sync: observer may call connect() synchronously
        if let buildError {
            observer?.onError(buildError)
            return
        }
        if let openedSocket {
            listen(openedSocket)
        }
    }
    
    
    private func buildWebSocketRequest() throws -> URLRequest {
        guard var components = URLComponents(
            url: context.baseURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw ChatError.invalidURL
        }
        
        components.scheme = "wss"
        
        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let wsPathTrimmed = wssPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        components.path = "/\(basePath)/\(wsPathTrimmed)"
        
        guard let url = components.url else {
            logger.error(
                "Failed to build from baseURL=\(context.baseURL) wssPath=\(wssPath)"
            )
            throw ChatError.invalidURL
        }
        
        var request = URLRequest(url: url)
        
        headerProvider.commonHeaders().forEach {
            request.addValue($1, forHTTPHeaderField: $0)
        }
            
        return request
    }
    
    
    private func listen(_ task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            guard let self else { return }
            
            switch result {
                    
                case .success(let message):
                    let isCurrent = syncConnectQueue.sync { task === self.socket }
                    guard isCurrent else {
                        logger.debug("ignore message from stale socket")
                        return
                    }

                    switch message {
                        case .string(let text):
                            handleMessage(text, task: task)

                        case .data(let data):
                            if let text =
                                String(data: data, encoding: .utf8) {
                                handleMessage(text, task: task)
                            }
                        @unknown default:
                            break
                    }
                    
                    // handleMessage may close the stream (disconnected event)
                    let stillCurrent = syncConnectQueue.sync { task === self.socket }
                    if stillCurrent {
                        listen(task)
                    }

                case .failure(let error):
                    onError(error.asChatError, task: task)
            }
        }
    }


    private func onError(_ error: ChatError, task: URLSessionWebSocketTask) {
        // server close frame may fail receive() before didCloseWith arrives;
        // keep the close code so auth-related closes (401/1008) are not lost
        let closeCode = task.closeCode
        let isClosedByServer = closeCode != .invalid
        let reason = task.closeReason.flatMap { String(data: $0, encoding: .utf8) }

        // handshake rejected (e.g. 401 on upgrade) - map HTTP status so auth refresh kicks in
        var error = error
        if let status = (task.response as? HTTPURLResponse)?.statusCode, status >= 400 {
            error = ChatError.from(statusCode: status, message: error.localizedDescription)
        }

        let isCurrent: Bool = syncConnectQueue.sync {
            guard task === socket else { return false }
            self.socket = nil
            _connectionState = isClosedByServer
                ? stateForClose(code: closeCode.rawValue, reason: reason)
                : .failed(error)
            return true
        }
        guard isCurrent else { return }

        if isClosedByServer {
            observer?.onClosed(code: closeCode.rawValue, reason: reason ?? "No reason")
        } else {
            observer?.onError(error)
        }
    }


    private func stateForClose(code: Int, reason: String?) -> ConnectionState {
        if code == URLSessionWebSocketTask.CloseCode.normalClosure.rawValue {
            return .disconnected
        }
        return .failed(ChatError.from(statusCode: code, message: reason ?? "No reason"))
    }

    
    private func handleMessage(
        _ text: String,
        task: URLSessionWebSocketTask
    ) {
        logger.debug("received \(text)")
        
        guard
            let data = text.data(
                using: .utf8
            ),
            let json =
                try? JSONSerialization
                .jsonObject(with: data)
                as? [String: Any],
            let payload =
                json["payload"]
                as? [String: Any]
        else {
            return
        }
        
        let event = RealtimeEventType.from(payload: payload)
        switch event {
                
            case .connected:
                handleConnected(payload)
                
            case .disconnected:
                handleDisconnected(payload)
                
            case .message:
                if let eventId = json["id"] as? String,
                    !eventId.isEmpty {
                    sendAck(eventId: eventId, task: task)
                }
                
                handleMessageEvent(payload)
                
            case .ack:
                handleAck(payload)
                
            case .error:
                handleError(payload)
                
            case .ping:
                handlePing(payload)
                
            case .dialogCreated:
                handleDialogCreated(payload)
                
            case .unsupported:
                logger.warning("unsupported event - \(payload)")
        }
    }
    
    
    private func handleMessageEvent(
        _ payload: [String: Any]
    ) {
        guard let body = payload[RealtimeEventType.message.rawValue],
              JSONSerialization.isValidJSONObject(body) else {
            logger.warning("message event without body")
            return
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: body)
            let dto = try jsonDecoder.decode(MessageDto.self, from: data)
            
            observer?.onMessage(dto)
            
        } catch {
            logger.warning("Failed to decode message event: \(error)")
        }
    }
    
    
    private func handleDialogCreated(
        _ payload: [String: Any]
    ) {
        guard let body = payload[RealtimeEventType.dialogCreated.rawValue],
              JSONSerialization.isValidJSONObject(body) else {
            logger.warning("new dialog event without body")
            return
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: body)
            let dto = try jsonDecoder.decode(DialogDto.self, from: data)
            
            observer?.onNewDialog(dto)
            
        } catch {
            logger.warning("Failed to decode new dialog event: \(error)")
        }
    }
    
    private func handleError(_ payload: [String: Any]) {}
    private func handleAck(_ payload: [String: Any]) {}
    private func handleConnected(_ payload: [String: Any]) {}
    
    
    private func handleDisconnected(_ payload: [String: Any]) {
        guard let body = payload[RealtimeEventType.disconnected.rawValue],
              JSONSerialization.isValidJSONObject(body) else {
            logger.warning("disconnect event without body")
            closeStream()
            return
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: body)
            let dto = try jsonDecoder.decode(DisconnectDto.self, from: data)
            
            let code = dto.code ?? URLSessionWebSocketTask.CloseCode.normalClosure.rawValue
            closeStream(code: wireCloseCode(code), reason: dto.reason, notifyCode: code)
            
        } catch {
            logger.warning("Failed to decode Disconnect event: \(error)")
            closeStream()
        }
    }
    
    
    /// Close codes allowed in a close frame (RFC 6455 7.4); others (e.g. HTTP 401) fall back to 1000.
    private func wireCloseCode(_ code: Int) -> URLSessionWebSocketTask.CloseCode {
        let isSendable = (1000...1003).contains(code)
            || (1007...1011).contains(code)
            || (3000...4999).contains(code)
        guard isSendable else { return .normalClosure }
        return URLSessionWebSocketTask.CloseCode(rawValue: code) ?? .normalClosure
    }


    /// - Parameter notifyCode: server-provided code reported to the observer
    ///   (may differ from the wire `code`); nil means a client-initiated close.
    /// - Parameter notify: whether to report `onClosed` to the observer.
    private func closeStream(
        code: URLSessionWebSocketTask.CloseCode = .normalClosure,
        reason: String? = nil,
        notifyCode: Int? = nil,
        notify: Bool = true
    ) {
        let reportedCode = notifyCode ?? code.rawValue
        let didClose: Bool = syncConnectQueue.sync {
            guard let socket else {
                // no active socket (e.g. after failure) - still reset state
                _connectionState = .disconnected
                return false
            }
            logger.debug("closeStream: code=\(code), reason=\(reason ?? "-")")

            let data = reason?.data(using: .utf8)
            socket.cancel(with: code, reason: data)

            self.socket = nil
            _connectionState = notifyCode == nil
                ? .disconnected
                : stateForClose(code: reportedCode, reason: reason)
            return true
        }
        // outside of sync: observer may call connect() synchronously
        if didClose && notify {
            observer?.onClosed(code: reportedCode, reason: reason ?? "No reason")
        }
    }
    
    
    private func handlePing(
        _ payload: [String: Any]
    ) {
//        socket?.sendPing { error in
//
//            if let error {
//
//                self.listener?.onError(
//                    error.asChatError
//                )
//            }
//        }
    }
}

