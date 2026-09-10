//
//  ForwardOrigin.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 08.09.2026.
//

import Foundation


/// Origin of a message that was forwarded from elsewhere.
public struct ForwardOrigin: Hashable, Codable {

    /// When the original message was sent, before it was forwarded.
    public let originalSentAt: Date

    /// Specific kind of origin and the data that comes with it.
    public let kind: ForwardOriginKind
}


/// Kind of origin a forwarded message came from.
public enum ForwardOriginKind: Hashable, Codable {

    /// Forwarded from another chat within Webitel.
    case internalUser(
        senderId: String,
        senderName: String?,
        sourceMessageId: String
    )

    /// Forwarded from an external messenger, sender named.
    case externalUser(senderName: String)

    /// Forwarded from an external messenger; the sender chose to hide their identity.
    case externalHiddenUser

    /// Forwarded from an external group or channel rather than a person.
    case externalChat(name: String?)

    /// Origin kind not recognized by this SDK version.
    case unsupported(rawKind: String, senderName: String?)
}


public extension ForwardOrigin {
    /// Name to display for the forwarding sender, when known.
    var senderDisplayName: String? {
        kind.senderDisplayName
    }
}


public extension ForwardOriginKind {
    /// Name to display for the forwarding sender, when known.
    var senderDisplayName: String? {
        switch self {
        case .internalUser(_, let name, _):
            return name

        case .externalUser(let name):
            return name

        case .externalHiddenUser:
            return nil

        case .externalChat(let name):
            return name

        case .unsupported(_, let name):
            return name
        }
    }
}
