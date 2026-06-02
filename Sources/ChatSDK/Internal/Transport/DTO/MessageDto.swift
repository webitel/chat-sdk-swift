//
//  MessageDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 26.03.2026.
//

import Foundation


internal struct MessageDto: Decodable {
    let id: String
    let dialogId: String
    let createdAt: Int64
    let editedAt: Int64
    let from: ParticipantDto
    let sendId: String?
    let body: String?
    let content: MessageContentDto

    private enum CodingKeys: String, CodingKey {
        case id
        case dialogId = "thread_id"
        case createdAt = "created_at"
        case editedAt = "edited_at"
        case from = "sender"
        case sendId = "send_id"
        case body
        case interactive
        case contact
        case location
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)

        dialogId = try container.decode(String.self, forKey: .dialogId)
        body = try? container.decodeIfPresent(String.self, forKey: .body)

        createdAt = try Self.decodeTimestamp(
            container,
            key: .createdAt
        )

        editedAt = (
            try? Self.decodeTimestamp(
                container,
                key: .editedAt
            )
        ) ?? createdAt

        from = try container.decode(
            ParticipantDto.self,
            forKey: .from
        )

        sendId = try container.decodeIfPresent(
            String.self,
            forKey: .sendId
        )

        content = try MessageContentDto(from: decoder)
    }
    
    private static func decodeTimestamp(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) throws -> Int64 {

        if let intValue = try? container.decode(Int64.self, forKey: key) {
            return intValue
        }

        if let stringValue = try? container.decode(String.self, forKey: key),
           let intValue = Int64(stringValue) {
            return intValue
        }

        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: container,
            debugDescription: "Invalid timestamp format"
        )
    }
}


internal extension MessageDto {
    func toDomain(_ currentUserId: String?) -> Message {
        let from = self.from.toDomain()

        let createdDate = Date(timeIntervalSince1970: Double(createdAt) / 1000.0)
        let editedDate = Date(timeIntervalSince1970: Double(editedAt) / 1000.0)
        
        return Message(
            id: id,
            dialogId: dialogId,
            createdAt: createdDate,
            editedAt: editedDate,
            from: from,
            content: content.toDomain(),
            sendId: sendId,
            isOutgoing: currentUserId == from.contact.id.sub
        )
    }
}


internal struct MessageContentDto: Decodable {
    let text: String?
    let attachments: [AttachmentDto]
    let interactive: InteractiveMessageDto?
    let contact: ContactMessageDto?
    let location: LocationMessageDto?

    private enum CodingKeys: String, CodingKey {
        case text = "body"
        case documents
        case interactive
        case contact
        case location
        case system
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        text = try container.decodeIfPresent(
            String.self,
            forKey: .text
        )

        attachments = try container.decodeIfPresent(
            [AttachmentDto].self,
            forKey: .documents
        ) ?? []

        interactive = try container.decodeIfPresent(
            InteractiveMessageDto.self,
            forKey: .interactive
        )

        contact = try? container.decodeIfPresent(
            ContactMessageDto.self,
            forKey: .contact
        )

        location = try? container.decodeIfPresent(
            LocationMessageDto.self,
            forKey: .location
        )
    }
}


extension MessageContentDto {
    func toDomain() -> MessageContent {
        if let contact {
            return .contact(
                .init(
                    name: contact.name,
                    phone: contact.phone,
                    email: contact.email
                )
            )
        }

        if let location {
            return .location(
                .init(
                    name: location.name,
                    address: location.address ?? "",
                    latitude: location.latitude ?? 0,
                    longitude: location.longitude ?? 0
                )
            )
        }

        let keyboard = interactive?.toDomain()

        let attachments = attachments.map {
            $0.toDomain()
        }

        let hasText = text?.isEmpty == false
        let hasAttachments = !attachments.isEmpty
        let hasKeyboard = keyboard != nil

        let contentPartsCount = [
            hasText,
            hasAttachments,
            hasKeyboard
        ]
            .filter { $0 }
            .count

        if contentPartsCount >= 2 {
            return .composite(
                .init(
                    text: text,
                    attachments: attachments,
                    keyboard: keyboard
                )
            )
        }

        if hasAttachments {
            return .attachments(attachments)
        }

        if let keyboard {
            return .keyboard(keyboard)
        }

        return .text(text ?? "")
    }
}


internal struct ContactMessageDto: Decodable {
    let name: String
    let phone: String?
    let email: String?
}


internal struct LocationMessageDto: Decodable {
    let name: String
    let address: String?
    let latitude: Double?
    let longitude: Double?
}


