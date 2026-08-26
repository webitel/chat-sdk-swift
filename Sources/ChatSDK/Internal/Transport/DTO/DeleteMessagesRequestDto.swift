//
//  DeleteMessagesRequestDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 20.08.2026.
//

import Foundation


internal struct DeleteMessagesRequestDto: Encodable {
    let ids: [String]
}
