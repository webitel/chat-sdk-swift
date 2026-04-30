//
//  DialogsResponseDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 07.04.2026.
//

import Foundation



internal struct DialogsResponseDto: Decodable {
    let page: Int?
    let hasNext: Bool?
    let items: [DialogDto]?
    
    private enum CodingKeys: String, CodingKey {
        
        case page
        case hasNext = "next"
        case items
    }
}
