//
//  DeliveryFailureDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 12.10.2026.
//

import Foundation


/// Item of a message's `failures` list.
internal struct DeliveryFailureDto: Decodable {
    let member: ParticipantDto
    let error: DeliveryErrorDto
}


/// Decodes a `failures` item, leaving it nil when malformed so one bad item does not drop the list.
internal struct LossyDeliveryFailureDto: Decodable {
    let value: DeliveryFailureDto?

    init(from decoder: Decoder) throws {
        value = try? DeliveryFailureDto(from: decoder)
    }
}


internal struct DeliveryErrorDto: Decodable {
    let code: String
    let message: String?

    private enum CodingKeys: String, CodingKey {
        case code, message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let value = try? container.decode(String.self, forKey: .code) {
            code = value
        } else {
            code = String(try container.decode(Int64.self, forKey: .code))
        }

        message = try? container.decodeIfPresent(String.self, forKey: .message)
    }
}


internal extension DeliveryFailureDto {
    func toDomain(messageId: String) -> DeliveryException {
        DeliveryException(
            messageId: messageId,
            member: member.toDomain(),
            error: error.toDomain()
        )
    }
}


internal extension DeliveryErrorDto {
    func toDomain() -> DeliveryError {
        DeliveryError(code: code, message: message)
    }
}
