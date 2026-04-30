//
//  ConnectListener.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation


/// A protocol defining a listener for connection state changes.
///
/// Conform to this protocol to receive updates when the connection state changes.
public protocol ConnectionObserver: AnyObject {
    
    /// Called when the connection state changes.
    func onStateChanged(_ to: ConnectionState)
}
