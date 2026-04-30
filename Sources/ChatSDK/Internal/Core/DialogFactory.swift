//
//  DialogFactory.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 26.03.2026.
//

import Foundation


internal final class DialogFactory {

    private var cache: [String: DialogImpl] = [:]
    
    func getOrCreate(
        client: DefaultChatClient,
        dto: DialogDto
    ) -> DialogImpl {

        if let dialog = cache[dto.id] {

            dialog.update(dto)

            return dialog
        }

        let dialog = DialogImpl(
            state: DialogState.from(dto, currentUserId: client.currentUserId),
            client: client
        )

        cache[dto.id] = dialog

        return dialog
    }


    func get(
        _ id: String
    ) -> DialogImpl? {

        cache[id]
    }
}
