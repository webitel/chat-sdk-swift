//
//  MarkAsReadRequestDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 29.09.2026.
//

import Foundation


/// Position in a dialog up to which messages are marked as read.
internal enum ReadPosition {
    case sequence(Int64)
    case messageId(String)
}


/// Exactly one of `id` or `up_to_seq` is sent; the server treats them equally.
internal struct MarkAsReadRequestDto: Encodable {
    let id: String?
    let up_to_seq: String?

    init(_ position: ReadPosition) {
        switch position {
            case .sequence(let sequence):
                id = nil
                up_to_seq = String(sequence)

            case .messageId(let messageId):
                id = messageId
                up_to_seq = nil
        }
    }
}
