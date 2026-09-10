//
//  ForwardMessagesRequestDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 09.09.2026.
//

import Foundation


internal struct ForwardMessagesRequestDto: Encodable {

    let message_ids: [String]
    let send_id: String
    let to: TargetDto

    init(messageIds: [String], target: MessageTarget, sendId: String) {
        self.message_ids = messageIds
        self.send_id = sendId
        self.to = TargetDto(target)
    }
}
