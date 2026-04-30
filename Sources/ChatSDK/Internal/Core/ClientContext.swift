//
//  File.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation


internal struct ClientContext {
    public let baseURL: URL
    public let clientToken: String
    public let networkConfig: NetworkConfig
    public let authMethod: AuthMethod
    public let deviceId: String
    public let agent: String
    public var pinnedHashes: [String]

    public init(
        baseURL: URL,
        clientToken: String,
        networkConfig: NetworkConfig,
        authMethod: AuthMethod,
        deviceId: String,
        agent: String,
        pinnedHashes: [String] = []
    ) {
        self.baseURL = baseURL
        self.clientToken = clientToken
        self.networkConfig = networkConfig
        self.authMethod = authMethod
        self.deviceId = deviceId
        self.agent = agent
        self.pinnedHashes = pinnedHashes
    }
}
