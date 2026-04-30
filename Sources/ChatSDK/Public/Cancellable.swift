//
//  Cancellable.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation


/// Represents an operation that can be cancelled.
public protocol Cancellable {

    ///
    /// Cancels the operation.
    /// Cancellation does not retract messages already accepted by the server.
    func cancel()
}
