//
//  NetworkConfig.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 27.03.2026.
//

import Foundation


/// Root network configuration used by the chat client.
public struct NetworkConfig {

    /// HTTP API configuration.
    public let api: ApiConfig

    /// Realtime WebSocket configuration.
    public let realtime: RealtimeConfig


    public init(
        api: ApiConfig = ApiConfig(),
        realtime: RealtimeConfig = RealtimeConfig()
    ) {
        self.api = api
        self.realtime = realtime
    }

    public static let `default` = NetworkConfig()
}


/// Configuration for realtime (WebSocket) connection behavior.
public struct RealtimeConfig {

    /// Maximum number of reconnect attempts before giving up.
    public let maxRetries: Int

    /// Interval between ping frames to keep the connection alive.
    public let pingInterval: TimeInterval

    /// Base delay used for calculating reconnect backoff.
    public let retryBaseDelay: TimeInterval

    /// Maximum delay between reconnect attempts.
    public let maxRetryDelay: TimeInterval


    public init(
        maxRetries: Int = 10,
        pingInterval: TimeInterval = 10,
        retryBaseDelay: TimeInterval = 0.5,
        maxRetryDelay: TimeInterval = 10
    ) {
        self.maxRetries = maxRetries
        self.pingInterval = pingInterval
        self.retryBaseDelay = retryBaseDelay
        self.maxRetryDelay = maxRetryDelay
    }
}


/// Configuration for HTTP API requests.
public struct ApiConfig {

    /// Maximum time allowed for an API call before it times out.
    public let callTimeout: TimeInterval


    public init(
        callTimeout: TimeInterval = 5
    ) {
        self.callTimeout = callTimeout
    }
}
