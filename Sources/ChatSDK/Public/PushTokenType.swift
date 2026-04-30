//
//  PushTokenType.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 26.03.2026.
//

import Foundation


/// An enumeration representing the types of push notification tokens.
///
/// This enum defines the possible types of push notification tokens that can be used for registering a device to receive push notifications.
///
/// - Cases:
///   - apns: Apple Push Notification Service token.
///   - fcm: Firebase Cloud Messaging token.
public enum PushTokenType {
    case apns, fcm
}
