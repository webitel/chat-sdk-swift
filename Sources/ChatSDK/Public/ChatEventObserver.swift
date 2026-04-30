//
//  ChatEventListener.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation


/// Observer used to receive chat-related events from the SDK.
public protocol ChatEventObserver: AnyObject {

    /// Called when a new ChatEvent is emitted.
    func onEvent(_ event: ChatEvent)
}
