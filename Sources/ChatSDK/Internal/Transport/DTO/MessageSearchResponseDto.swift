//
//  MessageSearchResponseDto.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 24.09.2026.
//

import Foundation



internal struct MessageSearchResponseDto: Decodable {

    let items: [MessageDto]?
    let olderPaging: PagingDto?
    let newerPaging: PagingDto?

    private enum CodingKeys: String, CodingKey {
        case items
        case olderPaging = "next_cursor"
        case newerPaging = "prev_cursor"
    }
}
