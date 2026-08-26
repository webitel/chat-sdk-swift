//
//  ReactionRequestDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 17.08.2026.
//

import Foundation


internal struct ReactionRequestDto: Encodable {
    let emoji: String
    let send_id: String?
}
