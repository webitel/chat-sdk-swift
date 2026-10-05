//
//  ChatClientObserver.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 05.10.2026.
//

import Foundation


/// Observer for client-level events not bound to a specific dialog.
///
/// All methods have default empty implementations,
/// implement only those you need.
public protocol ChatClientObserver: AnyObject {

    /// Called when incremental synchronization is no longer possible
    /// and the client should reload its chat state:
    /// the dialog list and any opened message histories.
    func onResyncRequired()
}


public extension ChatClientObserver {
    func onResyncRequired() {}
}
