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
    private(set) var connectionState: ConnectionState = .disconnected
    
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
        socket = nil
        connectionState = ConnectionState.disconnected
        observer?.onClosed(code: closeCode.rawValue, reason: reasonText ?? "No reason")
    }
    
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        logger.debug("WebSocket connected")
        connectionState = .connected
        observer?.onOpen()
    }
    
    
    func setObserver(_ observer: RealtimeObserver) {
        self.observer = observer
    }
    
    
    func connect() {
        tryOpenStream()
    }
    
    
    func disconnect() {
        closeStream(reason: "Client close connect")
    }
    
    
    func onAuthUpdated(_ token: String) {
        if connectionState == .connected {
            logger.debug("send new auth in stream; \(token.maskedToken)")

            let payload: [String: Any] = [
                "x-webitel-access": token,
                "x-webitel-client": context.clientToken
            ]

            if let data = try? JSONSerialization.data(withJSONObject: payload),
               let jsonString = String(data: data, encoding: .utf8) {
                socket?.send(.string(jsonString), completionHandler: { error in
                    if let error = error {
                        self.logger.error("error send auth: \(error)")
                    }
                })
            }
        }
    }
    
    
    private func sendAck(eventId: String) {
        logger.debug("Send ACK for eventId=\(eventId)")

        let payload: [String: Any] = [
            "type": "ack",
            "event_id": eventId
        ]

        if let data = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: data, encoding: .utf8) {
            socket?.send(.string(jsonString)) { error in
                if let error {
                    self.logger.error("Error send ACK: \(error)")
                }
            }
        }
    }
    
    
    private func tryOpenStream() {
        var shouldStartListening = false
        syncConnectQueue.sync {
            guard !connectionState.isAlive
            else {
                logger.warning(
                    "stream already active - \(connectionState)"
                )
                
                return
            }
            
            connectionState = .connecting
            
            let request: URLRequest
            
            do {
                request = try buildWebSocketRequest()
            } catch {
                observer?.onError(error.asChatError)
                return
            }
            
            logger.debug("WSS: \(wssPath)")
            socket = session.webSocketTask(with: request)
            
            socket?.resume()
            shouldStartListening = true
        }
        if shouldStartListening {
            listen()
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
    
    
    private func listen() {
        socket?.receive { [weak self] result in
            guard let self else { return }
            
            switch result {
                    
                case .success(let message):
                    switch message {
                        case .string(let text):
                            handleMessage(text)
                            
                        case .data(let data):
                            if let text =
                                String(data: data, encoding: .utf8) {
                                handleMessage(text)
                            }
                        @unknown default:
                            break
                    }
                    
                    listen()
                    
                case .failure(let error):
                    onError(error.asChatError)
            }
        }
    }
    
    
    private func onError(_ error: ChatError) {
        guard socket != nil else { return }
        self.socket = nil
        connectionState = .failed(error)
        observer?.onError(error)
    }
    
    
    private func handleMessage(
        _ text: String
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
                    sendAck(eventId: eventId)
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
        do {
            let data = try JSONSerialization.data(withJSONObject: payload[RealtimeEventType.message.rawValue]!)
            let dto = try jsonDecoder.decode(MessageDto.self, from: data)
            
            observer?.onMessage(dto)
            
        } catch {
            logger.warning("Failed to decode message event: \(error)")
        }
    }
    
    
    private func handleDialogCreated(
        _ payload: [String: Any]
    ) {
        do {
            let data = try JSONSerialization.data(withJSONObject: payload[RealtimeEventType.dialogCreated.rawValue]!)
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
        do {
            let data = try JSONSerialization.data(withJSONObject: payload[RealtimeEventType.disconnected.rawValue]!)
            let dto = try jsonDecoder.decode(DisconnectDto.self, from: data)
            
            closeStream(code: URLSessionWebSocketTask.CloseCode.init(rawValue: dto.code ?? 1000) ?? .normalClosure, reason: dto.reason)
            
        } catch {
            logger.warning("Failed to decode Disconnect event: \(error)")
            closeStream()
        }
    }
    
    
    private func closeStream(
        code: URLSessionWebSocketTask.CloseCode = .normalClosure,
        reason: String? = nil
    ) {
        syncConnectQueue.sync {
            guard let socket else { return }
            logger.debug("closeStream: code=\(code), reason=\(reason ?? "-")")
            
            let data = reason?.data(using: .utf8)
            socket.cancel(with: code, reason: data)
            
            self.socket = nil
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

