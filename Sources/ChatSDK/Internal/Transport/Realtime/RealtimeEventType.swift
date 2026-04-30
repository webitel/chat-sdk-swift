//
//  RealtimeEventType.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 08.04.2026.
//

import Foundation


internal enum RealtimeEventType: String, CaseIterable {

    case connected = "connected_event"
    case disconnected = "disconnected_event"
    case dialogCreated = "thread_created_event"
    case message = "message_event"
    case ack = "ack_event"
    case error = "error_event"
    case ping = "ping_event"
    case unsupported

    static func from(
        payload: [String: Any]
    ) -> Self {

        for event in Self.allCases {
            if payload[event.rawValue] != nil {
                return event
            }
        }

        return .unsupported
    }
}
