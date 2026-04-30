//
//  HeaderProvider.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 25.03.2026.
//

import Foundation


internal final class HeaderProvider {
    private let logger = SDKLogger.make("chat.header")

    private let context: ClientContext
    private let lock = NSLock()
    private var accessToken: String?

    init(context: ClientContext) {
        self.context = context
    }


    func updateAccessToken(_ token: String?) {
        lock.lock()
        accessToken = token
        lock.unlock()
    }


    func commonHeaders() -> [String: String] {
        lock.lock()
        let token = accessToken
        lock.unlock()

        var headers: [String: String] = [
            "x-webitel-device": context.deviceId,
            "x-webitel-client": context.clientToken,
            "User-Agent": context.agent
        ]

        if let token, !token.isEmpty {
            headers["x-webitel-access"] = token
        }
        
        headers.forEach { key, value in
            let logValue: String
            
            if key.lowercased() == "x-webitel-access" {
                logValue = value.maskedToken
            } else {
                logValue = value
            }
            
            logger.debug("Adding header: \(key): \(logValue)")
        }
        
        return headers
    }


    func hasAuth() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return accessToken?.isEmpty == false
    }
}


extension URLRequest {

    mutating func applyHeaders(
        _ provider: HeaderProvider
    ) {

        provider.commonHeaders()
            .forEach {
                setValue(
                    $0.value,
                    forHTTPHeaderField: $0.key
                )
            }
    }
}
