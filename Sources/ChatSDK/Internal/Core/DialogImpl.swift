//
//  DialogImpl.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 26.03.2026.
//

import Foundation


internal enum ReceiptKind {
    case delivered
    case read
}


internal final class DialogImpl: Dialog {
    private let client: DefaultChatClient
    private let lock = NSLock()

    /// Mutated from realtime/sync queues and API tasks, read from any thread.
    /// Access only through `withState`.
    private var state: DialogState

    var id: String { withState { $0.id } }
    var type: DialogType { withState { $0.type } }
    var members: [Participant] { withState { $0.members } }
    var subject: String { withState { $0.subject } }
    var lastMessage: Message? { withState { $0.lastMessage } }
    var unreadCount: Int { withState { $0.unreadCount } }
    var participantStates: [ParticipantState] { withState { $0.participantStates } }
    var deliveryExceptions: [DeliveryException] { withState { $0.deliveryExceptions } }

    init(
        state: DialogState,
        client: DefaultChatClient,
    ) {

        self.state = state
        self.client = client
    }
    
    
    func sendMessage(options: MessageOptions, completion: @escaping (Result<String, ChatError>) -> Void) -> any Cancellable {
        client.sendMessage(to: .dialog(id: id), options: options, completion: completion)
    }
    
    
    func sendMessage(
        options: MessageOptions
    ) async throws -> String {
        try await client.sendMessage(to: .dialog(id: id), options: options)
    }
    
    
    func getHistory(request: HistoryRequest, completion: @escaping (Result<HistorySlice, ChatError>) -> Void) {
        client.getHistory(dialogId: id, request: request, completion: completion)
    }
    
    
    func getHistory(request: HistoryRequest) async throws -> HistorySlice {
        try await client.getHistory(dialogId: id, request: request)
    }


    func searchMessages(request: MessageSearchRequest, completion: @escaping (Result<MessageSearchSlice, ChatError>) -> Void) {
        client.searchMessages(request: request, dialogId: id, completion: completion)
    }


    func searchMessages(_ request: MessageSearchRequest) async throws -> MessageSearchSlice {
        try await client.searchMessages(request, dialogId: id)
    }


    func sendAction(_ action: MessageAction, completion: @escaping (Result<Void, ChatError>) -> Void) {
        client.sendAction(action, completion: completion)
    }
    
    
    func sendAction(_ action: MessageAction) async throws {
        try await client.sendAction(action)
    }


    func sendTyping(request: TypingRequest, completion: @escaping (Result<Void, ChatError>) -> Void) {
        client.sendTyping(dialogId: id, request: request, completion: completion)
    }


    func sendTyping(request: TypingRequest) async throws {
        try await client.sendTyping(dialogId: id, request: request)
    }


    func markAsRead(sequence: Int64, completion: @escaping (Result<Void, ChatError>) -> Void) {
        client.markAsRead(dialogId: id, position: .sequence(sequence), completion: completion)
    }


    func markAsRead(sequence: Int64) async throws {
        try await client.markAsRead(dialogId: id, position: .sequence(sequence))
    }


    func markAsRead(messageId: String, completion: @escaping (Result<Void, ChatError>) -> Void) {
        client.markAsRead(dialogId: id, position: .messageId(messageId), completion: completion)
    }


    func markAsRead(messageId: String) async throws {
        try await client.markAsRead(dialogId: id, position: .messageId(messageId))
    }


    func setReaction(
        messageId: String,
        emoji: String,
        sendId: String?,
        completion: @escaping (Result<ReactionResult, ChatError>) -> Void
    ) {
        client.setReaction(messageId: messageId, emoji: emoji, sendId: sendId, completion: completion)
    }


    func setReaction(
        messageId: String,
        emoji: String,
        sendId: String?
    ) async throws -> ReactionResult {
        try await client.setReaction(messageId: messageId, emoji: emoji, sendId: sendId)
    }


    func deleteMessages(
        ids: [String],
        completion: @escaping (Result<DeleteMessagesResult, ChatError>) -> Void
    ) {
        client.deleteMessages(ids: ids, completion: completion)
    }


    func deleteMessages(ids: [String]) async throws -> DeleteMessagesResult {
        try await client.deleteMessages(ids: ids)
    }


    func forwardMessages(
        ids: [String],
        sendId: String,
        completion: @escaping (Result<ForwardMessagesResult, ChatError>) -> Void
    ) {
        client.forwardMessages(ids: ids, to: .dialog(id: id), sendId: sendId, completion: completion)
    }


    func forwardMessages(
        ids: [String],
        sendId: String
    ) async throws -> ForwardMessagesResult {
        try await client.forwardMessages(ids: ids, to: .dialog(id: id), sendId: sendId)
    }


    func editMessage(
        messageId: String,
        text: String,
        completion: @escaping (Result<EditMessageResult, ChatError>) -> Void
    ) {
        client.editMessage(messageId: messageId, text: text, completion: completion)
    }


    func editMessage(messageId: String, text: String) async throws -> EditMessageResult {
        try await client.editMessage(messageId: messageId, text: text)
    }


    func addObserver(_ observer: any ChatEventObserver) {
        client.addDialogObserver(dialogId: id, observer: observer)
    }
    
    
    func removeObserver(_ observer: any ChatEventObserver) {
        client.removeDialogObserver(dialogId: id, observer: observer)
    }


    func update(_ dto: DialogDto) {
        let members = dto.members?.map { $0.toDomain() } ?? []
        let lastMessage = dto.lastMessage?.toDomain(client.currentUserId)

        let readStates = dto.readStates?.compactMap { $0.toDomain(members: members) } ?? []

        withState { state in
            state.subject = dto.subject
            state.members = members
            state.lastMessage = lastMessage
            if let unreadCount = dto.unreadCount {
                state.unreadCount = unreadCount
            }
            Self.merge(readStates, into: &state.participantStates)
        }
    }


