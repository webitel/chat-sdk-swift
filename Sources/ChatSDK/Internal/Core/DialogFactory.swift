//
//  DialogFactory.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 26.03.2026.
//

import Foundation


internal final class DialogFactory {

    /// Accessed from realtime/sync queues and API tasks.
    private let lock = NSLock()
    private var cache: [String: DialogImpl] = [:]

    func getOrCreate(
        client: DefaultChatClient,
        dto: DialogDto
    ) -> DialogImpl {

        getOrCreateReportingNew(client: client, dto: dto).dialog
    }


    /// Same as `getOrCreate`, but also reports whether the dialog
    /// was created by this call. The check and insertion are atomic.
    func getOrCreateReportingNew(
        client: DefaultChatClient,
        dto: DialogDto
    ) -> (dialog: DialogImpl, isNew: Bool) {

        lock.lock()
        defer { lock.unlock() }

        if let dialog = cache[dto.id] {

            dialog.update(dto)

            return (dialog, false)
        }

        let dialog = DialogImpl(
            state: DialogState.from(dto, currentUserId: client.currentUserId),
            client: client
        )

        cache[dto.id] = dialog

        return (dialog, true)
    }


    func get(
        _ id: String
    ) -> DialogImpl? {

        lock.lock()
        defer { lock.unlock() }

        return cache[id]
    }
}
