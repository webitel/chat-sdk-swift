//
//  ContactsResponseDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 07.04.2026.
//

import Foundation


internal struct ContactsResponseDto: Decodable {
    
    let page: Int?
    let hasNext: Bool?
    let items: [ContactDto]?
    
    private enum CodingKeys: String, CodingKey {
        
        case page
        case hasNext = "next"
        case items
    }
}
