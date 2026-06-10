//
//  AuthAPIClient.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 25.03.2026.
//

import Foundation


final class AuthAPIClient: AuthService {

    private let context: ClientContext
    private let sslDelegate: SSLPinningDelegate
    private let headerProvider: HeaderProvider

    private let loginPath = "/api/v1/auth/token"
    private let logoutPath = "/api/v1/auth/logout"

    private var listeners: [(String) -> Void] = []

    private var refreshTask: Task<Void, Error>?

    private(set) var currentContact: ContactDto?
    
    private let logger = SDKLogger.make("chat.auth")
    
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
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
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
    
    
    func ensureAuthValid() async throws {
        logger.debug("ensure auth valid")
        if headerProvider.hasAuth() {
            return
        }
        
        try await refresh()
    }

    
    func refresh() async throws {
        logger.debug("refresh started")
        if let task = refreshTask {
            logger.debug("refresh auth already in progress")
            return try await task.value
        }

        let task = Task {
            try await performRefresh()
        }

        refreshTask = task

        defer {
            refreshTask = nil
        }

        return try await task.value
    }

    
    func endSession() async throws {
        guard headerProvider.hasAuth()
        else { return }

        let request = try buildRequest(
            path: logoutPath,
            method: "POST",
            body: EmptyBody()
        )
        logger.debug("POST: \(logoutPath)")
        
        try await perform(request) {
            try self.parseLogoutResponse(
                data: $0,
                response: $1
            )
        }
    }
    
    
    func clearAuth() {
        headerProvider.updateAccessToken(nil)
    }

    
    func addTokenListener(
        _ listener: @escaping (String) -> Void
    ) {
        listeners.append(listener)
    }

    
    private func performRefresh() async throws {

        switch context.authMethod {

        case .contact(let identity):
                logger.debug("Using contact identity for login")
            let token = try await userLogin(identity)

            headerProvider.updateAccessToken(token)

        case .token(let provider):
            let token = provider()
                logger.debug("Using token from provider - \(token.maskedToken)")
            headerProvider.updateAccessToken(token)

            try await inspect()

            notifyUpdate(token)
        }
    }

    
    private func userLogin(
        _ contact: ContactIdentity
    ) async throws -> String {

        let body = LoginRequestDto(
            clientId: context.clientToken,
            identity: contact
        )

        let request = try buildRequest(
            path: loginPath,
            method: "POST",
            body: body
        )
        logger.debug("POST: \(loginPath)")
        
        return try await perform(request) {
            try self.parseLoginResponse(
                data: $0,
                response: $1,
                contact: contact
            )
        }
    }

    
    private func inspect() async throws {
        let request = try buildRequest(
            path: loginPath,
            method: "GET",
            body: Optional<EmptyBody>.none
        )

        logger.debug("GET: \(loginPath)")
        
        try await perform(request) {
            try self.parseInspectResponse(
                data: $0,
                response: $1
            )
        }
    }
    
    
    private func parseLoginResponse(
        data: Data,
        response: HTTPURLResponse,
        contact: ContactIdentity
    ) throws -> String {
        let validData =
            try response.validate(data: data, logger: logger)
        
        let dto = try jsonDecoder.decode(
            LoginResponseDto.self,
            from: validData
        )
        
        logger.debug("login successful")
        
        guard
            let token = dto.token?.accessToken,
            !token.isEmpty
        else {
            logger.error("access_token missing")
            throw ChatError.invalidResponse
        }

        currentContact = dto.contact ?? ContactDto(
            iss: contact.sub,
            name: contact.iss,
            id: contact.name,
            source: contact.iss,
            isBot: false
        )
        logger.debug("contact: \(currentContact)")
        
        notifyUpdate(token)

        return token
    }
    
    
    private func parseInspectResponse(
        data: Data,
        response: HTTPURLResponse
    ) throws {
        let validData =
            try response.validate(data: data, logger: logger)
        
        let dto = try jsonDecoder.decode(
            InspectResponseDto.self,
            from: validData
        )

        guard let contact = dto.contact else {
            logger.error("contact missing")
            throw ChatError.invalidResponse
        }
        
        currentContact = contact
    }
    
    
    private func parseLogoutResponse(
        data: Data,
        response: HTTPURLResponse
    ) throws {
        try response.validate(data: data, logger: logger)
        
        headerProvider.updateAccessToken(nil)
        currentContact = nil
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
    

    private func notifyUpdate(
        _ token: String
    ) {
        listeners.forEach {
            $0(token)
        }
    }

    
    private func buildRequest<T: Encodable>(
        path: String,
        method: String,
        body: T?
    ) throws -> URLRequest {

        guard let url = buildURL(path) else {
            throw ChatError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        headerProvider.commonHeaders().forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }

        if let body {
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
            request.httpBody = try jsonEncoder.encode(body)
        }

        return request
    }
    

    private func buildURL(
        _ path: String
    ) -> URL? {
        URLComponents(
            url: context.baseURL
                .appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )?.url
    }
}


private struct EmptyBody: Encodable {}


extension String {
    var maskedToken: String {
        guard count > 14 else {
            return "***"
        }
        let prefix = prefix(6)
        let suffix = suffix(6)
        return "\(prefix)...\(suffix)"
    }
}
