//
//  SendMessageRequestDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 07.04.2026.
//

import Foundation


internal struct SendMessageRequestDto: Encodable {
    
    let body: String?
    let send_id: String
    let to: TargetDto
    
    init(
        target: MessageTarget,
        options: MessageOptions
    ) {
        
        self.body = options.text
        self.send_id = options.sendId
        self.to = TargetDto(target)
    }
}


internal struct TargetDto: Encodable {
    
    let contact: ContactIdentityDto?
    let thread_id: String?
    
    init(_ target: MessageTarget) {
        switch target {
            case .dialog(let id):
                thread_id = id
                contact = nil
                
            case .contact(let id):
                thread_id = nil
                contact = ContactIdentityDto(id)
        }
    }
}


internal struct ContactIdentityDto: Encodable {
    let iss: String
    let sub: String
    
    init(_ id: ContactID) {
        
        iss = id.iss
        sub = id.sub
    }
}
