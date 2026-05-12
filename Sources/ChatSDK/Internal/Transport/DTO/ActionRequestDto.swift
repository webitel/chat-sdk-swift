//
//  ActionRequestDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 11.05.2026.
//

import Foundation


internal struct ActionRequestDto: Encodable {
    let buttonCode: String
    let callbackData: String
}
