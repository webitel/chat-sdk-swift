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
}


extension DialogState {

    static func from(
        _ dto: DialogDto,
        currentUserId: String?
    ) -> DialogState {
        DialogState(

            id: dto.id,
            type: DialogType.from(dto.type),
            subject: dto.subject,
            members:
                dto.members?.map {
                    $0.toDomain()
                } ?? [],
            lastMessage:
                dto.lastMessage?
                .toDomain(currentUserId)
        )
    }
}
