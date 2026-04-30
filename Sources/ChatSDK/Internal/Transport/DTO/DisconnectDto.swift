//
//  DisconnectDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 08.04.2026.
//

import Foundation


struct DisconnectDto: Decodable {
    let reason: String?
    let code: Int?
}
