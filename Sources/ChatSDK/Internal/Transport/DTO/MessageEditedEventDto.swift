//
//  MessageEditedEventDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 26.08.2026.
//

import Foundation


/// Carries the full edited message, decoded the same way as a regular one.
/// `edited_by` becomes the message sender.
internal struct MessageEditedEventDto: Decodable {
    let message: MessageDto
    let editedBy: ParticipantDto

    var messageId: String { message.id }
    var dialogId: String { message.dialogId }

    private enum CodingKeys: String, CodingKey {
        case editedBy = "edited_by"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        editedBy = try container.decode(ParticipantDto.self, forKey: .editedBy)
        message = try MessageDto(from: decoder, fallbackDialogId: nil, sender: editedBy)
    }
}


internal extension MessageEditedEventDto {
    func toDomain(_ currentUserId: String?) -> Message {
        message.toDomain(currentUserId, from: editedBy.toDomain())
    }
}
