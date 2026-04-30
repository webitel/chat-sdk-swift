//
//  ParticipantDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 14.04.2026.
//

import Foundation


internal struct ParticipantDto: Codable {
    let id: String
    let contact: ContactDto
    let role: String
}


internal extension ParticipantDto {
    func toDomain() -> Participant {
        Participant(
            id: id,
            contact: contact.toDomain(),
            role: ParticipantRole(rawValueOrDefault: role)
        )
    }
}
