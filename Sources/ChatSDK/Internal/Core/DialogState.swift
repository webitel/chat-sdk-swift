//
//  DialogState.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 26.03.2026.
//

import Foundation


internal struct DialogState {

    let id: String
    let type: DialogType
    var subject: String
    var members: [Participant]
    var lastMessage: Message?
    var participantStates: [ParticipantState] = []
    var deliveryExceptions: [DeliveryException] = []
}


extension DialogState {

    static func from(
        _ dto: DialogDto,
        currentUserId: String?
    ) -> DialogState {
        let members = dto.members?.map { $0.toDomain() } ?? []

        return DialogState(

            id: dto.id,
            type: DialogType.from(dto.type),
            subject: dto.subject,
            members: members,
            lastMessage:
                dto.lastMessage?
                .toDomain(currentUserId),
            participantStates:
                dto.readStates?.compactMap {
                    $0.toDomain(members: members)
                } ?? []
        )
    }
}
