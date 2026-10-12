//
//  DeliveryException.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 12.10.2026.
//

import Foundation


/// Failure to deliver a message to a specific dialog member
/// (e.g. the external channel rejected it).
public struct DeliveryException: Hashable, Codable {

    /// Identifier of the message that was not delivered.
    public let messageId: String

    /// Member the message was not delivered to.
    public let member: Participant

    /// Error reported by the server or the external provider.
    public let error: DeliveryError

    public init(
        messageId: String,
        member: Participant,
        error: DeliveryError
    ) {
        self.messageId = messageId
        self.member = member
        self.error = error
    }
}


public struct DeliveryError: Hashable, Codable {

    /// Error code, e.g. `"403"`.
    public let code: String

    /// Human-readable error description, if provided.
    public let message: String?

    public init(code: String, message: String?) {
        self.code = code
        self.message = message
    }
}
