//
//  LoginRequestDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 08.04.2026.
//

import Foundation


internal struct LoginRequestDto: Encodable {
    let clientId: String
    let identity: ContactIdentity
}
