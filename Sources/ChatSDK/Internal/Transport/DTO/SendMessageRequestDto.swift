//
//  SendMessageRequestDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 07.04.2026.
//

import Foundation


internal struct SendTextMessageRequestDto: Encodable {
    
    let body: String?
    let send_id: String
    let to: TargetDto
    
    init(
        target: MessageTarget,
        text: String,
        sendId: String,
    ) {
        self.body = text
        self.send_id = sendId
        self.to = TargetDto(target)
    }
}


internal struct SendLocationRequestDto: Encodable {
    
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let send_id: String
    let to: TargetDto
    
    init(
        target: MessageTarget,
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        sendId: String,
    ) {
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.send_id = sendId
        self.to = TargetDto(target)
    }
}


internal struct SendContactRequestDto: Encodable {
    
    let name: String
    let phone_number: String?
    let email: String?
    let send_id: String
    let to: TargetDto
    
    init(
        target: MessageTarget,
        name: String,
        phoneNumber: String?,
        email: String?,
        sendId: String,
    ) {
        self.name = name
        self.phone_number = phoneNumber
        self.email = email
        self.send_id = sendId
        self.to = TargetDto(target)
    }
}


internal struct SendAttachmentsRequestDto: Encodable {
    
    let body: String?
    let send_id: String
    let to: TargetDto
    
    init(
        target: MessageTarget,
        text: String,
        sendId: String,
    ) {
        self.body = text
        self.send_id = sendId
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
