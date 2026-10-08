//
//  DialogDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation


internal struct DialogDto: Decodable {
    let id: String
    let subject: String
    let type: String
    let lastMessage: MessageDto?
    let members: [ParticipantDto]?
    let readStates: [ReadStateDto]?
    let unreadCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, type, subject, members
        case lastMessage = "last_msg"
        case readStates = "read_states"
        case unreadCount = "unread_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        subject = try container.decode(String.self, forKey: .subject)
        type = try container.decode(String.self, forKey: .type)
        lastMessage = try container.decodeIfPresent(MessageDto.self, forKey: .lastMessage)
        members = try container.decodeIfPresent([ParticipantDto].self, forKey: .members)
        readStates = try container.decodeIfPresent([ReadStateDto].self, forKey: .readStates)
        unreadCount = decodeUnreadCount(container, key: .unreadCount)
    }
}


struct MemberWrapperDto: Decodable {
    let member: ParticipantDto
}
