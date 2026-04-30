//
//  ContactDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.03.2026.
//

import Foundation

internal struct ContactDto: Codable {
    let iss: String
    let name: String
    let id: String
    let source: String
    let isBot: Bool?
    
    private enum CodingKeys: String, CodingKey {
        
        case iss
        case name
        case id = "sub"
        case source = "type"
        case isBot = "is_bot"
    }
    
    init(iss: String,
         name: String,
         id: String,
         source: String,
         isBot: Bool) {
        self.iss = iss
        self.name = name
        self.id = id
        self.source = source
        self.isBot = isBot
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )
        
        iss = try container.decode(String.self, forKey: .iss)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(
            String.self,
            forKey: .name
        ) ?? "unknown"
        
        source = try container.decodeIfPresent(
            String.self,
            forKey: .source
        ) ?? iss
        
        isBot = try container.decodeIfPresent(
            Bool.self,
            forKey: .isBot
        ) ?? false
    }
}


internal extension ContactDto {
    
    func toDomain() -> Contact {
        Contact(
            id: ContactID(sub: self.id, iss: self.iss),
            name: self.name,
            source: self.source,
            isBot: self.isBot == true
        )
    }
}