internal struct InteractiveMessageDto: Decodable {
    let singleUse: Bool
    let markup: MarkupDto?
    let listReplyDto: ListReplyDto?
    
    private enum CodingKeys: String, CodingKey {
        case markup
        case singleUse = "single_use"
        case listReply = "list_reply"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )
        
        singleUse = ((try? container.decodeIfPresent(
            Bool.self,
            forKey: .singleUse
        )) != nil)
        
        markup = try container.decodeIfPresent(
            MarkupDto.self,
            forKey: .markup
        )
        
        listReplyDto = try container.decodeIfPresent(
            ListReplyDto.self,
            forKey: .listReply
        )
    }
}


extension InteractiveMessageDto {
    func toDomain() -> ChatKeyboard? {
        if let markup {
            return .buttons(
                .init(
                    rows: markup.rows.map {
                        ChatKeyboardRow(
                            buttons: $0.buttons.map {
                                $0.toDomain()
                            }
                        )
                    }
                )
            )
        }
        if let listReplyDto {
            return .listMenu(
                .init(
                    title: listReplyDto.title,
                    sections: listReplyDto.sections.map {
                        ChatKeyboardSection(
                            title: $0.title,
                            buttons: $0.buttons.map {
                                $0.toDomain()
                            }
                        )
                    }
                )
            )
        }
        return nil
    }
}


internal struct MarkupDto: Decodable {
    let rows: [MarkupRowDto]
}


internal struct MarkupRowDto: Decodable {
    let buttons: [InteractiveButtonDto]
}


internal struct ListReplyDto: Decodable {
    let title: String
    let sections: [ListReplySectionDto]
    
    private enum CodingKeys: String, CodingKey {
        case title = "main_button_title"
        case sections
    }
}


internal struct ListReplySectionDto: Decodable {
    let title: String
    let buttons: [InteractiveButtonDto]

    private enum CodingKeys: String, CodingKey {
        case title = "section"
        case buttons
    }
}


internal struct CallbackActionDto: Decodable {
    let data: String
}


internal struct URLActionDto: Decodable {
    let url: String
}


internal struct RequestActionDto: Decodable {
    let action: String
}


internal struct InteractiveButtonDto: Decodable {
    let id: String
    let label: String
    let action: ChatButtonAction

    let metadata: [String: JSONValue]?

    private enum CodingKeys: String, CodingKey {
        case id
        case label
        case metadata
        case callback
        case url
        case request
        case action
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        id = try container.decode(String.self, forKey: .id)
        label = try container.decode(String.self, forKey: .label)
        
        metadata = try? container.decodeIfPresent(
            [String: JSONValue].self,
            forKey: .metadata
        )

        var buttonAction: ChatButtonAction?
        if let urlAction = try? container.decode(
            URLActionDto.self,
            forKey: .url
        ) {
            buttonAction = .openURL(urlAction.url)
        }

        if let requestAction = try? container.decode(
            RequestActionDto.self,
            forKey: .request
        ) {
            buttonAction = .requestData(requestAction.action)
        }
        
        if let callbackAction = try? container.decode(
            CallbackActionDto.self,
            forKey: .callback
        ) {
            buttonAction = .callback(callbackAction.data)
        }
        
        if let buttonAction {
            action = buttonAction
            
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .action,
                in: container,
                debugDescription: "Action not found"
            )
        }
    }
}


extension InteractiveButtonDto {
    func toDomain() -> ChatKeyboardButton {
        ChatKeyboardButton(
            id: id,
            label: label,
            action: action,
            metadata: metadata?.mapValues { $0.toDomain() }
        )
    }
}


internal struct AttachmentDto: Decodable {
    let id: String
    let name: String
    let mime: String
    let size: Int64?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case id, name, mime, size, url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.mime = try container.decode(String.self, forKey: .mime)
        self.url = try? container.decodeIfPresent(String.self, forKey: .url)

        if let intSize = try? container.decodeIfPresent(Int64.self, forKey: .size) {
            self.size = intSize
        }
        else if let stringSize = try? container.decodeIfPresent(String.self, forKey: .size) {
            self.size = Int64(stringSize)
        }
        
        else {
            self.size = nil
        }
    }
}


extension AttachmentDto {
    
    func toDomain() -> MessageAttachment {
        let fileURL = url.flatMap { URL(string: $0) }
        return MessageAttachment(
            fileId: id,
            fileName: name,
            mimeType: mime,
            size: size ?? 0,
            url: fileURL
        )
    }
}


