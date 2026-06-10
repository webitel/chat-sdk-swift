//
//  ChatClientConfiguration.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 27.03.2026.
//

import Foundation
import Logging


public struct ChatClientConfiguration {

    public var clientToken: String?


    /// Logging level for SDK internal logs.
    ///
    /// Default: `.error`
    public var logLevel: Logger.Level = .error
    
    
    /// Custom log handler factory used to intercept and process internal SDK logs.
    public var logHandler: ((String) -> LogHandler)?

    
    /// Enables automatic token refresh and request retry on `401 Unauthorized` responses.
    ///
    /// Default value is `true`.
    ///
    /// When enabled, the SDK will:
    /// - Detect `401` responses from API requests
    /// - Request a new JWT or Contact via `AuthMethod`
    /// - Retry the original request once the token is refreshed and validated
    ///
    /// If the refreshed token is still invalid, the original request will fail with `401`.
    public var autoRefreshAuth: Bool = true


    /// Collection of Base64-encoded SHA-256 public key hashes (SPKI)
    /// used for SSL pinning.
    ///
    /// If empty, SSL pinning is disabled.
    public var pinnedPublicKeys: [String] = []


    /// Unique device identifier used for session tracking.
    ///
    /// If not provided, SDK may generate one automatically.
    public var deviceId: String?


    /// Network-related configuration.
    public var networkConfig: NetworkConfig = .default
}
