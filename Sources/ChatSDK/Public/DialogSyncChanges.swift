//
//  DialogSyncChanges.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 28.09.2026.
//

import Foundation


/// Changes of a single dialog recovered after the realtime
/// connection was temporarily unavailable.
public struct DialogSyncChanges {

    /// Current unread message count for the dialog.
    public let unreadCount: Int

    /// Messages whose server state changed while the client
    /// was out of sync, sorted by `sequence`.
    ///
    /// Messages should be upserted by `id`.
    public let messages: [Message]

    /// Messages that should be removed from local state.
    public let deletedMessageIds: [String]

    /// Current delivery/read horizons for affected participants.
    public let participantStates: [ParticipantState]

    /// Delivery failures that should be applied to local state.
    public let deliveryExceptions: [DeliveryException]

    /// Members added or removed while the client was out of sync.
    public let memberChanges: [MemberChange]

    /// Indicates that the current user has left the dialog.
    public let hasLeft: Bool
}


public struct ParticipantState {

    public let member: Participant

    /// Highest message sequence known to be delivered
    /// to this participant.
    public let deliveredUpToSequence: Int64

    /// Highest message sequence known to be read
    /// by this participant.
    public let readUpToSequence: Int64
}


public struct DeliveryException {

    public let messageId: String
    public let member: Participant
    public let error: DeliveryError
}


public struct DeliveryError {

    public let code: String
    public let message: String?
}


public struct MemberChange {

    public let action: MemberChangeAction

    /// Member affected by the change.
    public let member: Participant

    /// Member who performed the change, if known.
    public let by: Participant?
}


public enum MemberChangeAction: Hashable {

    case added

    case removed

    /// Action not recognized by this SDK version. Contains the raw server value.
    case unknown(String)
}
