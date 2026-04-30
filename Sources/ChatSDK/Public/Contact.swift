//
//  Contact.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 20.03.2026.
//

import Foundation


/// Represents a chat contact.
public struct Contact: Hashable, Codable {

    /// Unique identifier of the contact.
    public let id: ContactID

    /// Display name of the contact.
    public let name: String

    /// Source of the contact (e.g. telegram, facebook, webitel, custom).
    /// Corresponds to the `iss` field configured on the server.
    public let source: String

    /// Indicates whether the contact represents a bot.
    public let isBot: Bool

    public init(
        id: ContactID,
        name: String,
        source: String,
        isBot: Bool
    ) {
        self.id = id
        self.name = name
        self.source = source
        self.isBot = isBot
    }
}


/// Unique identity of a contact.
public struct ContactID: Hashable, Codable {

    /// Subject identifier of the contact.
    public let sub: String

    /// Issuer of the contact identity.
    public let iss: String

    public init(sub: String, iss: String) {
        self.sub = sub
        self.iss = iss
    }
}
