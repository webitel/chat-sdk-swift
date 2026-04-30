//
//  ConnectionState.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 20.03.2026.
//

import Foundation


public enum ConnectionState: Equatable {

    /// SDK is trying to establish a realtime connection.
    case connecting

    /// Realtime connection is active.
    case connected

    /// SDK is fully disconnected and will NOT reconnect automatically.
    /// Happens after explicit disconnect().
    case disconnected

    /// Connection was lost unexpectedly and SDK is trying to reconnect.
    /// - Parameters:
    ///   - attempt: current attempt number
    ///   - maxAttempts: maximum retry attempts
    case reconnecting(attempt: Int, maxAttempts: Int)

    /// Connection failed with an error.
    case failed(ChatError)
}


extension ConnectionState: CustomStringConvertible {

    public var description: String {
        switch self {
        case .connecting:
            return "Connecting"

        case .connected:
            return "Connected"

        case .disconnected:
            return "Disconnected"

        case let .reconnecting(attempt, maxAttempts):
            return "Reconnecting(attempt: \(attempt), maxAttempts: \(maxAttempts))"

        case let .failed(error):
                return "Failed(message: \(error.errorDescription))"
        }
    }
}


public extension ConnectionState {
    var isConnected: Bool {
        if case .connected = self {
            return true
        }

        return false
    }

    var isConnecting: Bool {
        switch self {
        case .connecting,
             .reconnecting:
            return true

        default:
            return false
        }
    }

    var isAlive: Bool {
        switch self {
        case .connected,
             .connecting,
             .reconnecting:
            return true

        case .disconnected:
            return false
                
        case .failed(_):
            return false
        }
    }
}
