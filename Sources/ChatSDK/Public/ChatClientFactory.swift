//
//  ChatClientFactory.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 02.04.2026.
//

import Foundation
import Logging

public enum ChatClientFactory {

    public static func create(
        baseURL: URL,
        authMethod: AuthMethod,
        configure: (inout ChatClientConfiguration) -> Void = { _ in }
    ) -> any ChatClient {

        var config = ChatClientConfiguration()
        configure(&config)
        
        let deviceProvider = DeviceIdProvider()
        let systemDetails = SystemDetails()

        let context = ClientContext(
            baseURL: baseURL,
            clientToken: config.clientToken ?? "",
            networkConfig: config.networkConfig,
            authMethod: authMethod,
            deviceId: config.deviceId ?? deviceProvider.getDeviceId(),
            agent: systemDetails.userAgent,
            autoRefreshAuth: config.autoRefreshAuth,
            pinnedHashes: config.pinnedPublicKeys
        )
    
        SDKLogger.configure(
            level: config.logLevel, handlerFactory: config.logHandler
        )

        let headerProvider = HeaderProvider(
            context: context
        )
        
        let realtimeTransport = WssRealtimeTransport(
            context: context,
            headerProvider: headerProvider
        )

        let authManager = AuthAPIClient(
            context: context,
            headerProvider: headerProvider
        )

        let apiProvider = ChatAPIClient(
            context: context,
            headerProvider: headerProvider
        )
        
        
        let fileTransferClient = HttpFileTransferClient(
            context: context,
            headerProvider: headerProvider
        )
        
        authManager.addTokenListener { token in
            realtimeTransport.onAuthUpdated(token)
        }

        let realtimeHub = RealtimeHub()
        let dialogFactory = DialogFactory()
        
        SDKLogger.make("ChatSDK")
            .debug("created ChatClient with context: \(context)")
    
        let client: DefaultChatClient = DefaultChatClient(
            context: context,
            apiProvider: apiProvider,
            authManager: authManager,
            dialogFactory: dialogFactory,
            hub: realtimeHub,
            realtimeTransport: realtimeTransport,
            fileTransferClient: fileTransferClient
        )
        return client as any ChatClient
    }
}

