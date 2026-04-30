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
    
    enum CodingKeys: String, CodingKey {
        case id, type, subject, members
        case lastMessage = "last_msg"
    }
}


struct MemberWrapperDto: Decodable {
    let member: ParticipantDto
}
