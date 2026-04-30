//
//  LoginResponseDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 08.04.2026.
//

import Foundation


internal struct LoginResponseDto: Decodable {
    let token: TokenDto?
    let contact: ContactDto?
}
