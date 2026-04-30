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
    
    
    public var logHandler: ((String) -> LogHandler)?


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
