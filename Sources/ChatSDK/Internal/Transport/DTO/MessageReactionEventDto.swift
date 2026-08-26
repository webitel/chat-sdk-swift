//
//  MessageReactionEventDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 18.08.2026.
//

import Foundation


internal struct MessageReactionEventDto: Decodable {
    let messageId: String
    let dialogId: String
    let reactions: [MessageReactionDto]

    private enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case dialogId = "thread_id"
        case reactions
    }
}
