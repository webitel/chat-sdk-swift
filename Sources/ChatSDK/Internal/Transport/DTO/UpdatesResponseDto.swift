//
//  UpdatesResponseDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 28.09.2026.
//

import Foundation


internal struct UpdatesResponseDto: Decodable {
    let cursor: String
    let resync: Bool
    let hasMore: Bool
    let threads: [ThreadUpdatesDto]

    private enum CodingKeys: String, CodingKey {
        case cursor, resync, threads
        case hasMore = "has_more"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let value = try? container.decode(String.self, forKey: .cursor) {
            cursor = value
        } else {
            cursor = String(try container.decode(Int64.self, forKey: .cursor))
        }

        resync = (try? container.decodeIfPresent(Bool.self, forKey: .resync)) ?? false
        hasMore = (try? container.decodeIfPresent(Bool.self, forKey: .hasMore)) ?? false
        threads = (try? container.decodeIfPresent([ThreadUpdatesDto].self, forKey: .threads)) ?? []
    }
}


internal struct ThreadUpdatesDto: Decodable {
    private static let logger = SDKLogger.make("chat.dto.updates")

    let threadId: String
    let dialog: DialogDto?
    /// `nil` when the update does not carry the count.
    let unreadCount: Int?
    let messages: [MessageDto]
    let topMessage: MessageDto?
    let deletedMessageIds: [String]
    let readStates: [ReadStateDto]
    let memberChanges: [MemberChangeDto]
    let left: Bool

    private enum CodingKeys: String, CodingKey {
        case dialog, messages, left
        case threadId = "thread_id"
        case unreadCount = "unread_count"
        case topMessage = "top_message"
        case deletedMessageIds = "deleted_message_ids"
        case readStates = "read_states"
        case memberChanges = "member_changes"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let threadId = try container.decode(String.self, forKey: .threadId)
        self.threadId = threadId

        do {
            dialog = try container.decodeIfPresent(DialogDto.self, forKey: .dialog)
        } catch {
            Self.logger.warning("Failed to decode dialog for thread \(threadId): \(error)")
            dialog = nil
        }

        unreadCount = decodeUnreadCount(container, key: .unreadCount)
        messages = Self.decodeMessages(container, threadId: threadId)

        if container.contains(.topMessage),
           let topDecoder = try? container.superDecoder(forKey: .topMessage) {
            topMessage = try? MessageDto(from: topDecoder, fallbackDialogId: threadId)
        } else {
            topMessage = nil
        }

        deletedMessageIds = (try? container.decodeIfPresent([String].self, forKey: .deletedMessageIds)) ?? []
        readStates = (try? container.decodeIfPresent([ReadStateDto].self, forKey: .readStates)) ?? []
        memberChanges = (try? container.decodeIfPresent([MemberChangeDto].self, forKey: .memberChanges)) ?? []
        left = (try? container.decodeIfPresent(Bool.self, forKey: .left)) ?? false
    }

    /// Messages inside a thread omit `thread_id`, so each one is decoded
    /// with the enclosing thread id as fallback. Undecodable items are skipped.
    private static func decodeMessages(
        _ container: KeyedDecodingContainer<CodingKeys>,
        threadId: String
    ) -> [MessageDto] {

        guard
            container.contains(.messages),
            var items = try? container.nestedUnkeyedContainer(forKey: .messages)
        else {
            return []
        }

        var result: [MessageDto] = []

        while !items.isAtEnd {
            guard let itemDecoder = try? items.superDecoder() else { break }

            do {
                result.append(try MessageDto(from: itemDecoder, fallbackDialogId: threadId))
            } catch {
                logger.warning("Failed to decode message in thread \(threadId): \(error)")
            }
        }

        return result
    }
}


internal struct ReadStateDto: Decodable {
    let memberId: String?
    let member: ParticipantDto?
    let deliveredUpToSeq: Int64
    let readUpToSeq: Int64

    private enum CodingKeys: String, CodingKey {
        case member
        case memberId = "member_id"
        case deliveredUpToSeq = "delivered_up_to_seq"
        case readUpToSeq = "read_up_to_seq"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        memberId = try? container.decodeIfPresent(String.self, forKey: .memberId)
        member = try? container.decodeIfPresent(ParticipantDto.self, forKey: .member)
        deliveredUpToSeq = decodeFlexibleInt64(container, key: .deliveredUpToSeq) ?? 0
        readUpToSeq = decodeFlexibleInt64(container, key: .readUpToSeq) ?? 0
    }
}


internal struct MemberChangeDto: Decodable {
    let action: String
    let member: ParticipantDto?
    let by: ParticipantDto?

    private enum CodingKeys: String, CodingKey {
        case action, member, by
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        action = (try? container.decodeIfPresent(String.self, forKey: .action)) ?? ""
        member = try? container.decodeIfPresent(ParticipantDto.self, forKey: .member)
        by = try? container.decodeIfPresent(ParticipantDto.self, forKey: .by)
    }
}


internal extension ReadStateDto {
    private static let logger = SDKLogger.make("chat.dto.updates")

    /// Resolves the participant from the embedded `member`, or by `member_id`
    /// among `members` when the server sends only the id.
    func toDomain(members: [Participant] = []) -> ParticipantState? {
        let participant = member?.toDomain()
            ?? memberId.flatMap { id in members.first { $0.id == id } }

        guard let participant else {
            Self.logger.warning("Read state skipped, unknown member \(memberId ?? "-")")
            return nil
        }

        return ParticipantState(
            member: participant,
            deliveredUpToSequence: deliveredUpToSeq,
            readUpToSequence: readUpToSeq
        )
    }
}


internal extension MemberChangeDto {
    func toDomain() -> MemberChange? {
        guard let member else { return nil }

        return MemberChange(
            action: MemberChangeAction.from(action),
            member: member.toDomain(),
            by: by?.toDomain()
        )
    }
}


internal extension MemberChangeAction {
    static func from(_ raw: String) -> MemberChangeAction {
        let value = raw.uppercased()

        if value.hasSuffix("JOINED") {
            return .added
        }

        if value.hasSuffix("LEFT") {
            return .removed
        }

        return .unknown(raw)
    }
}
