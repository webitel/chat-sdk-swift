//
//  DeviceIdProvider.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 24.04.2026.
//

import Foundation


final class DeviceIdProvider {
    private let key = "com.webitel.chat.sdk.deviceId"
    
    func getDeviceId() -> String {
        if let existing = KeychainHelper.get(key) {
            return existing
        }

        let newId = UUID().uuidString
        KeychainHelper.set(newId, for: key)

        return newId
    }
}
