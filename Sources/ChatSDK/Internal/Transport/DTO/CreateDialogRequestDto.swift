//
//  CreateDialogRequestDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 23.06.2026.
//

import Foundation


internal struct CreateDialogRequestDto: Encodable {
    let direct: DirectDialogRequestDto
    
    init(contactID: ContactID) {
        direct = .init(member: ContactIdentityDto(contactID))
    }
}


internal struct CreateDialogResponseDto: Decodable {
    let thread: DialogDto
}


internal struct DirectDialogRequestDto: Encodable {
    let member: ContactIdentityDto
}
