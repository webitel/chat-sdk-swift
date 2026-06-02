//
//  ChatAPIClient.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation
import Logging

internal class ChatAPIClient: ChatAPI {
    
    private let sslDelegate: SSLPinningDelegate
    private let headerProvider: HeaderProvider
    private let context: ClientContext
    
    private let dialogsPath = "/api/v1/threads"
    private let contactsPath = "/api/v1/contacts"
    private let registerPath = "/api/v1/auth/devices"
    private let sendTextPath = "/api/v1/messages/text"
    private let sendFilePath = "/api/v1/messages/document"
    private let sendContactPath = "/api/v1/messages/contact"
    private let sendLocationPath = "/api/v1/messages/location"
    private let sendActionPath = "/api/v1/messages/interactive"
    
    private let logger = SDKLogger.make("chat.api")
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        
        configuration.timeoutIntervalForRequest =
            context.networkConfig.api.callTimeout

        configuration.timeoutIntervalForResource =
            context.networkConfig.api.callTimeout

        configuration.waitsForConnectivity = false

        return URLSession(
            configuration: configuration,
            delegate: sslDelegate,
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
    
    
    func getDialogs(
        _ request: DialogRequest
    ) async throws -> Page<DialogDto> {
        
        guard let urlRequest = buildDialogsRequest(request) else {
            throw ChatError.invalidURL
        }
        
        return try await perform(urlRequest) {
            try self.parseDialogsResponse(
                data: $0,
                response: $1,
                request: request
            )
        }
    }
    
    
    func getContacts(
        _ request: ContactRequest
    ) async throws -> Page<ContactDto> {
        
        guard let httpRequest = buildContactsRequest(request) else {
            throw ChatError.invalidURL
        }
        
        return try await perform(httpRequest) {
            try self.parseContactsResponse(
                data: $0,
                response: $1,
                request: request
            )
        }
    }
    
    
    func getHistory(
        dialogId: String,
        request: HistoryRequest
    ) async throws -> HistoryResponseDto {
        
        guard let httpRequest = buildHistoryRequest(
            dialogId: dialogId,
            request: request
        ) else {
            throw ChatError.invalidURL
        }
        
        return try await perform(httpRequest) {
            try self.parseHistoryResponse(
                data: $0,
                response: $1,
                request: request
            )
        }
    }
    
    
    func registerDevice(
        pushToken: String,
        pushTokenType: PushTokenType
    ) async throws {
        
        guard let request = buildRegisterDeviceRequest(
            pushToken,
            pushTokenType
        ) else {
            throw ChatError.invalidURL
        }
        
        _ = try await perform(request) {
            try self.parseRegisterResponse(
                data: $0,
                response: $1
            )
        }
    }
    
    
    func sendAction(
        action: MessageAction
    ) async throws {
        
        guard let request = buildSendActionRequest(action: action) else {
            throw ChatError.invalidURL
        }
        
        _ = try await perform(request) {
            try self.parseRegisterResponse(
                data: $0,
                response: $1
            )
        }
    }
    
    
    @discardableResult
    func sendMessage(
        to target: MessageTarget,
        options: MessageOptions
    ) async throws -> String {
        
        guard let request = buildSendMessageRequest(
            target: target,
            options: options
        ) else {
            throw ChatError.invalidURL
        }
        
        return try await perform(request) {
            try self.parseSendMessageResponse(
                data: $0,
                response: $1
            )
        }
    }
    
        
    private func perform<T>(
        _ request: URLRequest,
        parser: (Data, HTTPURLResponse) throws -> T
    ) async throws -> T {
        logger.debug("Sending request: \(request.url?.absoluteString ?? "nil")")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            logger.debug("""
                Received response:
                url: \(request.url?.absoluteString ?? "nil")
                size: \(data.count) bytes
                status: \((response as? HTTPURLResponse)?.statusCode ?? -1)
              """)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ChatError.invalidResponse
            }
            
            return try parser(data, httpResponse)
            
        } catch let error as ChatError {
            throw error
            
        } catch {
            if let err = sslDelegate.lastSSLError {
                logger.error("SSL pinning error: \(err)")
                throw err
            }
            
            logger.error("Request failed: \(error)")
            throw ChatError.unknown(
                code: ChatError.unknownCode,
                message: error.localizedDescription,
                underlying: error
            )
        }
    }
    
    
    private func buildRegisterDeviceRequest(
        _ pushToken: String,
        _ type: PushTokenType
    ) -> URLRequest? {
        
        guard let url = buildURL(path: registerPath) else {
            return nil
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        
        headerProvider.commonHeaders().forEach {
            urlRequest.setValue($1, forHTTPHeaderField: $0)
        }
        
        do {
            let body: RegisterDeviceRequestDto
            
            switch type {
                case .fcm:
                    body = RegisterDeviceRequestDto(fcm: pushToken)
                case .apns:
                    body = RegisterDeviceRequestDto(apn: pushToken)
            }
            
            urlRequest.httpBody = try jsonEncoder.encode(body)
        } catch {
            return nil
        }
        
        return urlRequest
    }
    
    
    private func buildDialogsRequest(
        _ request: DialogRequest
    ) -> URLRequest? {
        
        guard let url = buildDialogsURL(request) else {
            return nil
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        headerProvider.commonHeaders().forEach {
            urlRequest.setValue($1, forHTTPHeaderField: $0)
        }
        
        return urlRequest
    }
    
    
    private func buildContactsRequest(
        _ request: ContactRequest
    ) -> URLRequest? {
        
        guard let url = buildContactsURL(request) else {
            return nil
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        headerProvider.commonHeaders().forEach {
            urlRequest.setValue($1, forHTTPHeaderField: $0)
        }
        
        return urlRequest
    }
    
    
    private func buildSendMessageRequest(
        target: MessageTarget,
        options: MessageOptions
    ) -> URLRequest? {

        guard
            let endpoint = buildSendMessageComponents(
                target: target,
                options: options
            )

        else {
            return nil
        }

        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        headerProvider.commonHeaders().forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }

        request.httpBody = endpoint.body

        return request
    }


    private func buildSendMessageComponents(
        target: MessageTarget,
        options: MessageOptions
    ) -> RequestComponents? {
        switch options.content {
            case .text(let content):
                guard let url = buildURL(path: sendTextPath) else {
                    return nil
                }

                let dto = SendTextMessageRequestDto(
                    target: target,
                    text: content,
                    sendId: options.sendId
                )

                return RequestComponents(
                    url: url,
                    body: try? jsonEncoder.encode(dto)
                )

            case .attachments(let attachments):
                guard let url = buildURL(path: sendFilePath) else {
                    return nil
                }

                let dto = SendAttachmentsRequestDto(
                    target: target,
                    text: nil,
                    attachments: attachments,
                    sendId: options.sendId
                )

                return RequestComponents(
                    url: url,
                    body: try? jsonEncoder.encode(dto)
                )

            case .contact(let content):
                guard let url = buildURL(path: sendContactPath) else {
                    return nil
                }
                
                let dto = SendContactRequestDto(
                    target: target,
                    name: content.name,
                    phoneNumber: content.phone,
                    email: content.email,
                    sendId: options.sendId
                )

                return RequestComponents(
                    url: url,
                    body: try? jsonEncoder.encode(dto)
                )

            case .location(let content):
                guard let url = buildURL(path: sendLocationPath) else {
                    return nil
                }

                let dto = SendLocationRequestDto(
                    target: target,
                    name: content.name,
                    address: content.address,
                    latitude: content.latitude,
                    longitude: content.longitude,
                    sendId: options.sendId
                )

                return RequestComponents(
                    url: url,
                    body: try? jsonEncoder.encode(dto)
                )

            case .composite(let content):
                guard let url = buildURL(path: sendFilePath) else {
                    return nil
                }

                let dto = SendAttachmentsRequestDto(
                    target: target,
                    text: content.text,
                    attachments: content.attachments,
                    sendId: options.sendId
                )

                return RequestComponents(
                    url: url,
                    body: try? jsonEncoder.encode(dto)
                )
        }
    }
    
    
    private func buildSendActionRequest(
        action: MessageAction
    ) -> URLRequest? {
        guard let components = buildSendActionComponents(
            action: action
        ) else {
            return nil
        }

        var request = URLRequest(url: components.url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        headerProvider.commonHeaders().forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }

        request.httpBody = components.body
        return request
    }


    private func buildSendActionComponents(
        action: MessageAction
    ) -> RequestComponents? {

        switch action {
            case .buttonClick(let action):
                guard let url = buildURL(
                    path: "\(sendActionPath)/\(action.messageId)/callback"
                ) else {
                    return nil
                }

                let body = ActionRequestDto(
                    buttonCode: action.buttonId,
                    callbackData: action.data
                )

                return RequestComponents(
                    url: url,
                    body: try? jsonEncoder.encode(body)
                )
        }
    }
    
    
    private struct RequestComponents {
        let url: URL
        let body: Data?
    }
    
    
    private func parseRegisterResponse(
        data: Data,
        response: HTTPURLResponse
    ) throws {
        
        let _ = try response.validate(data: data, logger: logger)
    }
    
    
    private func parseDialogsResponse(
        data: Data,
        response: HTTPURLResponse,
        request: DialogRequest
    ) throws -> Page<DialogDto> {
        
        let validData =
            try response.validate(data: data, logger: logger)
        
        let dto = try jsonDecoder.decode(
            DialogsResponseDto.self,
            from: validData
        )
        
        return Page(
            page: dto.page ?? request.page,
            items: dto.items ?? [],
            hasNext: dto.hasNext ?? false
        )
    }
    
    
    private func parseSendMessageResponse(
        data: Data,
        response: HTTPURLResponse
    ) throws -> String {
        
        let validData =
            try response.validate(data: data, logger: logger)
        
        let dto = try jsonDecoder.decode(
            SendMessageResponseDto.self,
            from: validData
        )
        
        guard !dto.id.isEmpty else {
            throw ChatError.unknown(
                code: ChatError.unknownCode,
                message: "Missing id in response",
                underlying: nil
            )
        }
        
        return dto.id
    }
    
    
    private func parseContactsResponse(
        data: Data,
        response: HTTPURLResponse,
        request: ContactRequest
    ) throws -> Page<ContactDto> {
        
        let validData =
            try response.validate(data: data, logger: logger)
        
        let dto = try jsonDecoder.decode(
            ContactsResponseDto.self,
            from: validData
        )
        
        return Page(
            page: dto.page ?? request.page,
            items: dto.items ?? [],
            hasNext: dto.hasNext ?? false
        )
    }
    
    
    private func parseHistoryResponse(
        data: Data,
        response: HTTPURLResponse,
        request: HistoryRequest
    ) throws -> HistoryResponseDto {
        
        let validData =
            try response.validate(data: data, logger: logger)
        
        return try jsonDecoder.decode(
            HistoryResponseDto.self,
            from: validData
        )
    }
    
    
    private func buildHistoryRequest(
        dialogId: String,
        request: HistoryRequest
    ) -> URLRequest? {
        
        guard let url = buildHistoryURL(
            dialogId: dialogId,
            request: request
        ) else {
            
            return nil
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        headerProvider.commonHeaders().forEach {
            urlRequest.setValue($1, forHTTPHeaderField: $0)
        }
        
        return urlRequest
    }
    
    
    private func buildHistoryURL(
        dialogId: String,
        request: HistoryRequest
    ) -> URL? {
        
        var components = URLComponents(
            url: context.baseURL
                .appendingPathComponent("/api/v1/\(dialogId)/messages"),
            resolvingAgainstBaseURL: false
        )
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "size", value: String(request.limit))
        ]
        
        if let cursor = request.cursor {
            queryItems.append(URLQueryItem(name: "cursor.id", value: cursor.messageId))
            queryItems.append(
                URLQueryItem(
                    name: "cursor.before",
                    value: cursor.direction == .newer
                    ? "true"
                    : "false"
                )
            )
        }
        
        components?.queryItems = queryItems
        
        return components?.url
    }
    
    
    private func buildContactsURL(
        _ request: ContactRequest
    ) -> URL? {
        
        var components = URLComponents(
            url: context.baseURL
                .appendingPathComponent(contactsPath),
            resolvingAgainstBaseURL: false
        )
        
        components?.queryItems = [
            URLQueryItem(name: "page",value: String(request.page)),
            URLQueryItem(name: "size", value: String(request.size))
        ]
        
        return components?.url
    }
    
    
    private func buildDialogsURL(
        _ request: DialogRequest
    ) -> URL? {

        var components = URLComponents(
            url: context.baseURL
                .appendingPathComponent(dialogsPath),
            resolvingAgainstBaseURL: false
        )

        var queryItems: [URLQueryItem] = [
            .init(name: "page", value: "\(request.page)"),
            .init(name: "size", value: "\(request.size)")
        ]

        queryItems.append(contentsOf: makeFields())

        if let filter = request.filter {
            queryItems.append(contentsOf: makeFilterItems(filter))
        }

        components?.queryItems = queryItems
        return components?.url
    }
    
    
    private func makeFilterItems(
        _ filter: DialogFilter
    ) -> [URLQueryItem] {

        var items: [URLQueryItem] = []
        if let q = filter.query {
            items.append(.init(name: "q", value: q))
        }

        items.append(contentsOf: makeArrayItems(
            name: "ids",
            values: filter.ids
        ))

        items.append(contentsOf: makeArrayItems(
            name: "types",
            values: filter.types?
                .compactMap { $0.apiKind }
                .map(String.init)
        ))

        return items
    }
    
    
    private func makeArrayItems(
        name: String,
        values: [String]?
    ) -> [URLQueryItem] {
        guard let values else { return [] }
        
        return values.map {
            URLQueryItem(name: name, value: $0)
        }
    }
    
    
    private func makeFields() -> [URLQueryItem] {
        [
            "members",
            "id",
            "subject",
            "kind",
            "last_msg"
        ].map {
            URLQueryItem(name: "fields", value: $0)
        }
    }
    
    
    private func buildURL(path: String) -> URL? {
        let components = URLComponents(
            url: context.baseURL
                .appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        return components?.url
    }
}


internal extension HTTPURLResponse {
    func validate(
        data: Data,
        logger: Logging.Logger?
    ) throws -> Data {

        guard (200...299).contains(statusCode) else {
            let message =
                String(
                    data: data,
                    encoding: .utf8
                )

            logger?.error(
                "HTTP \(statusCode): \(message ?? "")"
            )

            throw ChatError.from(
                statusCode: statusCode,
                message: message
            )
        }

        return data
    }
}


internal extension DialogType {
    var apiKind: Int? {
        switch self {
        case .direct: return 1
        case .group: return 2
        case .channel: return 3
        case .unknown: return nil
        }
    }
}
