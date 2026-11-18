//
//  KeyboardCallbackEventDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 17.11.2026.
//

import Foundation


/// `interactive_callback_event`: a keyboard button of a message was pressed.
///
/// Selection fields (`button_code`, `callback_data`, `reacted_at`, `reacted_by`)
/// share the format of `reacted_metadata` in `MessageDto`.
internal struct KeyboardCallbackEventDto: Decodable {
    let dialogId: String
    let messageId: String
    let selection: ReactedMetadataDto

    private enum CodingKeys: String, CodingKey {
        case dialogId = "thread_id"
        case messageId = "message_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dialogId = try container.decode(String.self, forKey: .dialogId)
        messageId = try container.decode(String.self, forKey: .messageId)
        selection = try ReactedMetadataDto(from: decoder)
    }
}
