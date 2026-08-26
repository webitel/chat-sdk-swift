//
//  MessageDeletion.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 26.08.2026.
//

import Foundation


public struct MessageDeletion {
    public let messageId: String
    public let deletedBy: Participant
    public let deletedAt: Date
}
