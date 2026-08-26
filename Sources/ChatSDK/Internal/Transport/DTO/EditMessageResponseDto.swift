//
//  EditMessageResponseDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 20.08.2026.
//

import Foundation


internal struct EditMessageResponseDto: Decodable {
    let id: String
    let editedAt: String

    private enum CodingKeys: String, CodingKey {
        case id
        case editedAt = "edited_at"
    }
}


internal extension EditMessageResponseDto {
    func toDomain() throws -> EditMessageResult {
        guard let millis = Int64(editedAt) else {
            throw ChatError.unknown(
                code: ChatError.unknownCode,
                message: "Invalid edited_at value: \(editedAt)",
                underlying: nil
            )
        }

        return EditMessageResult(
            id: id,
            editedAt: Date(timeIntervalSince1970: Double(millis) / 1000.0)
        )
    }
}