    /// Advances the participant's receipt horizon and, when provided,
    /// the current user's unread count.
    ///
    /// A duplicate read receipt still updates the unread count; a stale one is ignored.
    ///
    /// - Returns: `true` if the horizon moved forward, `false` for stale or duplicate receipts.
    func applyReceipt(
        member: Participant,
        kind: ReceiptKind,
        upToSequence: Int64,
        unreadCount: Int?
    ) -> Bool {
        withState { state in
            let index = state.participantStates.firstIndex { $0.member.id == member.id }
            let current = index.map { state.participantStates[$0] }
                ?? ParticipantState(member: member, deliveredUpToSequence: 0, readUpToSequence: 0)

            let updated: ParticipantState

            switch kind {
            case .delivered:
                guard upToSequence > current.deliveredUpToSequence else { return false }
                updated = ParticipantState(
                    member: member,
                    deliveredUpToSequence: upToSequence,
                    readUpToSequence: current.readUpToSequence
                )

            case .read:
                // A repeated horizon still carries the server's current count: corrects local drift
                if let unreadCount, upToSequence == current.readUpToSequence {
                    state.unreadCount = unreadCount
                }

                guard upToSequence > current.readUpToSequence else { return false }
                updated = ParticipantState(
                    member: member,
                    deliveredUpToSequence: current.deliveredUpToSequence,
                    readUpToSequence: upToSequence
                )
            }

            if let index {
                state.participantStates[index] = updated
            } else {
                state.participantStates.append(updated)
            }

            if let unreadCount {
                state.unreadCount = unreadCount
            }

            return true
        }
    }


    /// Merges recovered horizons without moving any of them backwards.
    ///
    /// - Returns: Resulting states of the participants present in `incoming`.
    @discardableResult
    func mergeParticipantStates(_ incoming: [ParticipantState]) -> [ParticipantState] {
        withState { state in
            Self.merge(incoming, into: &state.participantStates)

            let ids = Set(incoming.map { $0.member.id })
            return state.participantStates.filter { ids.contains($0.member.id) }
        }
    }


    private static func merge(
        _ incoming: [ParticipantState],
        into states: inout [ParticipantState]
    ) {
        for item in incoming {
            guard let index = states.firstIndex(where: { $0.member.id == item.member.id }) else {
                states.append(item)
                continue
            }

            let current = states[index]
            states[index] = ParticipantState(
                member: item.member,
                deliveredUpToSequence: max(current.deliveredUpToSequence, item.deliveredUpToSequence),
                readUpToSequence: max(current.readUpToSequence, item.readUpToSequence)
            )
        }
    }


    func applyMemberChanges(_ changes: [MemberChange]) {
        withState { state in
            for change in changes {
                let index = state.members.firstIndex { $0.id == change.member.id }

                switch change.action {
                case .added:
                    if let index {
                        state.members[index] = change.member
                    } else {
                        state.members.append(change.member)
                    }

                case .removed:
                    if let index {
                        state.members.remove(at: index)
                    }

                case .unknown:
                    continue
                }
            }
        }
    }


    func applyUnreadCount(_ unreadCount: Int) {
        withState { $0.unreadCount = unreadCount }
    }


    /// Sets the last message and updates the unread count.
    ///
    /// Uses `unreadCount` from the server when present; otherwise counts an incoming
    /// message newer than the current user's read horizon. A repeated message is not counted twice.
    func applyMessage(_ message: Message, unreadCount: Int?, currentUserId: String?) {
        withState { state in
            let isRepeated = state.lastMessage?.id == message.id
            state.lastMessage = message

            if let unreadCount {
                state.unreadCount = unreadCount
                return
            }

            guard !message.isOutgoing, !isRepeated else { return }

            let readHorizon = state.participantStates
                .first { $0.member.contact.id.sub == currentUserId }?
                .readUpToSequence ?? 0

            if let sequence = message.sequence, sequence <= readHorizon {
                return
            }

            state.unreadCount += 1
        }
    }


    func applyReactions(messageId: String, reactions: [MessageReaction]) {
        withState { state in
            guard state.lastMessage?.id == messageId else { return }
            state.lastMessage?.reactions = reactions
        }
    }


    func applyDeletion(messageId: String) {
        withState { state in
            guard state.lastMessage?.id == messageId else { return }
            state.lastMessage = nil
        }
    }


    func applySync(lastMessage: Message?, deletedMessageIds: [String], unreadCount: Int?) {
        withState { state in
            if let unreadCount {
                state.unreadCount = unreadCount
            }

            if let id = state.lastMessage?.id, deletedMessageIds.contains(id) {
                state.lastMessage = nil
            }

            guard let lastMessage, !deletedMessageIds.contains(lastMessage.id)
            else { return }

            if let current = state.lastMessage, current.createdAt > lastMessage.createdAt {
                return
            }

            state.lastMessage = lastMessage
        }
    }


    @discardableResult
    func applyEdit(_ message: Message) -> Message {
        withState { state in
            guard state.lastMessage?.id == message.id else { return message }

            var merged = message
            if merged.reactions.isEmpty {
                merged.reactions = state.lastMessage?.reactions ?? []
            }

            state.lastMessage = merged
            return merged
        }
    }


    private func withState<T>(_ body: (inout DialogState) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body(&state)
    }


    static func == (lhs: DialogImpl, rhs: DialogImpl) -> Bool {
        return lhs.id == rhs.id
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

